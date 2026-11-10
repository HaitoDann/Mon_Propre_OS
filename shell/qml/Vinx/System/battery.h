#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// Batterie via UPower (périphérique d'affichage agrégé). present = false sur un poste fixe.
class Battery : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool present READ present NOTIFY changed)
    Q_PROPERTY(int percentage READ percentage NOTIFY changed)
    Q_PROPERTY(bool charging READ charging NOTIFY changed)

public:
    explicit Battery(QObject *parent = nullptr);
    bool present() const { return m_present; }
    int percentage() const { return m_percentage; }
    bool charging() const { return m_charging; }

Q_SIGNALS:
    void changed();

private Q_SLOTS:
    void refresh();

private:
    bool m_present = false;
    int m_percentage = 0;
    bool m_charging = false;
};
