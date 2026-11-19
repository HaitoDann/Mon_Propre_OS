#pragma once

#include <QIcon>
#include <QPixmap>
#include <QQuickImageProvider>

// image://theme/<nom> : icônes du thème système (applications, types de fichiers).
class ThemeIconProvider : public QQuickImageProvider
{
public:
    ThemeIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requested) override
    {
        const QSize s = requested.isValid() ? requested : QSize(64, 64);
        QIcon icon = QIcon::fromTheme(id);
        if (icon.isNull() && id.contains(QLatin1Char('-')))   // « application-x-foo » → « application-x-generic »
            icon = QIcon::fromTheme(id.section(QLatin1Char('-'), 0, 0) + QStringLiteral("-x-generic"));
        // Pixmap vide si l'icône est absente : le QML affiche alors un pictogramme VinX.
        // (1 × 1 transparent plutôt que vide, pour éviter un avertissement du moteur QML.)
        QPixmap pm = icon.isNull() ? QPixmap() : icon.pixmap(s);
        if (pm.isNull()) {
            pm = QPixmap(1, 1);
            pm.fill(Qt::transparent);
        }
        if (size)
            *size = pm.size();
        return pm;
    }
};
