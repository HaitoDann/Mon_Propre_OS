#pragma once
// Langue de l'interface VinX (ADR 0034) : le français est la langue source ; toute autre langue
// (préférence interface/language, ou langue du système si « automatique ») charge l'anglais.
#include <QCoreApplication>
#include <QDir>
#include <QLocale>
#include <QSettings>
#include <QStandardPaths>
#include <QTranslator>

inline QString vinxLanguage()
{
    QSettings s(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/vinx/shell.ini"),
                QSettings::IniFormat);
    const QString pref = s.value(QStringLiteral("interface/language")).toString();
    const QString lang = pref.isEmpty() ? QLocale::system().name().left(2) : pref;
    return lang == QLatin1String("fr") || lang.isEmpty() || lang == QLatin1String("C") ? QStringLiteral("fr") : QStringLiteral("en");
}

inline void vinxInstallTranslator(QCoreApplication &app)
{
    if (vinxLanguage() == QLatin1String("fr"))
        return;
    auto *translator = new QTranslator(&app);
    const QStringList dirs = {
#ifdef VINX_BUILD_TRANSLATIONS_DIR
        QStringLiteral(VINX_BUILD_TRANSLATIONS_DIR),
#endif
        QStringLiteral("/usr/share/vinx/translations")};
    for (const QString &dir : dirs)
        if (translator->load(QStringLiteral("vinx_en"), dir)) {
            app.installTranslator(translator);
            QLocale::setDefault(QLocale(QStringLiteral("en_GB")));   // dates, jours de la semaine
            return;
        }
    delete translator;
}
