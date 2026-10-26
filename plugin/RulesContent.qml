import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// "Allowed & blocked" page of the network panel: every saved OpenSnitch answer
// and netwatch list entry, with filters, search, and block/allow/remove.
// Changes run netwatch-rules through pkexec; data comes from the owning Panel.
Column {
  id: root

  required property var panel

  readonly property var bar: root.panel.bar
  readonly property color fg: root.panel.fg
  readonly property color dim: root.panel.dim
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property bool busy: root.panel.busyId !== ""
  readonly property var counts: root.panel.ruleCounts
  readonly property var entry: Model.classifyEntry(addField.text)
  spacing: Style.space(12)

  function focusSearch() { searchField.forceActiveFocus() }
  function focusAdd() { addField.forceActiveFocus() }

  // Position of a row in the keyboard order (rows are matched by id; the
  // repeater hands out copies).
  function rowIndex(item) {
    var rows = root.panel.ruleRows
    for (var i = 0; i < rows.length; i++) if (rows[i].id === item.id) return i
    return -1
  }

  // ---------- Header ----------
  Item {
    width: parent.width
    implicitHeight: Math.max(backButton.height, heading.implicitHeight)

    PanelActionButton {
      id: backButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      size: Style.space(28)
      iconText: Model.GLYPH_BACK
      fontSize: Style.font.body
      foreground: root.fg
      tooltipText: "Back (Esc)"
      onClicked: root.panel.closeRules()
    }

    Column {
      id: heading
      anchors.left: backButton.right
      anchors.leftMargin: Style.space(8)
      anchors.right: openButton.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      Text {
        textFormat: Text.PlainText
        text: "Allowed & blocked"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Caption {
        text: root.panel.rules.ok
          ? (root.counts.allow + " ALLOWED · " + root.counts.block + " BLOCKED")
          : "OPENSNITCH RULES AND LISTS"
      }
    }

    PanelActionButton {
      id: openButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: Style.space(28)
      iconText: Model.GLYPH_OPEN
      fontSize: Style.font.body
      foreground: root.dim
      hoverColor: root.fg
      tooltipText: "Open the OpenSnitch window"
      onClicked: {
        root.panel.startFirewallWindow()
        root.panel.close()
      }
    }
  }

  // ---------- Add ----------
  Column {
    width: parent.width
    spacing: Style.space(6)
    visible: root.panel.rules.ok

    Row {
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: addField
        width: parent.width - blockButton.width - allowButton.width - parent.spacing * 2
        placeholderText: "Block or allow a domain or IP…"
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        foreground: root.fg
        enabled: !root.busy
        onAccepted: if (root.panel.addEntry(text, "block")) text = ""
        Keys.onEscapePressed: function(event) {
          if (text !== "") { text = ""; event.accepted = true }
          else { root.panel.closeRules(); event.accepted = true }
        }
      }

      Button {
        id: blockButton
        anchors.verticalCenter: addField.verticalCenter
        text: "Block"
        foreground: root.fg
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        enabled: root.entry.ok && !root.busy
        opacity: enabled ? 1 : 0.45
        tooltipText: "Block for every app (Enter)"
        onClicked: if (root.panel.addEntry(addField.text, "block")) addField.text = ""
      }

      Button {
        id: allowButton
        anchors.verticalCenter: addField.verticalCenter
        text: "Allow"
        foreground: root.fg
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        enabled: root.entry.ok && !root.busy
        opacity: enabled ? 1 : 0.45
        tooltipText: "Allow for every app without asking"
        onClicked: if (root.panel.addEntry(addField.text, "allow")) addField.text = ""
      }
    }

    Body {
      width: parent.width
      visible: text !== ""
      text: root.entry.ok
        ? (root.entry.kind === "site" ? "Domain · exact name only (add www. separately)" : "IP address or network")
        : root.entry.error
      color: root.entry.ok ? root.dim : Color.urgent
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      elide: Text.ElideNone
    }
  }

  // Outcome of the last change (or the authentication wait).
  Rectangle {
    width: parent.width
    visible: root.panel.ruleNotice.text !== ""
    implicitHeight: noticeText.implicitHeight + Style.space(8) * 2
    radius: Style.cornerRadius
    color: Util.alpha(root.panel.ruleNotice.ok ? Color.accent : Color.urgent, 0.1)

    Body {
      id: noticeText
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      text: root.panel.ruleNotice.text
      color: root.panel.ruleNotice.ok ? root.fg : Color.urgent
      wrapMode: Text.WordWrap
      elide: Text.ElideNone
    }
  }

  // ---------- Filter + search ----------
  Item {
    width: parent.width
    visible: root.panel.rules.ok
    implicitHeight: Math.max(filterGroup.implicitHeight, searchField.implicitHeight)

    ButtonGroup {
      id: filterGroup
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      focusable: false
      spacing: Style.space(4)
      foreground: root.fg
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      options: [
        { value: "all", label: "All " + root.counts.all, tooltip: "Everything (1)" },
        { value: "allow", label: "Allowed " + root.counts.allow, tooltip: "Only allowed (2)" },
        { value: "block", label: "Blocked " + root.counts.block, tooltip: "Only blocked (3)" }
      ]
      value: root.panel.rulesFilter
      onChanged: function(value) { root.panel.rulesFilter = value }
    }

    TextField {
      id: searchField
      anchors.left: filterGroup.right
      anchors.leftMargin: Style.space(8)
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      placeholderText: "Search (/)"
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      foreground: root.fg
      text: root.panel.rulesQuery
      onTextChanged: root.panel.rulesQuery = text
      Keys.onEscapePressed: function(event) {
        if (text !== "") { text = ""; event.accepted = true }
        else { root.panel.closeRules(); event.accepted = true }
      }
    }
  }

  // ---------- States ----------
  Notice {
    width: parent.width
    visible: !root.panel.rules.ok
    text: !root.panel.rulesLoaded ? "Reading rules…"
      : !root.panel.status.helper ? "Managing rules here needs the netwatch rules manager. Run the setup script again to add it."
      : "No rules summary yet. It's written when the rules manager starts; try the setup script again if this stays."
    actionText: root.panel.rulesLoaded ? "Set up" : ""
    onActivated: root.panel.runSetup()
  }

  Notice {
    width: parent.width
    visible: root.panel.rules.ok && root.panel.ruleRows.length === 0
    text: root.panel.rules.items.length === 0
      ? "Nothing saved yet. Answers you give OpenSnitch with \"always\" appear here, along with anything you add above."
      : "Nothing matches."
    actionText: ""
  }

  // ---------- Rows ----------
  Repeater {
    model: root.panel.ruleSections

    Column {
      id: section
      required property var modelData
      width: root.width
      spacing: Style.space(2)

      PanelSectionHeader {
        text: section.modelData.title + " · " + section.modelData.items.length
        foreground: root.fg
        fontFamily: root.fontFamily
      }

      Repeater {
        model: section.modelData.items

        RuleRow {
          required property var modelData
          width: section.width
          item: modelData
          hasCursor: root.panel.ruleCursor >= 0 && root.rowIndex(modelData) === root.panel.ruleCursor
          onHoveredChanged: if (hovered) root.panel.ruleCursor = root.rowIndex(modelData)
        }
      }
    }
  }

  Body {
    width: parent.width
    visible: root.panel.rules.ok
    text: "Enter switches allow/block · x removes · answers given for a limited time are in the OpenSnitch window"
    color: root.dim
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
    elide: Text.ElideNone
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

  component Notice: Rectangle {
    id: notice
    property string text: ""
    property string actionText: ""
    signal activated()

    implicitHeight: noticeBody.implicitHeight + Style.space(10) * 2
    radius: Style.cornerRadius
    color: Util.alpha(root.fg, 0.05)

    Body {
      id: noticeBody
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

  component RuleRow: Rectangle {
    id: row
    property var item: ({})
    property bool hasCursor: false
    readonly property bool hovered: rowMouse.containsMouse || flipButton.hovering || deleteButton.hovering
    readonly property bool blocked: item.action === "block"
    readonly property bool working: root.panel.busyId === item.id

    implicitHeight: rowColumn.implicitHeight + Style.space(7) * 2
    radius: Style.cornerRadius
    color: hasCursor ? Style.hoverFillFor(root.fg, Color.accent) : "transparent"
    opacity: working ? 0.55 : (item.enabled === false ? 0.6 : 1)

    Behavior on color { ColorAnimation { duration: 80 } }

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
    }

    // What it is (app / site / address), tinted by what happens to it.
    Text {
      id: kindGlyph
      anchors.left: parent.left
      anchors.leftMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(22)
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: Model.itemGlyph(row.item)
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Column {
      id: rowColumn
      anchors.left: kindGlyph.right
      anchors.leftMargin: Style.space(10)
      anchors.right: flipButton.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      Row {
        width: parent.width
        spacing: Style.space(6)

        Text {
          id: stateText
          textFormat: Text.PlainText
          text: (row.blocked ? Model.GLYPH_BLOCK : Model.GLYPH_ALLOW) + " " + (row.blocked ? "Blocked" : "Allowed")
          color: row.blocked ? Color.urgent : Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }

        Body {
          width: parent.width - stateText.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          text: row.item.title || ""
          font.bold: true
        }
      }

      Body {
        width: parent.width
        visible: text !== ""
        text: row.working ? "Saving…" : (row.item.detail || "")
        color: root.dim
        font.pixelSize: Style.font.caption
      }
    }

    Button {
      id: flipButton
      property bool hovering: false
      anchors.right: deleteButton.left
      anchors.rightMargin: Style.space(4)
      anchors.verticalCenter: parent.verticalCenter
      text: row.blocked ? "Allow" : "Block"
      foreground: root.fg
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      enabled: !root.busy
      opacity: row.hovered || row.hasCursor ? 1 : 0.6
      tooltipText: (row.blocked ? "Allow " : "Block ") + (row.item.title || "") + " (Enter)"
      onClicked: root.panel.flipRule(row.item)
      onHovered: function(h) { hovering = h }
    }

    PanelActionButton {
      id: deleteButton
      property bool hovering: false
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      size: Style.space(24)
      iconText: Model.GLYPH_DELETE
      fontSize: Style.font.body
      foreground: root.dim
      hoverColor: Color.urgent
      opacity: root.busy ? 0.4 : (row.hovered || row.hasCursor ? 1 : 0.6)
      tooltipText: row.item.source === "rule"
        ? "Remove this answer — OpenSnitch asks again next time (x)"
        : "Remove from the list (x)"
      onClicked: if (!root.busy) root.panel.deleteRule(row.item)
      onHovered: function(h) { hovering = h }
    }
  }
}
