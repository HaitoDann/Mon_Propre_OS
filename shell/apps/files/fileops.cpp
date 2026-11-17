#include "fileops.h"
#include "folderentry.h"

#include <QClipboard>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QMimeData>
#include <QProcess>
#include <QTimer>

#ifdef VINX_HAVE_KIO
#include <KIO/CopyJob>
#include <KIO/Job>
#include <KIO/DeleteJob>
#include <KIO/RestoreJob>
#include <KIO/EmptyTrashJob>
#include <KIO/JobUiDelegateFactory>
#include <KIO/MkdirJob>
#include <KIO/OpenUrlJob>
#endif

namespace {
const QString kCutMime = QStringLiteral("application/x-kde-cutselection");

#ifndef VINX_HAVE_KIO
// Copie récursive locale ; le nom de destination est rendu unique en cas de conflit.
bool copyRecursive(const QString &src, const QString &destDir, QString *error, bool replace = false)
{
    const QFileInfo fi(src);
    const QDir dest(destDir);
    if (replace && dest.exists(fi.fileName()) && QFileInfo(dest.filePath(fi.fileName())).absoluteFilePath() != fi.absoluteFilePath()) {
        const QFileInfo old(dest.filePath(fi.fileName()));
        if (!(old.isDir() && !old.isSymLink() ? QDir(old.absoluteFilePath()).removeRecursively() : QFile::remove(old.absoluteFilePath()))) {
            *error = QObject::tr("Impossible de remplacer « %1 ».").arg(fi.fileName());
            return false;
        }
    }
    const QString name = uniqueName(fi.fileName(), [&dest](const QString &n) { return dest.exists(n); });
    const QString target = dest.filePath(name);
    if (fi.isDir() && !fi.isSymLink()) {
        if (QDir(destDir + QLatin1Char('/')).absolutePath().startsWith(fi.absoluteFilePath() + QLatin1Char('/'))
            || QDir(destDir).absolutePath() == fi.absoluteFilePath()) {
            *error = QObject::tr("Impossible de copier un dossier dans lui-même.");
            return false;
        }
        if (!dest.mkdir(name)) {
            *error = QObject::tr("Impossible de créer « %1 ».").arg(name);
            return false;
        }
        const QFileInfoList children = QDir(src).entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
        for (const QFileInfo &c : children)
            if (!copyRecursive(c.absoluteFilePath(), target, error, false))
                return false;
        return true;
    }
    if (!QFile::copy(src, target)) {
        *error = QObject::tr("Impossible de copier « %1 ».").arg(fi.fileName());
        return false;
    }
    return true;
}
#endif
}

QStringList FileOps::conflicts(const QList<QUrl> &urls, const QUrl &destDir) const
{
    QStringList out;
    if (!destDir.isLocalFile())
        return out;
    const QDir dest(destDir.toLocalFile());
    for (const QUrl &u : urls) {
        if (!u.isLocalFile())
            continue;
        const QFileInfo fi(u.toLocalFile());
        if (fi.absolutePath() == dest.absolutePath())
            continue;   // même dossier : copie = doublon « (2) », déplacement = rien
        if (dest.exists(fi.fileName()))
            out.append(fi.fileName());
    }
    return out;
}

static QList<QUrl> withoutConflicts(const QList<QUrl> &urls, const QStringList &names)
{
    QList<QUrl> out;
    for (const QUrl &u : urls)
        if (!names.contains(u.fileName()))
            out.append(u);
    return out;
}

FileOps::FileOps(QObject *parent)
    : QObject(parent)
{
    if (auto *cb = QGuiApplication::clipboard())
        connect(cb, &QClipboard::dataChanged, this, &FileOps::clipboardChanged);
}

bool FileOps::validName(const QString &name)
{
    const QString n = name.trimmed();
    return !n.isEmpty() && n != QLatin1String(".") && n != QLatin1String("..") && !n.contains(QLatin1Char('/'));
}

void FileOps::begin(const QString &task)
{
    ++m_jobs;
    m_task = task;
    m_progress = -1;
    Q_EMIT busyChanged();
    Q_EMIT progressChanged();
}

void FileOps::finish(bool ok, const QString &error)
{
    m_jobs = qMax(0, m_jobs - 1);
    if (m_jobs == 0) {
        m_task.clear();
        m_progress = -1;
    }
    Q_EMIT busyChanged();
    Q_EMIT progressChanged();
    if (!ok && !error.isEmpty())
        Q_EMIT failed(error);
    Q_EMIT done();
}

#ifdef VINX_HAVE_KIO
static void track(FileOps *self, KJob *job, std::function<void(bool, const QString &)> finish, std::function<void(int)> progress)
{
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoWarningHandlingEnabled, nullptr));
    QObject::connect(job, &KJob::percentChanged, self, [progress](KJob *, unsigned long p) { progress(int(p)); });
    QObject::connect(job, &KJob::result, self, [finish](KJob *j) {
        // Annulation par l'utilisateur (dialogue de conflit) : pas un échec à signaler.
        const bool ok = j->error() == 0;
        finish(ok, ok || j->error() == KIO::ERR_USER_CANCELED ? QString() : j->errorString());
    });
    job->start();
}
#endif

