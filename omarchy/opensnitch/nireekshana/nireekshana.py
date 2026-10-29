"""OpenSnitch prompt plugin: says in plain words what is trying to connect.

Adds a one-line verdict under the prompt's message, and an "Explain" page
with two tabs: In plain words (what it is, what it's for, who it's talking
to, why now, what allowing or denying does) and Advanced (the details behind
it). The explanation comes from explain.py, which never uses the network.

Installed by Bahya Nireekshana's omarchy/install.sh: OpenSnitch only loads
plugins from its own package folder, so install.sh links this folder there
and a pacman hook re-links it after OpenSnitch or Python updates. It is
switched on by ~/.config/opensnitch/actions/nireekshana.json.
"""

import html
import importlib.util
import os

from PyQt5 import QtCore, QtWidgets

from opensnitch.dialogs.prompt import PromptDialog
from opensnitch.plugins import PluginBase

_spec = importlib.util.spec_from_file_location(
    "nireekshana_explain", os.path.join(os.path.dirname(os.path.realpath(__file__)), "explain.py")
)
explain = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(explain)

PAGE = "nireekshana_page"
LINK = "#nireekshana"
MAIN_PAGE = 2  # the prompt's own question page (opensnitch.dialogs.prompt._constants.PAGE_MAIN)


class _Signals(QtCore.QObject):
    done = QtCore.pyqtSignal(object, object, object)


class _Job(QtCore.QRunnable):
    """Builds the explanation off the GUI thread: pacman and systemctl can take a moment."""

    def __init__(self, parent, con, known, desktop):
        super().__init__()
        self.signals = _Signals()
        self.parent = parent
        self.con = con
        self.known = known
        self.desktop = desktop

    def run(self):
        try:
            result = explain.explain(explain.conn_from_proto(self.con), self.known, explain.System(), self.desktop)
        except Exception as e:  # never break the prompt
            print("nireekshana: could not explain the connection:", repr(e))
            result = None
        self.signals.done.emit(self.parent, self.con, result)


def _desktop_entry(parent, path):
    """The app menu's name and description, read on the GUI thread that owns OpenSnitch's parser."""
    try:
        name, _icon, description, _ = parent._apps_parser.get_info_by_path(path, "")
    except Exception:
        return {}
    # Without a .desktop file OpenSnitch falls back to the file name, which says nothing.
    if description or (name and name != os.path.basename(path)):
        return {"name": name or "", "description": description or ""}
    return {}


class Nireekshana(PluginBase):
    name = "Nireekshana"
    version = 1
    author = "Bahya Nireekshana"
    description = "Explains each connection prompt in plain words"
    TYPE = [PluginBase.TYPE_POPUPS]

    def __init__(self, config=None):
        self._config = config or {}
        self.known = None
        self.pool = QtCore.QThreadPool()
        self.pool.setMaxThreadCount(1)

    def compile(self):
        self.known = explain.load_known()

    def configure(self, parent=None):
        if type(parent) != PromptDialog or parent.findChild(QtWidgets.QWidget, PAGE) is not None:
            return
        page = QtWidgets.QWidget(objectName=PAGE)
        layout = QtWidgets.QVBoxLayout(page)
        layout.setContentsMargins(5, 3, 5, 5)
        back = QtWidgets.QPushButton("← Back to the question")
        back.setFlat(True)
        back.setSizePolicy(QtWidgets.QSizePolicy.Maximum, QtWidgets.QSizePolicy.Maximum)
        back.clicked.connect(lambda: self._back(parent))
        tabs = QtWidgets.QTabWidget(objectName="nireekshana_tabs")
        for title, name in (("In plain words", "nireekshana_plain"), ("Advanced", "nireekshana_advanced")):
            text = QtWidgets.QTextBrowser(objectName=name)
            text.setOpenLinks(False)
            tabs.addTab(text, title)
        layout.addWidget(back)
        layout.addWidget(tabs)
        parent.stackedWidget.addWidget(page)
        parent.messageLabel.linkActivated.connect(lambda link: self._open(parent, link))

    def _open(self, parent, link):
        if link != LINK:
            return
        page = parent.findChild(QtWidgets.QWidget, PAGE)
        if page is None:
            return
        # Reading takes time: stop the countdown, as clicking in the prompt does.
        stop = getattr(parent, "_stop_countdown", None)
        if stop:
            stop()
        # The prompt has a fixed size; give the explanation room while it's open.
        if getattr(parent, "_nireekshana_size", None) is None:
            parent._nireekshana_size = parent.size()
            parent.setFixedSize(max(parent.width(), 620), max(parent.height(), 600))
        parent.stackedWidget.setCurrentWidget(page)

    def _back(self, parent):
        parent.stackedWidget.setCurrentIndex(MAIN_PAGE)
        self._restore(parent)

    def _restore(self, parent):
        size = getattr(parent, "_nireekshana_size", None)
        if size is not None:
            parent._nireekshana_size = None
            parent.setFixedSize(size)

    def run(self, parent, args):
        if type(parent) != PromptDialog or self.known is None:
            return
        con = args[0]
        self._restore(parent)
        job = _Job(parent, con, self.known, _desktop_entry(parent, con.process_path))
        job.signals.done.connect(self._show)
        self.pool.start(job)

    @staticmethod
    def _timeout_note(parent):
        """What OpenSnitch saves when the countdown runs out: the default action, for the chosen duration."""
        try:
            action = ("Deny", "Allow", "Reject")[parent._cfg.getInt(parent._cfg.DEFAULT_ACTION_KEY)]
            how_long = parent.durationCombo.currentText()
        except Exception:
            return None
        return (
            f"When the countdown runs out, OpenSnitch saves “{action}” for “{how_long}”, as if you "
            "had clicked it. Opening this explanation stops the countdown, so take your time."
        )

    def _show(self, parent, con, result):
        # A newer prompt may have replaced this one while the job ran.
        if result is None or getattr(parent, "_con", None) is not con:
            return
        note = self._timeout_note(parent)
        if note:
            result["plain"].insert(len(result["plain"]) - 1, ("If you don't answer", note))
        v = result["verdict"]
        line = (
            f"<br><span style='color:{explain.COLOURS[v['level']]}'>● <b>{html.escape(v['label'])}</b></span>"
            f" · {html.escape(result['headline'])} <a href='{LINK}'>Explain…</a>"
        )
        parent.messageLabel.setText(parent.messageLabel.text() + line)
        plain = parent.findChild(QtWidgets.QTextBrowser, "nireekshana_plain")
        advanced = parent.findChild(QtWidgets.QTextBrowser, "nireekshana_advanced")
        tabs = parent.findChild(QtWidgets.QTabWidget, "nireekshana_tabs")
        if plain is not None:
            plain.setHtml(explain.plain_html(result))
        if advanced is not None:
            advanced.setHtml(explain.advanced_html(result))
        if tabs is not None:
            tabs.setCurrentIndex(0)
