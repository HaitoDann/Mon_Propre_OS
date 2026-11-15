#include "foldermodel.h"

#include <QCollator>
#include <QDir>
#include <QLocale>
#include <QStandardPaths>
#include <QStorageInfo>

#ifdef VINX_HAVE_KIO
#include <KCoreDirLister>
#include <KFileItem>
#endif

// Comparaison « naturelle » indépendante de la langue : les suites de chiffres sont
// comparées comme des nombres, le reste selon l'ordre alphabétique local sans casse.
static int naturalCompare(const QString &a, const QString &b)
{
    static const QCollator collator = [] {
        QCollator c;
        c.setCaseSensitivity(Qt::CaseInsensitive);
        return c;
    }();
    int i = 0, j = 0;
    while (i < a.size() && j < b.size()) {
        if (a[i].isDigit() && b[j].isDigit()) {
            int si = i, sj = j;
            while (si < a.size() && a[si] == QLatin1Char('0')) ++si;
            while (sj < b.size() && b[sj] == QLatin1Char('0')) ++sj;
            int ei = si, ej = sj;
            while (ei < a.size() && a[ei].isDigit()) ++ei;
            while (ej < b.size() && b[ej].isDigit()) ++ej;
            if (ei - si != ej - sj)
                return (ei - si) < (ej - sj) ? -1 : 1;
            const int c = QStringView(a).mid(si, ei - si).compare(QStringView(b).mid(sj, ej - sj));
            if (c != 0)
                return c;
            i = ei; j = ej;
            continue;
        }
        int ei = i, ej = j;
        while (ei < a.size() && !a[ei].isDigit()) ++ei;
        while (ej < b.size() && !b[ej].isDigit()) ++ej;
        const int c = collator.compare(a.mid(i, ei - i), b.mid(j, ej - j));
        if (c != 0)
            return c;
        i = ei; j = ej;
    }
    return (a.size() - i) - (b.size() - j);
}

bool folderEntryLessThan(const FolderEntry &a, const FolderEntry &b)
{
    if (a.isDir != b.isDir)
        return a.isDir;
    const int c = naturalCompare(a.name, b.name);
    return c != 0 ? c < 0 : a.name < b.name;
}

FolderModel::FolderModel(QObject *parent)
    : QAbstractListModel(parent)
{
#ifdef VINX_HAVE_KIO
    m_lister = new KCoreDirLister(this);
    m_lister->setAutoErrorHandlingEnabled(false);
    auto reload = [this] {
        static const QMimeDatabase db;
        QList<FolderEntry> list;
        const KFileItemList items = m_lister->items();
        list.reserve(items.size());
        for (const KFileItem &it : items) {
            FolderEntry e;
            e.name = it.text();
            e.url = it.url();
            e.isDir = it.isDir();
            e.hidden = it.isHidden();
            e.size = e.isDir ? 0 : qint64(it.size());
            e.modified = it.time(KFileItem::ModificationTime);
            e.mimeType = it.mimetype();
            e.iconName = it.iconName();
            list.append(e);
        }
        setEntries(list);
    };
    connect(m_lister, &KCoreDirLister::itemsAdded, this, reload);
    connect(m_lister, &KCoreDirLister::itemsDeleted, this, reload);
    connect(m_lister, &KCoreDirLister::refreshItems, this, reload);
    connect(m_lister, &KCoreDirLister::clear, this, [this] { setEntries({}); });
    connect(m_lister, &KCoreDirLister::started, this, [this] { setLoading(true); });
    connect(m_lister, &KCoreDirLister::completed, this, [this, reload] { reload(); setLoading(false); });
    connect(m_lister, &KCoreDirLister::canceled, this, [this] { setLoading(false); });
    connect(m_lister, &KCoreDirLister::jobError, this, [this](KIO::Job *job) { setError(job->errorString()); setLoading(false); });
#else
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { listLocal(); });
#endif
}

FolderModel::~FolderModel() = default;

int FolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_visible.size());
}

QVariant FolderModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_visible.size())
        return {};
    const FolderEntry &e = m_visible.at(index.row());
    switch (role) {
    case NameRole: return e.name;
    case UrlRole: return e.url;
    case PathRole: return e.url.isLocalFile() ? e.url.toLocalFile() : e.url.toDisplayString();
    case IsDirRole: return e.isDir;
    case SizeRole: return e.size;
    case SizeTextRole: return e.isDir ? QString() : formatSize(e.size);
    case ModifiedRole: return e.modified;
    case MimeTypeRole: return e.mimeType;
    case IconNameRole: return e.iconName;
    case IsImageRole: return e.url.isLocalFile() && e.mimeType.startsWith(QLatin1String("image/")) && e.size < 40 * 1024 * 1024;
    }
    return {};
}

