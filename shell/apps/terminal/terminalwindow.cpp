#include "terminalwindow.h"

#include <qtermwidget.h>

#include <QAction>
#include <QKeySequence>
#include <functional>
#include <QApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFontDatabase>
#include <QMenu>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QTabBar>
#include <QToolButton>
#include <QVBoxLayout>

// Schémas de couleurs écrits dans ~/.local/share/vinx-terminal/colorschemes (lus par QTermWidget).
static QString schemesDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/vinx-terminal/colorschemes");
}

static void writeSchemes()
{
    QDir().mkpath(schemesDir());
    for (bool dark : {false, true}) {
        QFile f(schemesDir() + QLatin1Char('/') + termtheme::schemeName(dark) + QStringLiteral(".colorscheme"));
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
            f.write(termtheme::colorScheme(dark).toUtf8());
    }
}

static QFont terminalFont()
{
    QFont font(QStringLiteral("IBM Plex Mono"));
    font.setStyleHint(QFont::Monospace);
    font.setFixedPitch(true);
    font.setPointSize(11);
    return font;
}

TerminalWindow::TerminalWindow(const QString &workingDirectory, QWidget *parent)
    : QWidget(parent)
{
    writeSchemes();
    QTermWidget::addCustomColorSchemeDir(schemesDir());
    m_iniPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/vinx/shell.ini");

    auto *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);
    m_tabs = new QTabWidget(this);
    m_tabs->setDocumentMode(true);
    m_tabs->setTabsClosable(true);
    m_tabs->setMovable(true);
    m_tabs->tabBar()->setExpanding(false);
    m_tabs->tabBar()->setElideMode(Qt::ElideMiddle);
    layout->addWidget(m_tabs);

    m_add = new QToolButton(m_tabs);
    m_add->setText(QStringLiteral("+"));
    m_add->setToolTip(tr("Nouvel onglet (Ctrl+Maj+T)"));
    m_add->setAutoRaise(true);
    m_tabs->setCornerWidget(m_add, Qt::TopRightCorner);
    connect(m_add, &QToolButton::clicked, this, [this] { newTab(); });
    connect(m_tabs, &QTabWidget::tabCloseRequested, this, &TerminalWindow::closeTab);
    connect(m_tabs, &QTabWidget::currentChanged, this, [this] {
        updateTitle();
        if (current()) current()->setFocus();
    });

    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+T")), [this] { newTab(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+W")), [this] { closeTab(m_tabs->currentIndex()); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+C")), [this] { if (current()) current()->copyClipboard(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+V")), [this] { if (current()) current()->pasteClipboard(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+F")), [this] { if (current()) current()->toggleShowSearchBar(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+PgDown")), [this] { m_tabs->setCurrentIndex((m_tabs->currentIndex() + 1) % m_tabs->count()); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+PgUp")), [this] { m_tabs->setCurrentIndex((m_tabs->currentIndex() + m_tabs->count() - 1) % m_tabs->count()); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl++")), [this] { if (current()) current()->zoomIn(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+-")), [this] { if (current()) current()->zoomOut(); });

    // Les préférences VinX changent (thème, accent) : le terminal suit sans redémarrer.
    if (QFile::exists(m_iniPath))
        m_watcher.addPath(m_iniPath);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
        if (!m_watcher.files().contains(m_iniPath) && QFile::exists(m_iniPath))
            m_watcher.addPath(m_iniPath);   // fichier remplacé par une écriture atomique
        applyAppearance();
    });

    resize(860, 540);
    newTab(workingDirectory);
    applyAppearance();
}

void TerminalWindow::addShortcut(const QKeySequence &keys, const std::function<void()> &action)
{
    auto *a = new QAction(this);
    a->setShortcut(keys);
    a->setShortcutContext(Qt::WindowShortcut);
    connect(a, &QAction::triggered, this, action);
    addAction(a);
}

QTermWidget *TerminalWindow::current() const
{
    return qobject_cast<QTermWidget *>(m_tabs->currentWidget());
}

QTermWidget *TerminalWindow::newTab(const QString &workingDirectory)
{
    auto *term = new QTermWidget(0, m_tabs);
    QString dir = workingDirectory;
    if (dir.isEmpty() && current())
        dir = current()->workingDirectory();
    term->setWorkingDirectory(dir.isEmpty() ? QDir::homePath() : dir);
    auto env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("TERM"), QStringLiteral("xterm-256color"));
    env.insert(QStringLiteral("COLORTERM"), QStringLiteral("truecolor"));
    term->setEnvironment(env.toStringList());
    term->setTerminalFont(terminalFont());
    term->setColorScheme(termtheme::schemeName(m_appearance.dark));
    term->setScrollBarPosition(QTermWidget::ScrollBarRight);
    term->setHistorySize(10000);
    term->setBlinkingCursor(true);
    term->setTerminalSizeHint(false);
    term->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(term, &QWidget::customContextMenuRequested, this, [this, term](const QPoint &pos) { showContextMenu(term, pos); });
    connect(term, &QTermWidget::titleChanged, this, [this, term] {
        const int i = m_tabs->indexOf(term);
        if (i >= 0) m_tabs->setTabText(i, term->title());
        updateTitle();
    });
    connect(term, &QTermWidget::finished, this, [this, term] { closeTab(m_tabs->indexOf(term)); });
    connect(term, &QTermWidget::urlActivated, this, [](const QUrl &url, bool) { QDesktopServices::openUrl(url); });

    const int i = m_tabs->addTab(term, tr("Terminal"));
    m_tabs->setCurrentIndex(i);
    term->startShellProgram();
    term->setFocus();
    return term;
}

