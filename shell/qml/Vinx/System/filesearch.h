#pragma once

#include <QDateTime>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Recherche de fichiers par nom dans les dossiers personnels usuels (Documents, Bureau,
// Téléchargements, Images, Musique, Vidéos). Index léger reconstruit au plus toutes les 60 s.
class FileSearch : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit FileSearch(QObject *parent = nullptr);
    // [{ name, path, folder }] dont le nom contient la requête (sans accents ni casse).
    Q_INVOKABLE QVariantList search(const QString &query, int limit = 6);
    Q_INVOKABLE bool open(const QString &path) const;
    Q_INVOKABLE bool openUrl(const QString &url) const;

    static QString fold(const QString &s);   // minuscules, sans accents

private:
    void refresh();
    QStringList m_paths;
    QStringList m_folded;
    QDateTime m_built;
};
