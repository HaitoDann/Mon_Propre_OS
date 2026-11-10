#include "icon.h"

#include <QFile>
#include <QPainter>

Icon::Icon(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
    setImplicitSize(16, 16);
}

void Icon::setName(const QString &name)
{
    if (name == m_name)
        return;
    m_name = name;
    QFile file(QStringLiteral(":/qt/qml/Vinx/Controls/icons/%1.svg").arg(name));
    m_source = file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
    if (m_source.isEmpty())
        qWarning("Vinx.Controls: icône inconnue « %s »", qUtf8Printable(name));
    reload();
    Q_EMIT nameChanged();
}

void Icon::setColor(const QColor &color)
{
    if (color == m_color)
        return;
    m_color = color;
    reload();
    Q_EMIT colorChanged();
}

void Icon::reload()
{
    const bool wasValid = m_renderer.isValid();
    QByteArray svg = m_source;
    svg.replace("currentColor", m_color.name(QColor::HexRgb).toLatin1());
    m_renderer.load(svg);
    if (wasValid != m_renderer.isValid())
        Q_EMIT validChanged();
    update();
}

void Icon::paint(QPainter *painter)
{
    if (!m_renderer.isValid())
        return;
    painter->setOpacity(m_color.alphaF());
    m_renderer.render(painter, boundingRect());
}
