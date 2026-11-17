#include "drivers.h"
#include "syscmd.h"
#include "sysparse.h"

namespace {
QString category(const QString &classId)
{
    const QString c = classId.left(2);
    if (c == QLatin1String("03")) return QObject::tr("Graphique");
    if (c == QLatin1String("02") || classId == QLatin1String("0d11") || classId == QLatin1String("0d80")) return QObject::tr("Réseau");
    if (c == QLatin1String("04")) return QObject::tr("Son et vidéo");
    if (classId == QLatin1String("0c03")) return QObject::tr("USB");
    if (c == QLatin1String("01")) return QObject::tr("Stockage");
    return {};
}
}

Drivers::Drivers(QObject *parent)
    : QObject(parent)
{
}

void Drivers::scan()
{
    if (scanning())
        return;
    m_candidates.clear();
    m_steps = 2;
    Q_EMIT changed();

    runCommand(this, QStringLiteral("lspci"), {QStringLiteral("-mm"), QStringLiteral("-nn")}, [this](bool, const QString &out, const QString &) {
        QVariantList shown;
        bool nvidia = false;
        for (const QVariant &v : parseLspci(out)) {
            const QVariantMap d = v.toMap();
            const QString cat = category(d.value(QStringLiteral("classId")).toString());
            if (cat.isEmpty())
                continue;
            shown.append(QVariantMap{{QStringLiteral("category"), cat}, {QStringLiteral("name"), d.value(QStringLiteral("name"))},
                                     {QStringLiteral("vendor"), d.value(QStringLiteral("vendor"))}});
            nvidia = nvidia || (d.value(QStringLiteral("vendorId")) == QLatin1String("10de") && cat == tr("Graphique"));
        }
        m_devices = shown;
        if (nvidia)
            m_candidates.append(QVariantMap{{QStringLiteral("package"), QStringLiteral("nvidia-driver")},
                                            {QStringLiteral("reason"), tr("Pilote NVIDIA officiel : meilleures performances 3D et vidéo que le pilote libre.")},
                                            {QStringLiteral("nonFree"), true}});
        stepDone();
    });

    // isenkram : paquets (micrologiciels, outils) correspondant au matériel présent.
    runCommand(this, QStringLiteral("isenkram-lookup"), {}, [this](bool, const QString &out, const QString &) {
        for (const QString &raw : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
            const QString pkg = raw.trimmed();
            if (pkg.isEmpty() || pkg.contains(QLatin1Char(' ')))
                continue;
            const QString reason = pkg.startsWith(QLatin1String("firmware-")) ? tr("Micrologiciel pour un composant de cet ordinateur.")
                                                                              : tr("Prise en charge d'un composant de cet ordinateur.");
            m_candidates.append(QVariantMap{{QStringLiteral("package"), pkg}, {QStringLiteral("reason"), reason},
                                            {QStringLiteral("nonFree"), pkg == QLatin1String("nvidia-driver")}});
        }
        stepDone();
    }, 60000);
}

void Drivers::stepDone()
{
    if (--m_steps > 0)
        return;
    filterInstalled(m_candidates);
}

void Drivers::filterInstalled(QVariantList candidates)
{
    QStringList names;
    for (const QVariant &v : candidates)
        names << v.toMap().value(QStringLiteral("package")).toString();
    names.removeDuplicates();
    if (names.isEmpty()) {
        m_suggestions.clear();
        m_scanned = true;
        Q_EMIT changed();
        return;
    }
    m_steps = 1;
    runCommand(this, QStringLiteral("dpkg-query"), QStringList{QStringLiteral("-W"), QStringLiteral("-f=${Package} ${db:Status-Abbrev}\\n")} + names,
               [this, candidates](bool, const QString &out, const QString &) {
                   QStringList installed;
                   for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts))
                       if (line.section(QLatin1Char(' '), 1, 1).startsWith(QLatin1String("ii")))
                           installed << line.section(QLatin1Char(' '), 0, 0);
                   QVariantList out2;
                   QStringList seen;
                   for (const QVariant &v : candidates) {
                       const QString pkg = v.toMap().value(QStringLiteral("package")).toString();
                       if (installed.contains(pkg) || seen.contains(pkg))
                           continue;
                       seen << pkg;
                       out2.append(v);
                   }
                   m_suggestions = out2;
                   m_steps = 0;
                   m_scanned = true;
                   Q_EMIT changed();
               });
}

void Drivers::install(const QStringList &packages)
{
    if (packages.isEmpty() || m_installing)
        return;
    m_installing = true;
    Q_EMIT changed();
    runCommand(this, QStringLiteral("pkexec"), QStringList{vinxAdmin(), QStringLiteral("install")} + packages,
               [this](bool ok, const QString &, const QString &) {
                   m_installing = false;
                   Q_EMIT finished(ok, ok ? tr("Pilotes installés. Redémarrez l'ordinateur pour les utiliser.")
                                          : tr("L'installation a échoué. Vérifiez la connexion à Internet."));
                   scan();
               }, 0);
}