void FileOps::copy(const QList<QUrl> &input, const QUrl &destDir, int conflict)
{
    const QList<QUrl> urls = conflict == Skip ? withoutConflicts(input, conflicts(input, destDir)) : input;
    if (urls.isEmpty())
        return;
    begin(tr("Copie de %n élément(s)", "", int(urls.size())));
#ifdef VINX_HAVE_KIO
    auto *job = KIO::copy(urls, destDir, conflict == Replace ? KIO::Overwrite : KIO::DefaultFlags);
    job->setAutoRename(conflict == KeepBoth);
    track(this, job, [this](bool ok, const QString &e) { finish(ok, e); },
          [this](int p) { m_progress = p; Q_EMIT progressChanged(); });
#else
    QTimer::singleShot(0, this, [this, urls, destDir, conflict] {
        QString error;
        bool ok = true;
        for (const QUrl &u : urls)
            if (!(ok = copyRecursive(u.toLocalFile(), destDir.toLocalFile(), &error, conflict == Replace)))
                break;
        finish(ok, error);
    });
#endif
}

void FileOps::move(const QList<QUrl> &input, const QUrl &destDir, int conflict)
{
    const QList<QUrl> urls = conflict == Skip ? withoutConflicts(input, conflicts(input, destDir)) : input;
    if (urls.isEmpty())
        return;
    begin(tr("Déplacement de %n élément(s)", "", int(urls.size())));
#ifdef VINX_HAVE_KIO
    auto *job = KIO::move(urls, destDir, conflict == Replace ? KIO::Overwrite : KIO::DefaultFlags);
    job->setAutoRename(conflict == KeepBoth);
    track(this, job, [this](bool ok, const QString &e) { finish(ok, e); },
          [this](int p) { m_progress = p; Q_EMIT progressChanged(); });
#else
    QTimer::singleShot(0, this, [this, urls, destDir, conflict] {
        QString error;
        const QDir dest(destDir.toLocalFile());
        for (const QUrl &u : urls) {
            const QFileInfo fi(u.toLocalFile());
            if (fi.absolutePath() == dest.absolutePath())
                continue;   // déjà dans ce dossier
            if (dest.absolutePath().startsWith(fi.absoluteFilePath() + QLatin1Char('/')))
                return finish(false, tr("Impossible de déplacer un dossier dans lui-même."));
            if (conflict == Replace && dest.exists(fi.fileName())) {
                const QFileInfo old(dest.filePath(fi.fileName()));
                if (!(old.isDir() ? QDir(old.absoluteFilePath()).removeRecursively() : QFile::remove(old.absoluteFilePath())))
                    return finish(false, tr("Impossible de remplacer « %1 ».").arg(fi.fileName()));
            }
            const QString name = uniqueName(fi.fileName(), [&dest](const QString &n) { return dest.exists(n); });
            if (QFile::rename(fi.absoluteFilePath(), dest.filePath(name)))
                continue;
            // Autre disque : copie puis suppression.
            if (!copyRecursive(fi.absoluteFilePath(), dest.absolutePath(), &error))
                return finish(false, error);
            const bool removed = fi.isDir() ? QDir(fi.absoluteFilePath()).removeRecursively() : QFile::remove(fi.absoluteFilePath());
            if (!removed)
                return finish(false, tr("« %1 » a été copié mais pas supprimé de son emplacement d'origine.").arg(fi.fileName()));
        }
        finish(true, {});
    });
#endif
}

void FileOps::trash(const QList<QUrl> &urls)
{
    if (urls.isEmpty())
        return;
    begin(tr("Mise à la corbeille"));
#ifdef VINX_HAVE_KIO
    track(this, KIO::trash(urls), [this](bool ok, const QString &e) { finish(ok, e); },
          [this](int p) { m_progress = p; Q_EMIT progressChanged(); });
#else
    QTimer::singleShot(0, this, [this, urls] {
        for (const QUrl &u : urls)
            if (!QFile::moveToTrash(u.toLocalFile()))
                return finish(false, tr("Impossible de mettre « %1 » à la corbeille.").arg(u.fileName()));
        finish(true, {});
    });
#endif
}

void FileOps::emptyTrash()
{
#ifdef VINX_HAVE_KIO
    begin(tr("Vidage de la corbeille"));
    track(this, KIO::emptyTrash(), [this](bool ok, const QString &e) { finish(ok, e); }, [](int) {});
#endif
}

void FileOps::restore(const QList<QUrl> &trashUrls)
{
#ifdef VINX_HAVE_KIO
    if (trashUrls.isEmpty())
        return;
    begin(tr("Restauration"));
    track(this, KIO::restoreFromTrash(trashUrls), [this](bool ok, const QString &e) { finish(ok, e); }, [](int) {});
#else
    Q_UNUSED(trashUrls)
#endif
}

