#include "terminalwindow.h"

#include <qtermwidget.h>

#include <QAction>
#include <QApplication>
#include <QClipboard>
#include <QDesktopServices>
#include <QDir>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QInputDialog>
#include <QMimeData>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemModel>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QKeySequence>
#include <QLabel>
#include <QMenu>
#include <QProcess>
#include <QProcessEnvironment>
#include <QSplitter>
#include <QStackedWidget>
#include <QStandardPaths>
#include <QTabBar>
#include <QToolButton>
#include <QTreeView>
#include <QUrl>
#include <QVBoxLayout>

namespace {
// Le terminal est toujours sombre (choix de l'utilisateur) ; seul l'accent suit les préférences.
constexpr bool kDark = true;

QString tok(const char *const pair[2]) { return QString::fromLatin1(pair[kDark ? 0 : 1]).left(7); }

QString schemesDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/vinx-terminal/colorschemes");
}

void writeSchemes()
{
    QDir().mkpath(schemesDir());
    QFile f(schemesDir() + QLatin1Char('/') + termtheme::schemeName(kDark) + QStringLiteral(".colorscheme"));
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(termtheme::colorScheme(kDark).toUtf8());
}

QFont terminalFont()
{
    QFont font(QStringLiteral("IBM Plex Mono"));
    font.setStyleHint(QFont::Monospace);
    font.setFixedPitch(true);
    font.setPointSizeF(11.5);
    return font;
}

// « ~/Documents » pour l'affichage.
QString shortPath(const QString &path)
{
    const QString home = QDir::homePath();
    return path == home ? QStringLiteral("~") : path.startsWith(home + QLatin1Char('/')) ? QLatin1Char('~') + path.mid(home.size()) : path;
}

QString shellQuote(const QString &s)
{
    return QLatin1Char('\'') + QString(s).replace(QLatin1Char('\''), QStringLiteral("'\\''")) + QLatin1Char('\'');
}
} // namespace