QHash<int, QByteArray> FolderModel::roleNames() const
{
    return {{NameRole, "name"}, {UrlRole, "url"}, {PathRole, "path"}, {IsDirRole, "isDir"}, {SizeRole, "size"},
            {SizeTextRole, "sizeText"}, {ModifiedRole, "modified"}, {MimeTypeRole, "mimeType"},
            {IconNameRole, "iconName"}, {IsImageRole, "isImage"}};
}

void FolderModel::setUrl(const QUrl &url)
{
    const QUrl u = url.adjusted(QUrl::StripTrailingSlash | QUrl::NormalizePathSegments);
    const QUrl clean = u.path().isEmpty() && u.scheme() == QLatin1String("file") ? QUrl::fromLocalFile(QStringLiteral("/")) : u;
    if (clean == m_url)
        return;
    m_url = clean;
    Q_EMIT urlChanged();
    refresh();
}

void FolderModel::setShowHidden(bool v)
{
    if (v == m_showHidden)
        return;
    m_showHidden = v;
    Q_EMIT showHiddenChanged();
    applyFilter();
}

void FolderModel::setFilter(const QString &f)
{
    if (f == m_filter)
        return;
    m_filter = f;
    Q_EMIT filterChanged();
    applyFilter();
}

void FolderModel::refresh()
{
    setError({});
    if (!m_url.isValid())
        return;
#ifdef VINX_HAVE_KIO
    m_lister->openUrl(m_url);
#else
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());
    if (m_url.isLocalFile())
        m_watcher.addPath(m_url.toLocalFile());
    listLocal();
#endif
}

void FolderModel::listLocal()
{
    if (!m_url.isLocalFile()) {
        setEntries({});
        setError(tr("Cet emplacement nécessite les bibliothèques KDE (KIO)."));
        return;
    }
    QDir dir(m_url.toLocalFile());
    if (!dir.exists() || !dir.isReadable()) {
        setEntries({});
        setError(tr("Impossible d'ouvrir ce dossier."));
        return;
    }
    QList<FolderEntry> list;
    const QFileInfoList infos = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
    list.reserve(infos.size());
    for (const QFileInfo &fi : infos)
        list.append(FolderEntry::fromFileInfo(fi));
    setEntries(list);
}

void FolderModel::setEntries(QList<FolderEntry> entries)
{
    std::sort(entries.begin(), entries.end(), folderEntryLessThan);
    m_all = entries;
    applyFilter();
}

void FolderModel::applyFilter()
{
    QList<FolderEntry> visible;
    for (const FolderEntry &e : std::as_const(m_all)) {
        if (e.hidden && !m_showHidden)
            continue;
        if (!m_filter.isEmpty() && !e.name.contains(m_filter, Qt::CaseInsensitive))
            continue;
        visible.append(e);
    }
    const int before = count();
    beginResetModel();
    m_visible = visible;
    endResetModel();
    if (before != count())
        Q_EMIT countChanged();
}

void FolderModel::setLoading(bool v)
{
    if (v != m_loading) {
        m_loading = v;
        Q_EMIT loadingChanged();
    }
}

void FolderModel::setError(const QString &e)
{
    if (e != m_error) {
        m_error = e;
        Q_EMIT errorChanged();
    }
}

QString FolderModel::title() const
{
    if (m_url.scheme() == QLatin1String("trash"))
        return tr("Corbeille");
    if (m_url.scheme() == QLatin1String("remote"))
        return tr("Réseau");
    if (m_url.isLocalFile()) {
        const QString p = m_url.toLocalFile();
        if (p == QDir::homePath())
            return tr("Dossier personnel");
        if (p == QStringLiteral("/"))
            return tr("Système de fichiers");
    }
    const QString name = m_url.fileName();
    return name.isEmpty() ? m_url.toDisplayString() : name;
}

bool FolderModel::canGoUp() const
{
    return parentUrl() != m_url;
}

QUrl FolderModel::parentUrl() const
{
    const QUrl up = m_url.adjusted(QUrl::RemoveFilename | QUrl::StripTrailingSlash);
    if (up.path().isEmpty())
        return m_url.path() == QLatin1String("/") || m_url.path().isEmpty() ? m_url : up.resolved(QUrl(QStringLiteral("/")));
    return up;
}

QVariantMap FolderModel::get(int row) const
{
    QVariantMap m;
    if (row < 0 || row >= m_visible.size())
        return m;
    const QModelIndex i = index(row);
    const auto roles = roleNames();
    for (auto it = roles.cbegin(); it != roles.cend(); ++it)
        m.insert(QString::fromLatin1(it.value()), data(i, it.key()));
    return m;
}

int FolderModel::indexOfName(const QString &name) const
{
    for (int i = 0; i < m_visible.size(); ++i)
        if (m_visible.at(i).name == name)
            return i;
    return -1;
}

