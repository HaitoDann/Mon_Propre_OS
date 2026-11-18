#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// Paramètres → Bureautique (ADR 0029) : format d'enregistrement de LibreOffice et polices compatibles.
class Office : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString format READ format NOTIFY changed)            // « msoffice », « odf » ou ""
    Q_PROPERTY(bool libreOfficeInstalled READ libreOfficeInstalled CONSTANT)
    Q_PROPERTY(QStringList missingFonts READ missingFonts NOTIFY changed)
public:
    explicit Office(QObject *parent = nullptr);
    QString format() const { return m_format; }
    bool libreOfficeInstalled() const;
    QStringList missingFonts() const { return m_missing; }
    Q_INVOKABLE bool setFormat(const QString &format);
    Q_INVOKABLE bool libreOfficeRunning() const;
    Q_INVOKABLE void refresh();
Q_SIGNALS:
    void changed();
private:
    QString profilePath() const;
    QString m_format;
    QStringList m_missing;
};