TerminalWindow::TerminalWindow(const QString &workingDirectory, QWidget *parent)
    : QWidget(parent)
{
    writeSchemes();
    QTermWidget::addCustomColorSchemeDir(schemesDir());
    m_iniPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/vinx/shell.ini");

    auto *root = new QVBoxLayout(this);
    root->setContentsMargins(0, 0, 0, 0);
    root->setSpacing(0);

    // Barre : bouton « Dossiers », onglets, nouvel onglet.
    auto *bar = new QWidget(this);
    bar->setObjectName(QStringLiteral("bar"));
    auto *barLayout = new QHBoxLayout(bar);
    barLayout->setContentsMargins(8, 6, 8, 6);
    barLayout->setSpacing(6);
    m_treeButton = new QToolButton(bar);
    m_treeButton->setObjectName(QStringLiteral("treeButton"));
    m_treeButton->setText(tr("Dossiers"));
    m_treeButton->setCheckable(true);
    m_treeButton->setChecked(true);
    m_treeButton->setToolTip(tr("Afficher ou masquer l'arborescence (Ctrl+Maj+B)"));
    m_tabBar = new QTabBar(bar);
    m_tabBar->setDocumentMode(true);
    m_tabBar->setTabsClosable(true);
    m_tabBar->setMovable(true);
    m_tabBar->setExpanding(false);
    m_tabBar->setElideMode(Qt::ElideMiddle);
    m_tabBar->setDrawBase(false);
    auto *add = new QToolButton(bar);
    add->setObjectName(QStringLiteral("addButton"));
    add->setText(QStringLiteral("+"));
    add->setToolTip(tr("Nouvel onglet (Ctrl+Maj+T)"));
    barLayout->addWidget(m_treeButton);
    barLayout->addWidget(m_tabBar, 1);
    barLayout->addWidget(add);
    root->addWidget(bar);

    // Arborescence à gauche, terminaux à droite.
    m_split = new QSplitter(Qt::Horizontal, this);
    m_split->setHandleWidth(1);
    m_split->setChildrenCollapsible(false);
    m_treePanel = buildTree();
    m_stack = new QStackedWidget(m_split);
    m_stack->setContentsMargins(12, 10, 4, 4);   // marge autour du texte (même fond que le terminal)
    m_split->addWidget(m_treePanel);
    m_split->addWidget(m_stack);
    m_split->setStretchFactor(1, 1);
    m_split->setSizes({250, 650});
    root->addWidget(m_split, 1);

    m_status = new QLabel(this);
    m_status->setObjectName(QStringLiteral("status"));
    root->addWidget(m_status);

    connect(add, &QToolButton::clicked, this, [this] { newTab(); });
    connect(m_treeButton, &QToolButton::toggled, this, &TerminalWindow::setTreeVisible);
    connect(m_tabBar, &QTabBar::tabCloseRequested, this, &TerminalWindow::closeTab);
    connect(m_tabBar, &QTabBar::tabMoved, this, [this](int from, int to) {
        QWidget *w = m_stack->widget(from);
        m_stack->removeWidget(w);
        m_stack->insertWidget(to, w);
    });
    connect(m_tabBar, &QTabBar::currentChanged, this, [this](int i) {
        if (i >= 0 && i < m_stack->count()) {
            m_stack->setCurrentIndex(i);
            if (auto *t = qobject_cast<QTermWidget *>(m_stack->widget(i)))
                markActivity(t, false);
        }
        updateTitle();
        followDirectory();
        if (current()) current()->setFocus();
    });

    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+T")), [this] { newTab(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+W")), [this] { closeTab(m_tabBar->currentIndex()); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+C")), [this] { if (current()) current()->copyClipboard(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+V")), [this] { if (current()) current()->pasteClipboard(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+F")), [this] { if (current()) current()->toggleShowSearchBar(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+Shift+B")), [this] { m_treeButton->toggle(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+PgDown")), [this] { m_tabBar->setCurrentIndex((m_tabBar->currentIndex() + 1) % m_tabBar->count()); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+PgUp")), [this] { m_tabBar->setCurrentIndex((m_tabBar->currentIndex() + m_tabBar->count() - 1) % m_tabBar->count()); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl++")), [this] { if (current()) current()->zoomIn(); });
    addShortcut(QKeySequence(QStringLiteral("Ctrl+-")), [this] { if (current()) current()->zoomOut(); });

    // L'arborescence suit les « cd » tapés dans le terminal (dossier courant du shell).
    m_follow.setInterval(700);
    connect(&m_follow, &QTimer::timeout, this, &TerminalWindow::followDirectory);
    m_follow.start();

    // Les préférences VinX changent (accent) : le terminal suit sans redémarrer.
    if (QFile::exists(m_iniPath))
        m_watcher.addPath(m_iniPath);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
        if (!m_watcher.files().contains(m_iniPath) && QFile::exists(m_iniPath))
            m_watcher.addPath(m_iniPath);
        applyAppearance();
    });

    resize(1040, 620);
    applyAppearance();
    newTab(workingDirectory);
}

