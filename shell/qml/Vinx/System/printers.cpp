#include "printers.h"
#include "syscmd.h"
#include "sysparse.h"

Printers::Printers(QObject *parent)
    : QObject(parent)
    , m_available(hasCommand(QStringLiteral("lpstat")))
{
    refresh();
}

void Printers::refresh()
{
    if (!m_available)
        return;
    runCommand(this, QStringLiteral("lpstat"), {QStringLiteral("-p"), QStringLiteral("-d")}, [this](bool, const QString &out, const QString &) {
        m_printers = parseLpstat(out);
        Q_EMIT changed();
    });
}

QVariantList Printers::discovered() const
{
    // Masque les imprimantes déjà ajoutées (même nom de file).
    QVariantList out;
    for (const QVariant &v : m_found) {
        const QString queue = cupsQueueName(v.toMap().value(QStringLiteral("name")).toString());
        bool present = false;
        for (const QVariant &p : m_printers)
            present = present || p.toMap().value(QStringLiteral("name")).toString() == queue;
        if (!present)
            out.append(v);
    }
    return out;
}

void Printers::discover()
{
    if (m_searching)
        return;
    m_searching = true;
    Q_EMIT changed();
    runCommand(this, QStringLiteral("driverless"), {}, [this](bool, const QString &out, const QString &) {
        m_found = parseDriverless(out);
        m_searching = false;
        Q_EMIT changed();
    }, 20000);
}

void Printers::admin(const QStringList &args, const QString &okMessage, const QString &failMessage)
{
    m_busy = true;
    Q_EMIT changed();
    runCommand(this, QStringLiteral("pkexec"), QStringList{vinxAdmin()} + args, [=](bool ok, const QString &, const QString &) {
        m_busy = false;
        Q_EMIT finished(ok, ok ? okMessage : failMessage);
        refresh();
    }, 0);
}

void Printers::add(const QString &displayName, const QString &uri)
{
    const QString queue = cupsQueueName(displayName);
    admin({QStringLiteral("printer-add"), queue, uri}, tr("« %1 » est prête.").arg(displayName),
          tr("Impossible d'ajouter « %1 ».").arg(displayName));
}

void Printers::remove(const QString &name)
{
    admin({QStringLiteral("printer-remove"), name}, tr("Imprimante supprimée."), tr("Impossible de supprimer l'imprimante."));
}

void Printers::setDefault(const QString &name)
{
    // Préférence de l'utilisateur (sans droits administrateur).
    runCommand(this, QStringLiteral("lpoptions"), {QStringLiteral("-d"), name}, [this](bool, const QString &, const QString &) { refresh(); });
}

void Printers::printTestPage(const QString &name)
{
    runCommand(this, QStringLiteral("lp"), {QStringLiteral("-d"), name, QStringLiteral("/usr/share/cups/data/testprint")},
               [this](bool ok, const QString &, const QString &) {
                   Q_EMIT finished(ok, ok ? tr("Page de test envoyée.") : tr("Impossible d'imprimer la page de test."));
                   refresh();
               });
}

void Printers::cancelJobs(const QString &name)
{
    runCommand(this, QStringLiteral("cancel"), {QStringLiteral("-a"), name}, [this](bool ok, const QString &, const QString &) {
        Q_EMIT finished(ok, ok ? tr("Impressions annulées.") : tr("Impossible d'annuler les impressions."));
        refresh();
    });
}