QVariantList FolderModel::breadcrumb() const
{
    QVariantList out;
    if (m_url.isLocalFile()) {
        const QString home = QDir::homePath();
        QString p = m_url.toLocalFile();
        QString root = QStringLiteral("/");
        QString rootName = tr("Système");
        if (p == home || p.startsWith(home + QLatin1Char('/'))) {
            root = home;
            rootName = tr("Dossier personnel");
        }
        out.append(QVariantMap{{QStringLiteral("name"), rootName}, {QStringLiteral("url"), QUrl::fromLocalFile(root)}});
        const QString rest = p.mid(root.size());
        QString acc = root;
        for (const QString &part : rest.split(QLatin1Char('/'), Qt::SkipEmptyParts)) {
            acc = acc.endsWith(QLatin1Char('/')) ? acc + part : acc + QLatin1Char('/') + part;
            out.append(QVariantMap{{QStringLiteral("name"), part}, {QStringLiteral("url"), QUrl::fromLocalFile(acc)}});
        }
        return out;
    }
    out.append(QVariantMap{{QStringLiteral("name"), title()}, {QStringLiteral("url"), m_url}});
    return out;
}

QVariantList FolderModel::places()
{
    QVariantList out;
    auto add = [&out](const QString &name, const QUrl &url, const QString &icon, const QString &section) {
        out.append(QVariantMap{{QStringLiteral("name"), name}, {QStringLiteral("url"), url},
                               {QStringLiteral("icon"), icon}, {QStringLiteral("section"), section}});
    };
    auto std = [&](QStandardPaths::StandardLocation loc, const QString &name, const QString &icon) {
        const QString p = QStandardPaths::writableLocation(loc);
        if (!p.isEmpty() && QDir(p).exists() && p != QDir::homePath())
            add(name, QUrl::fromLocalFile(p), icon, tr("Emplacements"));
    };
    add(tr("Dossier personnel"), QUrl::fromLocalFile(QDir::homePath()), QStringLiteral("home"), tr("Emplacements"));
    std(QStandardPaths::DesktopLocation, tr("Bureau"), QStringLiteral("grid"));
    std(QStandardPaths::DocumentsLocation, tr("Documents"), QStringLiteral("doc"));
    std(QStandardPaths::DownloadLocation, tr("Téléchargements"), QStringLiteral("download"));
    std(QStandardPaths::PicturesLocation, tr("Images"), QStringLiteral("image"));
    std(QStandardPaths::MusicLocation, tr("Musique"), QStringLiteral("music"));
    std(QStandardPaths::MoviesLocation, tr("Vidéos"), QStringLiteral("video"));
    if (kioAvailable()) {
        add(tr("Corbeille"), QUrl(QStringLiteral("trash:/")), QStringLiteral("trash"), tr("Emplacements"));
        add(tr("Réseau"), QUrl(QStringLiteral("remote:/")), QStringLiteral("globe"), tr("Appareils"));
    }
    // Disques et clés USB montés.
    const auto volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo &v : volumes) {
        const QString root = v.rootPath();
        if (!v.isValid() || !v.isReady())
            continue;
        if (!(root.startsWith(QLatin1String("/media/")) || root.startsWith(QLatin1String("/run/media/"))))
            continue;
        const QString name = v.displayName().isEmpty() || v.displayName() == root ? QDir(root).dirName() : v.displayName();
        add(name, QUrl::fromLocalFile(root), QStringLiteral("drive"), tr("Appareils"));
    }
    add(tr("Système de fichiers"), QUrl::fromLocalFile(QStringLiteral("/")), QStringLiteral("drive"), tr("Appareils"));
    return out;
}

QUrl FolderModel::urlFromText(const QString &text)
{
    QString t = text.trimmed();
    if (t.startsWith(QLatin1Char('~')))
        t = QDir::homePath() + t.mid(1);
    if (t.startsWith(QLatin1Char('/')))
        return QUrl::fromLocalFile(QDir::cleanPath(t));
    const QUrl u(t);
    return u.scheme().isEmpty() ? QUrl::fromLocalFile(QDir::home().absoluteFilePath(t)) : u;
}

QString FolderModel::formatSize(qint64 bytes)
{
    // Unités françaises : octets, Ko, Mo, Go, To (base 1024, comme la plupart des systèmes).
    static const char *units[] = {"Ko", "Mo", "Go", "To"};
    if (bytes < 1024)
        return tr("%n octet(s)", "", int(bytes));
    double v = double(bytes);
    int u = -1;
    while (v >= 1024 && u < 3) { v /= 1024; ++u; }
    return QLocale().toString(v, 'f', v < 10 ? 1 : 0) + QLatin1Char(' ') + QLatin1String(units[u]);
}

bool FolderModel::kioAvailable()
{
#ifdef VINX_HAVE_KIO
    return true;
#else
    return false;
#endif
}