QWidget *TerminalWindow::buildTree()
{
    auto *panel = new QWidget(this);
    panel->setObjectName(QStringLiteral("treePanel"));
    auto *layout = new QVBoxLayout(panel);
    layout->setContentsMargins(0, 8, 0, 0);
    layout->setSpacing(2);

    auto *head = new QHBoxLayout;
    head->setContentsMargins(12, 0, 6, 0);
    auto *title = new QLabel(tr("DOSSIER COURANT"), panel);
    title->setObjectName(QStringLiteral("treeTitle"));
    auto *up = new QToolButton(panel);
    up->setObjectName(QStringLiteral("upButton"));
    up->setText(QStringLiteral("↑"));
    up->setToolTip(tr("Dossier parent (cd ..)"));
    head->addWidget(title, 1);
    head->addWidget(up);
    layout->addLayout(head);

    m_crumb = new QLabel(panel);
    m_crumb->setObjectName(QStringLiteral("crumb"));
    m_crumb->setContentsMargins(12, 0, 12, 4);
    layout->addWidget(m_crumb);

    m_model = new QFileSystemModel(panel);
    // Dossiers et fichiers, fichiers cachés compris (choix de l'utilisateur).
    m_model->setFilter(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
    m_model->setReadOnly(true);
    m_tree = new QTreeView(panel);
    m_tree->setModel(m_model);
    m_tree->setHeaderHidden(true);
    for (int c = 1; c < m_model->columnCount(); ++c)
        m_tree->hideColumn(c);
    m_tree->setSortingEnabled(true);
    m_tree->sortByColumn(0, Qt::AscendingOrder);
    m_tree->setAnimated(true);
    m_tree->setIndentation(14);
    m_tree->setUniformRowHeights(true);
    m_tree->setExpandsOnDoubleClick(false);
    m_tree->setFrameShape(QFrame::NoFrame);
    m_tree->setContextMenuPolicy(Qt::CustomContextMenu);
    // Glisser-déposer : on fait glisser un fichier vers Fichiers ou le bureau pour le récupérer,
    // on dépose des fichiers sur l'arborescence pour les copier dans le dossier (ou le sous-dossier visé).
    m_tree->setDragEnabled(true);
    m_tree->setDragDropMode(QAbstractItemView::DragOnly);
    m_tree->setDefaultDropAction(Qt::CopyAction);
    m_tree->viewport()->setAcceptDrops(true);
    m_tree->viewport()->installEventFilter(this);
    m_tree->setToolTip(tr("Double-clic : se placer dans le dossier, ou ouvrir le fichier. Glissez des fichiers ici pour les copier."));
    layout->addWidget(m_tree, 1);

    connect(up, &QToolButton::clicked, this, [this] {
        QDir d(m_dir);
        if (d.cdUp()) changeDirectory(d.absolutePath());
    });
    connect(m_tree, &QTreeView::doubleClicked, this, [this](const QModelIndex &index) {
        const QString path = m_model->filePath(index);
        if (m_model->isDir(index))
            changeDirectory(path);
        else
            QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    });
    connect(m_tree, &QWidget::customContextMenuRequested, this, &TerminalWindow::showTreeMenu);
    return panel;
}

void TerminalWindow::setTreeVisible(bool visible)
{
    m_treePanel->setVisible(visible);
    if (current()) current()->setFocus();
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
    return qobject_cast<QTermWidget *>(m_stack->currentWidget());
}

QTermWidget *TerminalWindow::newTab(const QString &workingDirectory)
{
    QString dir = workingDirectory;
    if (dir.isEmpty() && current())
        dir = current()->workingDirectory();
    if (dir.isEmpty() || !QDir(dir).exists())
        dir = QDir::homePath();

    auto *term = new QTermWidget(0, m_stack);
    term->setWorkingDirectory(dir);
    auto env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("TERM"), QStringLiteral("xterm-256color"));
    env.insert(QStringLiteral("COLORTERM"), QStringLiteral("truecolor"));
    term->setEnvironment(env.toStringList());
    term->setTerminalFont(terminalFont());
    term->setColorScheme(termtheme::schemeName(kDark));
    term->setScrollBarPosition(QTermWidget::ScrollBarRight);
    term->setHistorySize(10000);
    term->setBlinkingCursor(true);
    term->setTerminalSizeHint(false);
    term->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(term, &QWidget::customContextMenuRequested, this, [this, term](const QPoint &pos) { showContextMenu(term, pos); });
    connect(term, &QTermWidget::titleChanged, this, [this, term] {
        const int i = m_stack->indexOf(term);
        if (i >= 0 && !term->title().isEmpty()) m_tabBar->setTabText(i, term->title());
        updateTitle();
    });
    connect(term, &QTermWidget::finished, this, [this, term] { closeTab(m_stack->indexOf(term)); });
    // Onglet en arrière-plan : un point signale une nouvelle sortie (fin de compilation, de copie…).
    term->setMonitorActivity(true);
    connect(term, &QTermWidget::activity, this, [this, term] { if (term != current()) markActivity(term, true); });
    connect(term, &QTermWidget::urlActivated, this, [](const QUrl &url, bool) { QDesktopServices::openUrl(url); });

    const int i = m_stack->addWidget(term);
    m_tabBar->insertTab(i, QFileInfo(dir).fileName().isEmpty() ? QStringLiteral("/") : QFileInfo(dir).fileName());
    m_tabBar->setCurrentIndex(i);
    m_stack->setCurrentIndex(i);
    term->startShellProgram();
    term->setFocus();
    setTreeRoot(dir);
    return term;
}

void TerminalWindow::closeTab(int index)
{
    if (index < 0 || index >= m_stack->count())
        return;
    QWidget *w = m_stack->widget(index);
    m_stack->removeWidget(w);
    m_tabBar->removeTab(index);
    w->deleteLater();
    if (m_stack->count() == 0) {
        close();
        return;
    }
    m_stack->setCurrentIndex(m_tabBar->currentIndex());
    updateTitle();
}

void TerminalWindow::updateTitle()
{
    const QString t = current() ? current()->title() : QString();
    setWindowTitle((t.isEmpty() ? shortPath(m_dir) : t) + QStringLiteral(" — ") + tr("Terminal"));
}

