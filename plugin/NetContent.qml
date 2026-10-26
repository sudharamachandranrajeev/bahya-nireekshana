import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Body of the network panel: live speed, usage history and the apps &
// firewall section. All data comes from the owning Panel.
Column {
  id: root

  // The network Panel that owns the data.
  required property var panel

  readonly property var bar: root.panel.bar
  readonly property color fg: root.panel.fg
  readonly property color dim: root.panel.dim
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property color uploadTint: Qt.tint(Color.accent, Util.alpha(root.fg, 0.35))
  readonly property var bucket: root.panel.periodBuckets[root.panel.currentIndex] || null
  spacing: Style.space(14)

  // ---------- Hero ----------
  PanelHero {
    foreground: root.fg
    fontFamily: root.fontFamily
    title: "Network"
    meta: {
      var iface = root.panel.primaryInterface
      var parts = [iface ? Model.interfaceLabel(iface.kind) : "Offline"]
      if (root.panel.vnstatState === "ok" && root.panel.todayBucket)
        parts.push(Model.formatBytes(root.panel.todayBucket.rx + root.panel.todayBucket.tx) + " today")
      else if (iface)
        parts.push("connected")
      return parts.join(" · ")
    }
    detail: root.panel.primaryInterface ? root.panel.primaryInterface.name : ""
    iconComponent: Text {
      textFormat: Text.PlainText
      text: root.panel.primaryInterface ? Model.interfaceGlyph(root.panel.primaryInterface.kind) : Model.GLYPH_NETWORK
      color: root.panel.showActive ? Color.accent : root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.display

      Behavior on color { ColorAnimation { duration: 260 } }
    }
  }

  // ---------- Live speed ----------
  Row {
    width: parent.width
    spacing: Style.space(8)

    ThroughputCard {
      width: (parent.width - parent.spacing) / 2
      title: "DOWNLOAD"
      glyph: Model.GLYPH_DOWN
      rate: root.panel.rate.rx
      samples: root.panel.rxHistory
      tint: Color.accent
    }

    ThroughputCard {
      width: (parent.width - parent.spacing) / 2
      title: "UPLOAD"
      glyph: Model.GLYPH_UP
      rate: root.panel.rate.tx
      samples: root.panel.txHistory
      tint: root.uploadTint
    }
  }

  PanelSeparator { foreground: root.fg }

  // ---------- Usage history ----------
  Column {
    width: parent.width
    spacing: Style.space(10)

    Item {
      width: parent.width
      implicitHeight: Math.max(usageHeader.implicitHeight, periodPicker.implicitHeight)

      PanelSectionHeader {
        id: usageHeader
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "USAGE"
        foreground: root.fg
        fontFamily: root.fontFamily
      }

      ButtonGroup {
        id: periodPicker
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.panel.vnstatState === "ok"
        focusable: false
        spacing: Style.space(4)
        foreground: root.fg
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        options: [
          { value: "day", label: "Day", tooltip: "Last 14 days (d)" },
          { value: "week", label: "Week", tooltip: "Last 8 weeks (w)" },
          { value: "month", label: "Month", tooltip: "Last 12 months (m)" }
        ]
        value: root.panel.granularity
        onChanged: function(value) { root.panel.setGranularity(value) }
      }
    }

    Notice {
      width: parent.width
      visible: root.panel.vnstatState !== "ok"
      text: root.panel.vnstatState === "missing"
        ? "Daily, weekly and monthly history needs vnstat."
        : root.panel.vnstatState === "loading" ? "Reading history…"
        : "Collecting — vnstat saves its first numbers within 5 minutes."
      actionText: root.panel.vnstatState === "missing" ? "Set up" : ""
      onActivated: root.panel.runSetup()
    }

    // Selected period: total, split and comparison.
    Item {
      width: parent.width
      visible: root.panel.vnstatState === "ok" && root.bucket !== null
      implicitHeight: summaryLeft.implicitHeight

      Column {
        id: summaryLeft
        anchors.left: parent.left
        anchors.right: summaryRight.left
        anchors.rightMargin: Style.space(8)
        spacing: Style.space(2)

        Caption {
          text: root.bucket ? Model.bucketTitle(root.bucket, root.panel.granularity, new Date()).toUpperCase() : ""
        }

        Text {
          textFormat: Text.PlainText
          text: root.bucket ? Model.formatBytes(root.bucket.rx + root.bucket.tx) : ""
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Body {
          width: parent.width
          text: Model.changeText(root.panel.periodBuckets, root.panel.currentIndex, root.panel.granularity,
            root.panel.history, root.panel.counted, new Date())
          color: root.dim
          font.pixelSize: Style.font.caption
          visible: text !== ""
        }
      }

      Column {
        id: summaryRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Body {
          anchors.right: parent.right
          text: Model.GLYPH_DOWN + " " + (root.bucket ? Model.formatBytes(root.bucket.rx) : "") + " down"
          color: Color.accent
        }

        Body {
          anchors.right: parent.right
          text: Model.GLYPH_UP + " " + (root.bucket ? Model.formatBytes(root.bucket.tx) : "") + " up"
          color: root.uploadTint
        }
      }
    }

    HistoryBars {
      width: parent.width
      height: Style.space(78)
      visible: root.panel.vnstatState === "ok"
    }

    // Per-interface breakdown of the selected period.
    Column {
      width: parent.width
      spacing: Style.space(2)
      visible: root.panel.vnstatState === "ok" && root.bucket !== null && root.bucket.interfaces.length > 0

      Repeater {
        model: root.bucket ? root.bucket.interfaces : []

        InterfaceRow {
          required property var modelData
          width: parent.width
          entry: modelData
        }
      }
    }
  }

  PanelSeparator { foreground: root.fg }

  // ---------- Apps & firewall ----------
  Column {
    width: parent.width
    spacing: Style.space(4)

    PanelSectionHeader {
      text: "APPS & FIREWALL"
      foreground: root.fg
      fontFamily: root.fontFamily
    }

    FirewallRow { width: parent.width }

    Repeater {
      model: root.panel.actions

      ActionRow {
        required property var modelData
        required property int index
        width: parent.width
        action: modelData
        hasCursor: root.panel.cursorIndex === index
        onHoveredChanged: if (hovered) root.panel.cursorIndex = index
      }
    }
  }

  // ---------- Components ----------

  component Caption: Text {
    textFormat: Text.PlainText
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 1.1
  }

  component Body: Text {
    textFormat: Text.PlainText
    color: root.fg
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }

  component ThroughputCard: Rectangle {
    id: card
    property string title: ""
    property string glyph: ""
    property real rate: 0
    property var samples: []
    property color tint: Color.accent

    implicitHeight: cardColumn.implicitHeight + Style.space(10) * 2
    radius: Style.cornerRadius
    color: Util.alpha(root.fg, 0.05)

    Column {
      id: cardColumn
      anchors.fill: parent
      anchors.margins: Style.space(10)
      spacing: Style.space(6)

      Item {
        width: parent.width
        implicitHeight: Math.max(cardTitle.implicitHeight, cardRate.implicitHeight)

        Caption {
          id: cardTitle
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: card.glyph + " " + card.title
          color: card.rate > 1000 ? card.tint : root.dim
        }

        Text {
          id: cardRate
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: Model.formatRate(card.rate)
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }
      }

      Sparkline {
        width: parent.width
        height: Style.space(30)
        samples: card.samples
        capacity: root.panel.historyLength
        color: card.tint
        minimumScale: 100 * 1000
      }
    }
  }

  component Notice: Rectangle {
    id: notice
    property string text: ""
    property string actionText: ""
    signal activated()

    implicitHeight: noticeText.implicitHeight + Style.space(10) * 2
    radius: Style.cornerRadius
    color: Util.alpha(root.fg, 0.05)

    Body {
      id: noticeText
      anchors.left: parent.left
      anchors.leftMargin: Style.space(10)
      anchors.right: noticeButton.visible ? noticeButton.left : parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      text: notice.text
      color: root.dim
      wrapMode: Text.WordWrap
      elide: Text.ElideNone
    }

    Button {
      id: noticeButton
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      visible: notice.actionText !== ""
      text: notice.actionText
      foreground: root.fg
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: notice.activated()
    }
  }

  // Stacked download/upload bars for the visible periods. Hover or click a bar
  // (or press h / l) to show that period above.
  component HistoryBars: Item {
    id: chart
    readonly property var buckets: root.panel.periodBuckets
    readonly property real peak: Math.max(1, Model.maxTotal(buckets))
    readonly property real labelHeight: Style.font.caption + Style.space(4)
    readonly property real slot: width / Math.max(1, buckets.length)

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      y: chart.height - chart.labelHeight
      height: 1
      color: Util.alpha(root.fg, 0.12)
    }

    Repeater {
      model: chart.buckets

      Item {
        id: column
        required property var modelData
        required property int index
        readonly property bool selected: index === root.panel.currentIndex
        readonly property real plot: chart.height - chart.labelHeight - Style.space(2)
        readonly property real total: modelData.rx + modelData.tx
        readonly property real barHeight: total > 0 ? Math.max(2, plot * total / chart.peak) : 0

        x: index * chart.slot
        width: chart.slot
        height: chart.height

        // Download at the bottom, upload stacked on top.
        Rectangle {
          id: rxBar
          anchors.horizontalCenter: parent.horizontalCenter
          y: column.plot - height
          width: Math.max(3, chart.slot * 0.56)
          height: column.total > 0 ? column.barHeight * column.modelData.rx / column.total : 0
          radius: Math.min(2, width / 2)
          color: Color.accent
          opacity: column.selected ? 1 : 0.42
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: rxBar.top
          width: rxBar.width
          height: column.barHeight - rxBar.height
          radius: rxBar.radius
          color: root.uploadTint
          opacity: column.selected ? 1 : 0.42
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          textFormat: Text.PlainText
          text: Model.bucketLabel(column.modelData, root.panel.granularity)
          color: column.selected ? root.fg : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: column.selected
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.panel.selectedIndex = column.index === chart.buckets.length - 1 ? -1 : column.index
          onClicked: root.panel.selectedIndex = column.index === chart.buckets.length - 1 ? -1 : column.index
        }
      }
    }
  }

  component InterfaceRow: Item {
    id: ifaceRow
    property var entry: ({})
    readonly property var info: {
      var list = root.panel.interfaces
      for (var i = 0; i < list.length; i++) if (list[i].name === entry.name) return list[i]
      return { kind: Model.interfaceKind(entry.name, false, false) }
    }

    implicitHeight: Style.space(24)

    Text {
      id: ifaceGlyph
      anchors.left: parent.left
      anchors.leftMargin: Style.space(4)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(20)
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: Model.interfaceGlyph(ifaceRow.info.kind)
      color: ifaceRow.entry.counted ? root.fg : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Body {
      anchors.left: ifaceGlyph.right
      anchors.leftMargin: Style.space(8)
      anchors.right: ifaceTotals.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      text: ifaceRow.entry.name + "  " + Model.interfaceLabel(ifaceRow.info.kind)
        + (ifaceRow.entry.counted ? "" : " · not in total")
      color: ifaceRow.entry.counted ? root.fg : root.dim
    }

    Body {
      id: ifaceTotals
      anchors.right: parent.right
      anchors.rightMargin: Style.space(4)
      anchors.verticalCenter: parent.verticalCenter
      text: Model.GLYPH_DOWN + " " + Model.formatBytes(ifaceRow.entry.rx) + "   " + Model.GLYPH_UP + " " + Model.formatBytes(ifaceRow.entry.tx)
      color: root.dim
    }
  }

  component FirewallRow: Rectangle {
    id: fwRow
    readonly property var fw: root.panel.firewall
    readonly property color tint: fw.level === "ok" ? Color.accent
      : fw.level === "missing" ? root.dim : Color.urgent
    readonly property string buttonText: fw.level === "paused" ? "Start"
      : (fw.level === "missing" || fw.level === "off") ? "Set up" : ""

    implicitHeight: fwColumn.implicitHeight + Style.space(10) * 2
    radius: Style.cornerRadius
    color: Util.alpha(fwRow.tint, 0.08)

    Text {
      id: fwGlyph
      anchors.left: parent.left
      anchors.leftMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(26)
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: fwRow.fw.glyph
      color: fwRow.tint
      font.family: root.fontFamily
      font.pixelSize: Style.font.display
    }

    Column {
      id: fwColumn
      anchors.left: fwGlyph.right
      anchors.leftMargin: Style.space(12)
      anchors.right: fwButton.visible ? fwButton.left : parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)

      Body {
        width: parent.width
        text: fwRow.fw.title
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Body {
        width: parent.width
        text: fwRow.fw.detail
        color: root.dim
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
      }
    }

    Button {
      id: fwButton
      anchors.right: parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      visible: fwRow.buttonText !== ""
      text: fwRow.buttonText
      foreground: root.fg
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: {
        if (fwRow.fw.level === "paused") root.panel.startFirewallWindow()
        else root.panel.runSetup()
      }
    }
  }

  component ActionRow: Rectangle {
    id: actionRow
    property var action: ({})
    property bool hasCursor: false
    readonly property bool hovered: actionMouse.containsMouse

    implicitHeight: actionColumn.implicitHeight + Style.space(7) * 2
    radius: Style.cornerRadius
    color: hasCursor && action.enabled ? Style.hoverFillFor(root.fg, Color.accent) : "transparent"
    opacity: action.enabled ? 1 : 0.55

    Behavior on color { ColorAnimation { duration: 80 } }

    MouseArea {
      id: actionMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: actionRow.action.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: root.panel.runAction(actionRow.action)
    }

    Text {
      id: actionGlyph
      anchors.left: parent.left
      anchors.leftMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(26)
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: actionRow.action.glyph || ""
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      id: actionChevron
      anchors.right: parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      visible: actionRow.action.chevron === true && actionRow.action.enabled
      textFormat: Text.PlainText
      text: Model.GLYPH_CHEVRON
      color: actionRow.hasCursor ? root.fg : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Column {
      id: actionColumn
      anchors.left: actionGlyph.right
      anchors.leftMargin: Style.space(12)
      anchors.right: actionChevron.visible ? actionChevron.left : parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      Body {
        width: parent.width
        text: actionRow.action.title || ""
      }

      Body {
        width: parent.width
        text: actionRow.action.detail || ""
        color: root.dim
        font.pixelSize: Style.font.caption
      }
    }
  }
}
