#include "filesearch.h"

#include <QDesktopServices>
#include <QDirIterator>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUrl>

namespace {
constexpr int kMaxFiles = 20000;
}

FileSearch::FileSearch(QObject *parent)
    : QObject(parent)
{
}

QString FileSearch::fold(const QString &s)
{
    QString out;
    out.reserve(s.size());
    for (const QChar c : s.normalized(QString::NormalizationForm_D))
        if (c.category() != QChar::Mark_NonSpacing)
            out.append(c.toLower());
    return out;
}

void FileSearch::refresh()
{
    if (m_built.isValid() && m_built.secsTo(QDateTime::currentDateTime()) < 60)
        return;
    m_paths.clear();
    m_folded.clear();
    const QList<QStandardPaths::StandardLocation> roots = {
        QStandardPaths::DocumentsLocation, QStandardPaths::DesktopLocation, QStandardPaths::DownloadLocation,
        QStandardPaths::PicturesLocation, QStandardPaths::MusicLocation, QStandardPaths::MoviesLocation};
    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    for (const auto loc : roots) {
        const QString root = QStandardPaths::writableLocation(loc);
        if (root.isEmpty() || root == home)
            continue;   // ne jamais indexer tout le dossier personnel
        QDirIterator it(root, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext() && m_paths.size() < kMaxFiles) {
            const QString path = it.next();
            if (path.contains(QLatin1String("/.")))
                continue;   // fichiers et dossiers cachés
            m_paths.append(path);
            m_folded.append(fold(it.fileName()));
        }
    }
    m_built = QDateTime::currentDateTime();
}

QVariantList FileSearch::search(const QString &query, int limit)
{
    const QString q = fold(query.trimmed());
    if (q.size() < 2)
        return {};
    refresh();
    QVariantList out;
    for (int i = 0; i < m_paths.size() && out.size() < limit; ++i) {
        if (!m_folded.at(i).contains(q))
            continue;
        const QFileInfo fi(m_paths.at(i));
        out.append(QVariantMap{{QStringLiteral("name"), fi.fileName()}, {QStringLiteral("path"), fi.absoluteFilePath()},
                               {QStringLiteral("folder"), fi.dir().dirName()}});
    }
    return out;
}

bool FileSearch::open(const QString &path) const
{
    return QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

bool FileSearch::openUrl(const QString &url) const
{
    return QDesktopServices::openUrl(QUrl(url));
}
