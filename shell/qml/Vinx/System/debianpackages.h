#pragma once

#include <QObject>
#include <QProcess>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Logiciels du dépôt Debian pour le Store : recherche visuelle (AppStream : nom, résumé, icône),
// outils techniques (apt), fiche détaillée, installation et suppression via PackageKit (polkit).
class DebianPackages : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(QVariantList results READ results NOTIFY resultsChanged)  // [{ id, name, summary, package, icon, installed }]
    Q_PROPERTY(bool searching READ searching NOTIFY resultsChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString task READ task NOTIFY busyChanged)
    Q_PROPERTY(int progress READ progress NOTIFY busyChanged)
    // Fiches des logiciels du catalogue du Store : paquet → { name, summary, package, icon, iconUrl, installed }
    // (seuls les paquets présents dans le dépôt Debian y figurent).
    Q_PROPERTY(QVariantMap catalog READ catalog NOTIFY catalogChanged)
    Q_PROPERTY(bool catalogLoading READ catalogLoading NOTIFY catalogChanged)

public:
    explicit DebianPackages(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QVariantList results() const { return m_results; }
    bool searching() const { return m_searching; }
    bool busy() const { return m_proc != nullptr; }
    QString task() const { return m_task; }
    int progress() const { return m_progress; }
    QVariantMap catalog() const { return m_catalog; }
    bool catalogLoading() const { return !m_lookupQueue.isEmpty(); }

    // tools : inclut les paquets sans interface (outils en ligne de commande, bibliothèques).
    Q_INVOKABLE void search(const QString &query, bool tools = false);
    Q_INVOKABLE void details(const QString &package);
    Q_INVOKABLE void install(const QString &package, const QString &label);
    Q_INVOKABLE void remove(const QString &package, const QString &label);
    Q_INVOKABLE bool launch(const QString &desktopId) const;
    // Charge les fiches AppStream (nom, résumé, logo) des paquets du catalogue, une à une.
    Q_INVOKABLE void lookup(const QStringList &packages);

Q_SIGNALS:
    void resultsChanged();
    void busyChanged();
    void detailsReady(const QString &package, const QVariantMap &info);
    void finished(bool success, const QString &message);
    void catalogChanged();

private:
    void markInstalled(QVariantList list, int serial);
    void lookupNext();
    void refreshCatalogInstalled();
    QVariantMap m_catalog;
    QStringList m_lookupQueue;
    void runPkcon(const QStringList &args, const QString &task, const QString &okMsg, const QString &failMsg);
    bool m_available = false;
    bool m_searching = false;
    int m_serial = 0;
    QVariantList m_results;
    QProcess *m_proc = nullptr;
    QString m_task;
    int m_progress = -1;
};