void TerminalWindow::followDirectory()
{
    if (!current())
        return;
    const QString dir = current()->workingDirectory();
    if (!dir.isEmpty() && dir != m_dir && QDir(dir).exists())
        setTreeRoot(dir);
}

void TerminalWindow::setTreeRoot(const QString &dir)
{
    m_dir = dir;
    m_tree->setRootIndex(m_model->setRootPath(dir));
    m_crumb->setText(shortPath(dir));
    m_crumb->setToolTip(dir);
    m_status->setText(tr("Dossier : %1    ·    Double-clic : entrer dans un dossier ou ouvrir un fichier").arg(shortPath(dir)));
    const int i = m_tabBar->currentIndex();
    if (i >= 0 && (!current() || current()->title().isEmpty()))
        m_tabBar->setTabText(i, QFileInfo(dir).fileName().isEmpty() ? QStringLiteral("/") : QFileInfo(dir).fileName());
    updateTitle();
}

// Double-clic sur un dossier : « cd » écrit et exécuté dans le terminal courant.
void TerminalWindow::changeDirectory(const QString &dir)
{
    if (!current())
        return;
    current()->sendText(QStringLiteral("cd ") + shellQuote(dir) + QLatin1Char('\n'));
    setTreeRoot(dir);
    current()->setFocus();
}

void TerminalWindow::showTreeMenu(const QPoint &pos)
{
    const QModelIndex index = m_tree->indexAt(pos);
    const QString path = index.isValid() ? m_model->filePath(index) : m_dir;
    const bool isDir = !index.isValid() || m_model->isDir(index);
    QMenu menu(this);
    if (isDir) {
        menu.addAction(tr("Se placer dans ce dossier"), this, [this, path] { changeDirectory(path); });
        menu.addAction(tr("Ouvrir dans un nouvel onglet"), this, [this, path] { newTab(path); });
        menu.addAction(tr("Nouveau dossier…"), this, [this, path] {
            bool ok = false;
            const QString name = QInputDialog::getText(this, tr("Nouveau dossier"), tr("Nom du dossier :"), QLineEdit::Normal, QString(), &ok).trimmed();
            if (ok && !name.isEmpty() && !name.contains(QLatin1Char('/')))
                QDir(path).mkdir(name);
        });
        menu.addAction(tr("Ouvrir dans Fichiers"), this, [path] {
            if (!QProcess::startDetached(QStringLiteral("vinx-files"), {path}))
                QDesktopServices::openUrl(QUrl::fromLocalFile(path));
        });
    } else {
        menu.addAction(tr("Ouvrir"), this, [path] { QDesktopServices::openUrl(QUrl::fromLocalFile(path)); });
    }
    menu.addSeparator();
    menu.addAction(tr("Écrire le chemin dans le terminal"), this, [this, path] {
        if (current()) { current()->sendText(shellQuote(path) + QLatin1Char(' ')); current()->setFocus(); }
    });
    menu.addAction(tr("Copier le chemin"), this, [path] { QApplication::clipboard()->setText(path); });
    menu.exec(m_tree->viewport()->mapToGlobal(pos));
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
    item(tr("Afficher les dossiers"), "Ctrl+Shift+B", [this] { m_treeButton->toggle(); });
    item(tr("Nouvel onglet"), "Ctrl+Shift+T", [this] { newTab(); });
    item(tr("Fermer l'onglet"), "Ctrl+Shift+W", [this, term] { closeTab(m_stack->indexOf(term)); });
    menu.exec(term->mapToGlobal(pos));
}