void FileOps::deletePermanently(const QList<QUrl> &urls)
{
    if (urls.isEmpty())
        return;
    begin(tr("Suppression"));
#ifdef VINX_HAVE_KIO
    track(this, KIO::del(urls), [this](bool ok, const QString &e) { finish(ok, e); },
          [this](int p) { m_progress = p; Q_EMIT progressChanged(); });
#else
    for (const QUrl &u : urls) {
        const QFileInfo fi(u.toLocalFile());
        if (!(fi.isDir() ? QDir(fi.absoluteFilePath()).removeRecursively() : QFile::remove(fi.absoluteFilePath())))
            return finish(false, tr("Impossible de supprimer « %1 ».").arg(fi.fileName()));
    }
    finish(true, {});
#endif
}

void FileOps::rename(const QUrl &url, const QString &newName)
{
    if (!validName(newName) || newName == url.fileName())
        return;
    const QUrl dest = url.adjusted(QUrl::RemoveFilename).resolved(QUrl(QUrl::toPercentEncoding(newName.trimmed())));
#ifdef VINX_HAVE_KIO
    begin(tr("Renommage"));
    track(this, KIO::moveAs(url, dest, KIO::HideProgressInfo), [this](bool ok, const QString &e) { finish(ok, e); }, [](int) {});
#else
    begin(tr("Renommage"));
    if (QFileInfo::exists(dest.toLocalFile()))
        return finish(false, tr("« %1 » existe déjà.").arg(newName));
    finish(QFile::rename(url.toLocalFile(), dest.toLocalFile()), tr("Impossible de renommer « %1 ».").arg(url.fileName()));
#endif
}

QString FileOps::createFolder(const QUrl &dir, const QString &baseName)
{
    // Le nom libre est déterminé localement (dossiers locaux) ; ailleurs, KIO signale le conflit.
    QString name = baseName;
    if (dir.isLocalFile()) {
        const QDir d(dir.toLocalFile());
        name = uniqueName(baseName, [&d](const QString &n) { return d.exists(n); });
    }
    const QUrl target = QUrl(dir.toString() + QLatin1Char('/')).resolved(QUrl(QUrl::toPercentEncoding(name)));
#ifdef VINX_HAVE_KIO
    begin(tr("Création d'un dossier"));
    track(this, KIO::mkdir(target), [this](bool ok, const QString &e) { finish(ok, e); }, [](int) {});
#else
    begin(tr("Création d'un dossier"));
    finish(QDir().mkdir(target.toLocalFile()), tr("Impossible de créer le dossier."));
#endif
    return name;
}

void FileOps::open(const QUrl &url)
{
#ifdef VINX_HAVE_KIO
    auto *job = new KIO::OpenUrlJob(url);
    // Type inconnu : boîte « Ouvrir avec » ; fichier exécutable : confirmation.
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->setRunExecutables(false);
    job->start();
#else
    QDesktopServices::openUrl(url);
#endif
}

void FileOps::openTerminal(const QUrl &dir)
{
    const QString path = dir.isLocalFile() ? dir.toLocalFile() : QDir::homePath();
    for (const char *term : {"vinx-terminal", "konsole", "x-terminal-emulator", "gnome-terminal", "xterm"}) {
        if (QProcess::startDetached(QString::fromLatin1(term), {}, path))
            return;
    }
    Q_EMIT failed(tr("Aucun terminal n'est installé."));
}

void FileOps::setClipboard(const QList<QUrl> &urls, bool cut)
{
    auto *data = new QMimeData;
    data->setUrls(urls);
    QStringList paths;
    for (const QUrl &u : urls)
        paths.append(u.isLocalFile() ? u.toLocalFile() : u.toString());
    data->setText(paths.join(QLatin1Char('\n')));
    data->setData(kCutMime, cut ? "1" : "0");
    QGuiApplication::clipboard()->setMimeData(data);
}

bool FileOps::canPaste() const
{
    const QMimeData *d = QGuiApplication::clipboard() ? QGuiApplication::clipboard()->mimeData() : nullptr;
    return d && d->hasUrls();
}

QList<QUrl> FileOps::clipboardUrls() const
{
    const QMimeData *d = QGuiApplication::clipboard()->mimeData();
    return d && d->hasUrls() ? d->urls() : QList<QUrl>();
}

bool FileOps::clipboardIsCut() const
{
    const QMimeData *d = QGuiApplication::clipboard()->mimeData();
    return d && d->data(kCutMime) == "1";
}

void FileOps::paste(const QUrl &destDir, int conflict)
{
    const QList<QUrl> urls = clipboardUrls();
    if (urls.isEmpty())
        return;
    if (clipboardIsCut()) {
        move(urls, destDir, conflict);
        QGuiApplication::clipboard()->clear();
    } else {
        copy(urls, destDir, conflict);
    }
}
