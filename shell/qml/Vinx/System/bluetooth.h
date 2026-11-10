#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// Adaptateur Bluetooth principal via BlueZ.
class Bluetooth : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(bool powered READ powered WRITE setPowered NOTIFY changed)

public:
    explicit Bluetooth(QObject *parent = nullptr);
    bool available() const { return m_available; }
    bool powered() const { return m_powered; }
    void setPowered(bool on);

Q_SIGNALS:
    void changed();

private Q_SLOTS:
    void refresh();

private:
    bool m_available = false;
    bool m_powered = false;
};
