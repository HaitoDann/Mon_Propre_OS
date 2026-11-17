#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Détecteur de pilotes : composants (lspci), paquets recommandés (isenkram) et pilote NVIDIA,
// installation via l'outil administrateur VinX.
class Drivers : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool scanning READ scanning NOTIFY changed)
    Q_PROPERTY(bool installing READ installing NOTIFY changed)
    Q_PROPERTY(bool scanned READ scanned NOTIFY changed)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY changed)        // [{ category, name, vendor }]
    Q_PROPERTY(QVariantList suggestions READ suggestions NOTIFY changed) // [{ package, reason, nonFree }]

public:
    explicit Drivers(QObject *parent = nullptr);
    bool scanning() const { return m_steps > 0; }
    bool installing() const { return m_installing; }
    bool scanned() const { return m_scanned; }
    QVariantList devices() const { return m_devices; }
    QVariantList suggestions() const { return m_suggestions; }

    Q_INVOKABLE void scan();
    Q_INVOKABLE void install(const QStringList &packages);

Q_SIGNALS:
    void changed();
    void finished(bool success, const QString &message);

private:
    void stepDone();
    void filterInstalled(QVariantList candidates);
    int m_steps = 0;
    bool m_installing = false;
    bool m_scanned = false;
    QVariantList m_devices, m_suggestions, m_candidates;
};
