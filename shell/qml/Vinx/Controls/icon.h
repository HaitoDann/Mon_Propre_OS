#pragma once

#include <QColor>
#include <QQuickPaintedItem>
#include <QSvgRenderer>
#include <QtQml/qqmlregistration.h>

// Icône SVG du jeu VinX, recolorée à la volée (remplace « currentColor »).
// Usage QML : Icon { name: "wifi"; color: Theme.text; width: 16; height: 16 }
class Icon : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)

public:
    explicit Icon(QQuickItem *parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString &name);
    QColor color() const { return m_color; }
    void setColor(const QColor &color);
    bool isValid() const { return m_renderer.isValid(); }

    void paint(QPainter *painter) override;

Q_SIGNALS:
    void nameChanged();
    void colorChanged();
    void validChanged();

private:
    void reload();

    QString m_name;
    QColor m_color = Qt::white;
    QByteArray m_source;
    QSvgRenderer m_renderer;
};
