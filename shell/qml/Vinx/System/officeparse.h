#pragma once
// Compatibilité Microsoft Office (ADR 0029) : format d'enregistrement par défaut de LibreOffice,
// lu et écrit dans le profil de l'utilisateur (registrymodifications.xcu). Pur : tests/tst_office.cpp.
#include <QRegularExpression>
#include <QString>
#include <QStringList>

namespace office {

struct Factory { const char *service; const char *ms; const char *odf; };
inline const Factory factories[] = {
    {"com.sun.star.text.TextDocument", "MS Word 2007 XML", "writer8"},
    {"com.sun.star.sheet.SpreadsheetDocument", "Calc MS Excel 2007 XML", "calc8"},
    {"com.sun.star.presentation.PresentationDocument", "Impress MS PowerPoint 2007 XML", "impress8"},
};

inline QString itemPath(const char *service)
{
    return QStringLiteral("/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['%1']").arg(QLatin1String(service));
}

inline QString filterItem(const char *service, const QString &filter)
{
    return QStringLiteral("<item oor:path=\"%1\"><prop oor:name=\"ooSetupFactoryDefaultFilter\" oor:op=\"fuse\"><value>%2</value></prop></item>")
        .arg(itemPath(service), filter);
}

inline QString warnItem(bool warn)
{
    return QStringLiteral("<item oor:path=\"/org.openoffice.Office.Common/Save/Document\"><prop oor:name=\"WarnAlienFormat\" oor:op=\"fuse\"><value>%1</value></prop></item>")
        .arg(warn ? QStringLiteral("true") : QStringLiteral("false"));
}

inline QString emptyXcu()
{
    return QStringLiteral("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                          "<oor:items xmlns:oor=\"http://openoffice.org/2001/registry\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n"
                          "</oor:items>\n");
}

// Retire les éléments <item …> dont le chemin et la propriété correspondent.
inline QString removeItems(QString xcu, const QString &path, const QString &prop)
{
    const QRegularExpression re(QStringLiteral("<item oor:path=\"%1\"><prop oor:name=\"%2\"[^>]*>.*?</prop></item>\\n?")
                                    .arg(QRegularExpression::escape(path), QRegularExpression::escape(prop)),
                                QRegularExpression::DotMatchesEverythingOption);
    return xcu.remove(re);
}

// « msoffice », « odf » ou "" (réglage de LibreOffice / du système).
inline QString readFormat(const QString &xcu)
{
    int ms = 0, odf = 0;
    for (const Factory &f : factories) {
        const QRegularExpression re(QStringLiteral("<item oor:path=\"%1\"><prop oor:name=\"ooSetupFactoryDefaultFilter\"[^>]*><value>([^<]*)</value>")
                                        .arg(QRegularExpression::escape(itemPath(f.service))));
        const QString v = re.match(xcu).captured(1);
        if (v == QLatin1String(f.ms)) ++ms;
        else if (v == QLatin1String(f.odf)) ++odf;
    }
    return ms == 3 ? QStringLiteral("msoffice") : odf == 3 ? QStringLiteral("odf") : QString();
}

// Écrit les trois formats par défaut (Writer, Calc, Impress). En format Microsoft, l'avertissement
// « Garder le format actuel ? » est désactivé.
inline QString writeFormat(QString xcu, const QString &format)
{
    if (xcu.trimmed().isEmpty() || !xcu.contains(QLatin1String("</oor:items>")))
        xcu = emptyXcu();
    const bool ms = format == QLatin1String("msoffice");
    QString items;
    for (const Factory &f : factories) {
        xcu = removeItems(xcu, itemPath(f.service), QStringLiteral("ooSetupFactoryDefaultFilter"));
        items += filterItem(f.service, QLatin1String(ms ? f.ms : f.odf)) + QLatin1Char('\n');
    }
    xcu = removeItems(xcu, QStringLiteral("/org.openoffice.Office.Common/Save/Document"), QStringLiteral("WarnAlienFormat"));
    items += warnItem(!ms) + QLatin1Char('\n');
    return xcu.replace(QLatin1String("</oor:items>"), items + QLatin1String("</oor:items>"));
}

} // namespace office