void TerminalWindow::applyAppearance()
{
    m_appearance = termtheme::readAppearance(m_iniPath);
    const QString bg = tok(vinx::tokens::surfaceWindow), bar = tok(vinx::tokens::surfaceGlassStrong),
                  side = tok(vinx::tokens::surfaceSunken), text = tok(vinx::tokens::text),
                  text2 = tok(vinx::tokens::textSecondary), text3 = tok(vinx::tokens::textTertiary),
                  line = QStringLiteral("#2C302E"), accent = m_appearance.accent, ink = m_appearance.accentInk;
    setStyleSheet(QStringLiteral(
        "TerminalWindow, QStackedWidget { background: %1; }"
        "#bar { background: %2; border-bottom: 1px solid %7; }"
        "QTabBar { background: transparent; font-family: 'IBM Plex Sans'; font-size: 12px; }"
        "QTabBar::tab { background: transparent; color: %5; padding: 6px 12px; margin: 0 2px; border-radius: 7px; min-width: 70px; max-width: 220px; }"
        "QTabBar::tab:selected { background: %1; color: %4; border-bottom: 2px solid %8; }"
        "QTabBar::tab:hover:!selected { color: %4; background: %3; }"
        "QToolButton { color: %5; background: transparent; border: 0; border-radius: 7px; padding: 4px 10px;"
        " font-family: 'IBM Plex Sans'; font-size: 12px; }"
        "QToolButton:hover { background: %1; color: %4; }"
        "#treeButton:checked { background: %1; color: %4; }"
        "#addButton { font-size: 16px; padding: 0 10px; }"
        "#treePanel { background: %3; border-right: 1px solid %7; }"
        "#treeTitle { color: %6; font-family: 'IBM Plex Sans'; font-size: 11px; font-weight: 600; letter-spacing: 1px; }"
        "#crumb { color: %6; font-family: 'IBM Plex Mono'; font-size: 11px; }"
        "QTreeView { background: %3; color: %4; border: 0; font-family: 'IBM Plex Sans'; font-size: 13px; outline: 0; }"
        "QTreeView::item { padding: 3px 2px; border-radius: 5px; }"
        "QTreeView::item:hover { background: %1; }"
        "QTreeView::item:selected { background: %8; color: %9; }"
        "QSplitter::handle { background: %7; }"
        "#status { background: %2; color: %6; border-top: 1px solid %7; padding: 4px 12px;"
        " font-family: 'IBM Plex Sans'; font-size: 11px; }"
        "QScrollBar:vertical { background: transparent; width: 10px; margin: 2px; }"
        "QScrollBar::handle:vertical { background: %7; border-radius: 4px; min-height: 30px; }"
        "QScrollBar::add-line, QScrollBar::sub-line { height: 0; }"
        "QMenu { background: %2; color: %4; border: 1px solid %7; padding: 4px; font-family: 'IBM Plex Sans'; }"
        "QMenu::item { padding: 6px 24px 6px 12px; border-radius: 6px; }"
        "QMenu::item:selected { background: %8; color: %9; }"
        "QMenu::separator { height: 1px; background: %7; margin: 4px 8px; }")
        .arg(bg, bar, side, text, text2, text3, line, accent, ink));
}

void TerminalWindow::markActivity(QTermWidget *term, bool active)
{
    const int i = m_stack->indexOf(term);
    if (i < 0)
        return;
    QString text = m_tabBar->tabText(i);
    const QString dot = QStringLiteral("● ");
    if (text.startsWith(dot))
        text = text.mid(dot.size());
    m_tabBar->setTabText(i, active ? dot + text : text);
}

bool TerminalWindow::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_tree->viewport()) {
        if (event->type() == QEvent::DragEnter || event->type() == QEvent::DragMove) {
            auto *e = static_cast<QDropEvent *>(event);
            if (e->mimeData()->hasUrls() && e->source() != m_tree) {
                e->setDropAction(Qt::CopyAction);
                e->accept();
                return true;
            }
        } else if (event->type() == QEvent::Drop) {
            auto *e = static_cast<QDropEvent *>(event);
            if (e->mimeData()->hasUrls() && e->source() != m_tree) {
                // Cible : le dossier survolé, sinon le dossier courant.
                const QModelIndex index = m_tree->indexAt(e->position().toPoint());
                const QString dir = index.isValid() && m_model->isDir(index) ? m_model->filePath(index) : m_dir;
                copyInto(e->mimeData()->urls(), dir);
                e->setDropAction(Qt::CopyAction);
                e->accept();
                return true;
            }
        }
    }
    return QWidget::eventFilter(watched, event);
}

// Copie (récursive, sans jamais écraser un fichier existant) des fichiers déposés.
void TerminalWindow::copyInto(const QList<QUrl> &urls, const QString &dir)
{
    QStringList args{QStringLiteral("-r"), QStringLiteral("-n"), QStringLiteral("--")};
    for (const QUrl &u : urls)
        if (u.isLocalFile())
            args << u.toLocalFile();
    if (args.size() == 3)
        return;
    args << dir;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, p, &QObject::deleteLater);
    connect(p, &QProcess::finished, this, [this, dir](int code) {
        m_status->setText(code == 0 ? tr("Copié dans %1.").arg(shortPath(dir)) : tr("La copie dans %1 a échoué.").arg(shortPath(dir)));
    });
    m_status->setText(tr("Copie en cours…"));
    p->start(QStringLiteral("cp"), args);
}
