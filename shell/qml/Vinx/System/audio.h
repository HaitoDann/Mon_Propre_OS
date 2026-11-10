#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

// Volume de la sortie audio par défaut (PipeWire), via l'outil wpctl de WirePlumber.
// Implémentation simple pour la v0.1 ; une liaison native PipeWire viendra plus tard.
class Audio : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY changed)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY changed)

public:
    explicit Audio(QObject *parent = nullptr);
    bool available() const { return m_available; }
    double volume() const { return m_volume; }
    bool muted() const { return m_muted; }
    void setVolume(double volume);
    void setMuted(bool muted);

public Q_SLOTS:
    void refresh();

Q_SIGNALS:
    void changed();

private:
    void run(const QStringList &args);

    bool m_available = false;
    double m_volume = 0;
    bool m_muted = false;
    QTimer m_poll;
};
