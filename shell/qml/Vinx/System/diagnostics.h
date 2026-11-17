#pragma once

#include <QDateTime>
#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Assistant de dépannage : lit le journal du système et de la session, vérifie l'espace disque
// et l'accès à Internet, et traduit ce qu'il trouve en problèmes compréhensibles (diagparse.h).
class Diagnostics : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QVariantList issues READ issues NOTIFY changed)
    // Journal système illisible sans droits : une analyse complète (mot de passe) est proposée.
    Q_PROPERTY(bool limited READ limited NOTIFY changed)
    Q_PROPERTY(QDateTime lastRun READ lastRun NOTIFY changed)
    Q_PROPERTY(QString details READ details NOTIFY changed)

public:
    explicit Diagnostics(QObject *parent = nullptr);
    bool running() const { return m_pending > 0; }
    QVariantList issues() const { return m_issues; }
    bool limited() const { return m_limited; }
    QDateTime lastRun() const { return m_lastRun; }
    QString details() const { return m_details; }

    // full : lit le journal système complet (mot de passe administrateur).
    Q_INVOKABLE void run(bool full = false);

Q_SIGNALS:
    void changed();

private:
    void done();
    int m_pending = 0;
    bool m_limited = false;
    QString m_log;
    QVariantList m_extra, m_issues;
    QDateTime m_lastRun;
    QString m_details;
};
