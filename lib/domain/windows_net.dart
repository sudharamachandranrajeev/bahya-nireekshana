/// Windows' IP Helper API through dart:ffi: interface counters
/// (GetIfTable2) and the sockets each process holds (GetExtendedTcpTable /
/// GetExtendedUdpTable). Only called on Windows; test/windows_net_test.dart
/// runs it on a real Windows runner in CI.
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'connections.dart';
import 'counters.dart';

final _iphlpapi = DynamicLibrary.open('iphlpapi.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _getIfTable2 = _iphlpapi
    .lookupFunction<Uint32 Function(Pointer<Pointer<Uint8>>), int Function(Pointer<Pointer<Uint8>>)>(
      'GetIfTable2',
    );
final _freeMibTable = _iphlpapi.lookupFunction<Void Function(Pointer<Uint8>), void Function(Pointer<Uint8>)>(
  'FreeMibTable',
);
typedef _TableNative = Uint32 Function(Pointer<Uint8>, Pointer<Uint32>, Int32, Uint32, Int32, Uint32);
typedef _TableDart = int Function(Pointer<Uint8>, Pointer<Uint32>, int, int, int, int);
final _getExtendedTcpTable = _iphlpapi.lookupFunction<_TableNative, _TableDart>('GetExtendedTcpTable');
final _getExtendedUdpTable = _iphlpapi.lookupFunction<_TableNative, _TableDart>('GetExtendedUdpTable');
final _getTickCount64 = _kernel32.lookupFunction<Uint64 Function(), int Function()>('GetTickCount64');
final _openProcess = _kernel32
    .lookupFunction<IntPtr Function(Uint32, Int32, Uint32), int Function(int, int, int)>('OpenProcess');
final _closeHandle = _kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
final _queryImageName = _kernel32
    .lookupFunction<
      Int32 Function(IntPtr, Uint32, Pointer<Utf16>, Pointer<Uint32>),
      int Function(int, int, Pointer<Utf16>, Pointer<Uint32>)
    >('QueryFullProcessImageNameW');

// MIB_IF_ROW2 (netioapi.h), 1352 bytes: the offsets of the fields read here.
const _rowSize = 1352;
const _alias = 28; // WCHAR[257]
const _description = 542; // WCHAR[257]
const _type = 1128; // IFTYPE
const _flags = 1152; // InterfaceAndOperStatusFlags: bit 0 hardware, bit 1 filter
const _operStatus = 1156; // 1 = up
const _inOctets = 1208;
const _outOctets = 1280;

/// IFTYPE values (ipifcons.h) and the usage kind each counts as.
String windowsKind(int type) => switch (type) {
  71 => 'wifi', // IF_TYPE_IEEE80211
  6 => 'ethernet', // IF_TYPE_ETHERNET_CSMACD
  243 || 244 => 'mobile', // IF_TYPE_WWANPP, IF_TYPE_WWANPP2
  24 => 'loopback', // IF_TYPE_SOFTWARE_LOOPBACK
  131 || 23 => 'vpn', // IF_TYPE_TUNNEL, IF_TYPE_PPP
  _ => 'other',
};

/// The hardware interfaces (not the filter drivers Windows stacks on each,
/// which repeat the same counts).
List<Iface> windowsInterfaces() {
  final table = calloc<Pointer<Uint8>>();
  try {
    if (_getIfTable2(table) != 0) return const [];
    final base = table.value;
    try {
      final count = base.cast<Uint32>().value;
      // The rows start after NumEntries, aligned to 8.
      final rows = (base + 8).asTypedList(count * _rowSize);
      final data = ByteData.sublistView(rows);
      final out = <Iface>[];
      for (var i = 0; i < count; i++) {
        final o = i * _rowSize;
        final flags = data.getUint8(o + _flags);
        final hardware = flags & 1 != 0, filter = flags & 2 != 0;
        final kind = windowsKind(data.getUint32(o + _type, Endian.little));
        if (!hardware || filter || kind == 'loopback') continue;
        out.add(
          Iface(
            name: _wide(rows, o + _alias),
            label: _wide(rows, o + _description),
            kind: kind,
            rx: data.getUint64(o + _inOctets, Endian.little),
            tx: data.getUint64(o + _outOctets, Endian.little),
            up: data.getUint32(o + _operStatus, Endian.little) == 1,
          ),
        );
      }
      return out;
    } finally {
      _freeMibTable(base);
    }
  } finally {
    calloc.free(table);
  }
}

/// The boot, as the minute Windows started (counters restart with it).
String windowsBootId() {
  final booted = DateTime.now().subtract(Duration(milliseconds: _getTickCount64()));
  return '${booted.millisecondsSinceEpoch ~/ 60000}';
}

/// A NUL-terminated UTF-16 string inside [bytes] at [offset], at most 257
/// characters.
String _wide(Uint8List bytes, int offset) {
  final units = <int>[];
  for (var i = 0; i < 257; i++) {
    final u = bytes[offset + i * 2] | (bytes[offset + i * 2 + 1] << 8);
    if (u == 0) break;
    units.add(u);
  }
  return String.fromCharCodes(units);
}

const _afInet = 2, _afInet6 = 23;
const _tcpOwnerPidAll = 5, _udpOwnerPid = 1;
const _insufficientBuffer = 122;

const _tcpStates = {
  1: 'closed',
  2: 'listen',
  3: 'syn-sent',
  4: 'syn-received',
  5: 'established',
  6: 'fin-wait',
  7: 'fin-wait',
  8: 'close-wait',
  9: 'closing',
  10: 'last-ack',
  11: 'time-wait',
  12: 'closed',
};

/// Every TCP and UDP socket, with the process that owns it.
List<Connection> windowsConnections() {
  final names = <int, String>{};
  String path(int pid) => names[pid] ??= _imagePath(pid);
  final out = <Connection>[];
  for (final (af, tcp) in [(_afInet, true), (_afInet6, true), (_afInet, false), (_afInet6, false)]) {
    final bytes = _table(af, tcp);
    if (bytes == null) continue;
    final data = ByteData.sublistView(bytes);
    final count = data.getUint32(0, Endian.little);
    final v6 = af == _afInet6;
    // Row sizes: MIB_TCPROW_OWNER_PID 24, MIB_TCP6ROW_OWNER_PID 56,
    // MIB_UDPROW_OWNER_PID 12, MIB_UDP6ROW_OWNER_PID 28; rows start at 4.
    final size = tcp ? (v6 ? 56 : 24) : (v6 ? 28 : 12);
    for (var i = 0; i < count; i++) {
      final o = 4 + i * size;
      if (o + size > bytes.length) break;
      int u32(int at) => data.getUint32(o + at, Endian.little);
      int port(int at) => ((bytes[o + at] << 8) | bytes[o + at + 1]);
      final Connection c;
      if (tcp && !v6) {
        c = Connection(
          protocol: 'tcp',
          local: _v4(bytes, o + 4),
          localPort: port(8),
          remote: _v4(bytes, o + 12),
          remotePort: port(16),
          state: _tcpStates[u32(0)] ?? 'unknown',
          pid: u32(20),
        );
      } else if (tcp) {
        c = Connection(
          protocol: 'tcp6',
          local: _v6(bytes, o),
          localPort: port(20),
          remote: _v6(bytes, o + 24),
          remotePort: port(44),
          state: _tcpStates[u32(48)] ?? 'unknown',
          pid: u32(52),
        );
      } else if (!v6) {
        c = Connection(protocol: 'udp', local: _v4(bytes, o), localPort: port(4), pid: u32(8));
      } else {
        c = Connection(protocol: 'udp6', local: _v6(bytes, o), localPort: port(20), pid: u32(24));
      }
      out.add(c.withProcess(path(c.pid)));
    }
  }
  return out;
}

Uint8List? _table(int af, bool tcp) {
  final size = calloc<Uint32>();
  try {
    final call = tcp ? _getExtendedTcpTable : _getExtendedUdpTable;
    final kind = tcp ? _tcpOwnerPidAll : _udpOwnerPid;
    // The table can grow between asking its size and reading it.
    for (var attempt = 0; attempt < 3; attempt++) {
      final buffer = calloc<Uint8>(size.value == 0 ? 1 : size.value);
      try {
        final r = call(buffer, size, 0, af, kind, 0);
        if (r == 0) return Uint8List.fromList(buffer.asTypedList(size.value));
        if (r != _insufficientBuffer) return null;
      } finally {
        calloc.free(buffer);
      }
    }
    return null;
  } finally {
    calloc.free(size);
  }
}

String _v4(Uint8List b, int o) => '${b[o]}.${b[o + 1]}.${b[o + 2]}.${b[o + 3]}';

String _v6(Uint8List b, int o) =>
    [for (var i = 0; i < 16; i += 2) ((b[o + i] << 8) | b[o + i + 1]).toRadixString(16)]
        .join(':')
        .replaceFirst(RegExp(r'(^|:)0(:0)+(:|$)'), '::');

/// The program file of [pid], or '' when Windows does not say (system
/// processes, or another user's).
String _imagePath(int pid) {
  if (pid == 0) return '';
  if (pid == 4) return 'System';
  const queryLimitedInformation = 0x1000;
  final handle = _openProcess(queryLimitedInformation, 0, pid);
  if (handle == 0) return '';
  final buffer = calloc<Uint16>(1024).cast<Utf16>();
  final length = calloc<Uint32>()..value = 1024;
  try {
    return _queryImageName(handle, 0, buffer, length) != 0 ? buffer.toDartString(length: length.value) : '';
  } finally {
    calloc.free(buffer);
    calloc.free(length);
    _closeHandle(handle);
  }
}
