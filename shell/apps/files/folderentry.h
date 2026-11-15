#pragma once

#include <QDateTime>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QString>
#include <QUrl>

// Élément d'un dossier, indépendant du moteur (KIO ou local).
struct FolderEntry {
    QString name;
    QUrl url;
    bool isDir = false;
    bool hidden = false;
    qint64 size = 0;
    QDateTime modified;
    QString mimeType;
    QString iconName;

    static FolderEntry fromFileInfo(const QFileInfo &fi)
    {
        static const QMimeDatabase db;
        FolderEntry e;
        e.name = fi.fileName();
        e.url = QUrl::fromLocalFile(fi.absoluteFilePath());
        e.isDir = fi.isDir();
        e.hidden = fi.isHidden() || e.name.startsWith(QLatin1Char('.'));
        e.size = e.isDir ? 0 : fi.size();
        e.modified = fi.lastModified();
        const QMimeType mt = e.isDir ? db.mimeTypeForName(QStringLiteral("inode/directory")) : db.mimeTypeForFile(fi);
        e.mimeType = mt.name();
        e.iconName = mt.iconName();
        return e;
    }
};

// Tri : dossiers d'abord, puis nom (ordre « naturel » : fichier2 avant fichier10).
bool folderEntryLessThan(const FolderEntry &a, const FolderEntry &b);

// « Rapport.odt » → « Rapport (2).odt » : premier nom libre dans exists().
template<typename Exists>
QString uniqueName(const QString &name, Exists exists)
{
    if (!exists(name))
        return name;
    const int dot = name.lastIndexOf(QLatin1Char('.'));
    const bool hasExt = dot > 0;
    const QString base = hasExt ? name.left(dot) : name;
    const QString ext = hasExt ? name.mid(dot) : QString();
    for (int i = 2;; ++i) {
        const QString candidate = QStringLiteral("%1 (%2)%3").arg(base).arg(i).arg(ext);
        if (!exists(candidate))
            return candidate;
    }
}