void TerminalWindow::closeTab(int index)
{
    if (index < 0)
        return;
    QWidget *w = m_tabs->widget(index);
    m_tabs->removeTab(index);
    w->deleteLater();
    if (m_tabs->count() == 0) {
        close();
        return;
    }
    updateTitle();
}

void TerminalWindow::updateTitle()
{
    const QString t = current() ? current()->title() : QString();
    setWindowTitle(t.isEmpty() ? tr("Terminal") : t + QStringLiteral(" — ") + tr("Terminal"));
}

void TerminalWindow::showContextMenu(QTermWidget *term, const QPoint &pos)
{
    QMenu menu(this);
    // Entrée de menu avec raccourci affiché (forme explicite, indépendante des surcharges de Qt).
    auto item = [&menu](const QString &text, const char *keys, auto &&slot) {
        QAction *a = menu.addAction(text);
        a->setShortcut(QKeySequence(QString::fromLatin1(keys)));
        QObject::connect(a, &QAction::triggered, slot);
    };
    const auto links = term->filterActions(pos);   // « Ouvrir le lien », « Copier l'adresse »…
    for (QAction *a : links)
        menu.addAction(a);
    if (!links.isEmpty())
        menu.addSeparator();
    item(tr("Copier"), "Ctrl+Shift+C", [term] { term->copyClipboard(); });
    item(tr("Coller"), "Ctrl+Shift+V", [term] { term->pasteClipboard(); });
    item(tr("Rechercher…"), "Ctrl+Shift+F", [term] { term->toggleShowSearchBar(); });
    menu.addSeparator();
    item(tr("Agrandir le texte"), "Ctrl++", [term] { term->zoomIn(); });
    item(tr("Réduire le texte"), "Ctrl+-", [term] { term->zoomOut(); });
    menu.addSeparator();
    item(tr("Nouvel onglet"), "Ctrl+Shift+T", [this] { newTab(); });
    item(tr("Fermer l'onglet"), "Ctrl+Shift+W", [this, term] { closeTab(m_tabs->indexOf(term)); });
    menu.exec(term->mapToGlobal(pos));
}

void TerminalWindow::applyAppearance()
{
    m_appearance = termtheme::readAppearance(m_iniPath);
    const bool d = m_appearance.dark;
    for (int i = 0; i < m_tabs->count(); ++i)
        if (auto *t = qobject_cast<QTermWidget *>(m_tabs->widget(i)))
            t->setColorScheme(termtheme::schemeName(d));
    const auto tok = [d](const char *const pair[2]) { return QString::fromLatin1(pair[d ? 0 : 1]).left(7); };
    const QString bar = tok(vinx::tokens::surfaceSunken), text = tok(vinx::tokens::text),
                  text2 = tok(vinx::tokens::textSecondary), win = tok(vinx::tokens::surfaceWindow);
    // Onglets VinX : onglet actif souligné à la couleur d'accent.
    setStyleSheet(QStringLiteral(
        "QTabWidget::pane { border: 0; }"
        "QTabBar { background: %1; }"
        "QTabBar::tab { background: transparent; color: %3; padding: 6px 14px; border: 0; margin: 4px 2px; border-radius: 7px;"
        " font-family: 'IBM Plex Sans'; font-size: 12px; min-width: 80px; max-width: 240px; }"
        "QTabBar::tab:selected { background: %4; color: %2; border-bottom: 2px solid %5; }"
        "QTabBar::tab:hover:!selected { color: %2; }"
        "QToolButton { color: %2; background: transparent; border: 0; padding: 2px 10px; font-size: 16px; }"
        "QToolButton:hover { background: %4; border-radius: 7px; }"
        "QMenu { background: %4; color: %2; border: 1px solid %1; padding: 4px; font-family: 'IBM Plex Sans'; }"
        "QMenu::item { padding: 6px 24px 6px 12px; border-radius: 6px; }"
        "QMenu::item:selected { background: %5; color: %6; }")
        .arg(bar, text, text2, win, m_appearance.accent, m_appearance.accentInk));
}
