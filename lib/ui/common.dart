import 'package:brahma_core/brahma_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/counters.dart';

/// Opens [url] in the browser.
Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) showMessage(context, 'Nothing on this device can open $url.');
}

Future<void> copyText(BuildContext context, String text, {String what = 'Copied.'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showMessage(context, what);
}

/// Saves [bytes] where the user chooses; returns whether it was saved.
Future<bool> saveBytes(BuildContext context, String fileName, Uint8List bytes, {String mime = ''}) async {
  try {
    final where = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mime.isEmpty ? 'application/octet-stream' : mime,
      dialogTitle: 'Save $fileName',
    );
    if (where != null && context.mounted) showMessage(context, 'Saved $fileName.');
    return where != null;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}

/// Runs [task] in a dialog that says what it is doing. Returns the result,
/// or null when it failed (the error is shown).
Future<T?> runTask<T>(
  BuildContext context, {
  required String title,
  required Future<T> Function(void Function(String status) progress) task,
  String status = 'Working…',
}) async {
  final notifier = ValueNotifier(status);
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Row(
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 16),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: notifier,
                  builder: (_, s, _) => Text(s, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    final r = await task((s) => notifier.value = s);
    nav.pop();
    return r;
  } catch (e) {
    nav.pop();
    if (context.mounted) showError(context, e);
    return null;
  } finally {
    notifier.dispose();
  }
}

IconData kindIcon(String kind) => switch (kind) {
  'wifi' => Icons.wifi,
  'ethernet' => Icons.settings_ethernet,
  'mobile' => Icons.signal_cellular_alt,
  'vpn' => Icons.vpn_lock_outlined,
  _ => Icons.lan_outlined,
};

/// The colour of a kind of network in breakdowns; the same everywhere.
Color kindColor(BuildContext context, String kind) {
  final c = ChartColors.of(context).series;
  return c[(usageKinds.indexOf(kind) + c.length) % c.length];
}

/// "14:05" or "3 Oct, 14:05" for a stored UTC time.
String whenLabel(String isoUtc, String today) {
  final at = DateTime.parse(isoUtc).toLocal();
  final time = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  final day = isoDate(at);
  if (day == today) return 'Today, $time';
  if (day == addDays(today, -1)) return 'Yesterday, $time';
  return '${niceDate(day)}, $time';
}

/// Short day labels for chart axes: "Mon", "3 Oct", "Oct".
String shortDay(String day) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${int.parse(day.substring(8))} ${months[int.parse(day.substring(5, 7)) - 1]}';
}

String shortMonth(String day) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[int.parse(day.substring(5, 7)) - 1];
}
