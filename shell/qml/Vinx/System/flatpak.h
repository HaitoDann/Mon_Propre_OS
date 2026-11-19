#pragma once

#include <QDateTime>
#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Installation d'applications Flatpak (Flathub) pour le Store, dans l'espace utilisateur
// (--user : aucune authentification administrateur requise).
class Flatpak : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(QStringList installed READ installed NOTIFY installedChanged)
    // Applications installées : [{ id, name, version }] (toutes installations confondues).
    Q_PROPERTY(QVariantList installedApps READ installedApps NOTIFY installedChanged)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchResultsChanged)
    Q_PROPERTY(bool searching READ searching NOTIFY searchResultsChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString task READ task NOTIFY busyChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    // Incrémenté quand le catalogue AppStream (logos) vient d'être téléchargé : à lire dans les
    // liaisons qui appellent iconUrl() pour qu'elles se réévaluent.
    Q_PROPERTY(int iconsRevision READ iconsRevision NOTIFY iconsChanged)

public:
    explicit Flatpak(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QStringList installed() const { return m_installed; }
    QVariantList installedApps() const { return m_installedApps; }
    QVariantList searchResults() const { return m_results; }
    bool searching() const { return m_searching; }
    // Recherche sur Flathub (« flatpak search ») : résultats dans searchResults.
    Q_INVOKABLE void search(const QString &query);
    bool busy() const { return m_process != nullptr; }
    QString task() const { return m_task; }
    int progress() const { return m_progress; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool isInstalled(const QString &appId) const { return m_installed.contains(appId); }
    // label : texte affiché et utilisé dans la notification de fin (ex. « Pack Graphisme »).
    Q_INVOKABLE bool install(const QStringList &appIds, const QString &label);
    Q_INVOKABLE bool uninstall(const QStringList &appIds, const QString &label);
    Q_INVOKABLE bool launch(const QString &appId) const;
    // Fiche d'une application Flathub (version, licence, tailles) → detailsReady.
    Q_INVOKABLE void details(const QString &appId);
    // Logo d'une application Flathub (cache AppStream de Flatpak, ou icône exportée si installée) ; "" sinon.
    Q_INVOKABLE QString iconUrl(const QString &appId) const;
    // Télécharge le catalogue AppStream de Flathub (noms, logos) s'il manque ou date de plus de
    // 24 h, en arrière-plan (« flatpak update --appstream », autorisé sans mot de passe par polkit).
    Q_INVOKABLE void refreshAppstream();
    int iconsRevision() const { return m_iconsRevision; }
    // Catalogue absent, de plus de 24 h ou daté dans le futur (horloge corrigée) : à retélécharger.
    static bool appstreamStale(const QDateTime &lastUpdate, const QDateTime &now);

    static int parseProgress(const QString &output);   // dernier « NN% » de la sortie, -1 sinon

Q_SIGNALS:
    void installedChanged();
    void busyChanged();
    void progressChanged();
    void searchResultsChanged();
    void finished(bool success, const QString &message);
    void detailsReady(const QString &appId, const QVariantMap &info);
    void iconsChanged();

private:
    bool start(const QStringList &args, const QString &task, const QString &doneMessage);

    bool m_available = false;
    QStringList m_installed;
    QVariantList m_installedApps, m_results;
    bool m_searching = false;
    int m_searchSerial = 0;
    QProcess *m_process = nullptr;
    QString m_task;
    int m_progress = -1;
    int m_iconsRevision = 0;
    bool m_appstreamRunning = false;
};
