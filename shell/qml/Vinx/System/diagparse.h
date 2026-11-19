#pragma once

#include <QRegularExpression>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QtGlobal>
#include <algorithm>
#include <functional>

// Assistant de dépannage : traduit les messages techniques du journal en problèmes compréhensibles.
// Chaque règle : motif, gravité, titre, conseil, action proposée (page de Paramètres ou commande).
// Testé dans tests/tst_diag.cpp.

struct DiagRule {
    const char *id;
    const char *pattern;      // expression régulière (insensible à la casse)
    int severity;             // 2 = important, 1 = à surveiller
    const char *title;        // %1 = première capture éventuelle
    const char *advice;
    const char *action;       // « page:printers », « page:drivers »… ou vide
    const char *actionLabel;
};

inline const QList<DiagRule> &diagRules()
{
    static const QList<DiagRule> rules = {
        {"printer-unreachable", R"((Unable to locate printer|The printer is not responding|printer may not exist or is unavailable|Network host .* is busy|No route to host.*ipp|cupsd.*(Unable to connect|Connection refused)))", 2,
         QT_TRANSLATE_NOOP("Diag", "Votre imprimante n'est pas joignable"),
         QT_TRANSLATE_NOOP("Diag", "Vérifiez qu'elle est allumée et connectée au même réseau (Wi-Fi ou câble) que l'ordinateur, puis relancez l'impression."),
         "page:printers", QT_TRANSLATE_NOOP("Diag", "Ouvrir Imprimantes")},
        {"wifi-auth", R"((secrets were required|4-Way Handshake failed|WRONG_KEY|reason=15))", 2,
         QT_TRANSLATE_NOOP("Diag", "La connexion Wi-Fi a été refusée"),
         QT_TRANSLATE_NOOP("Diag", "Le mot de passe enregistré est probablement incorrect ou a changé. Oubliez le réseau puis reconnectez-vous."),
         "page:network", QT_TRANSLATE_NOOP("Diag", "Ouvrir Réseau")},
        {"wifi-drop", R"((CTRL-EVENT-DISCONNECTED|association took too long|beacon loss|deauthenticating))", 1,
         QT_TRANSLATE_NOOP("Diag", "Le Wi-Fi s'est déconnecté plusieurs fois"),
         QT_TRANSLATE_NOOP("Diag", "Le signal est peut-être faible : rapprochez-vous de la box ou utilisez la bande 2,4 GHz, plus stable à distance."),
         "page:network", QT_TRANSLATE_NOOP("Diag", "Ouvrir Réseau")},
        {"firmware-missing", R"((?:Direct firmware load for|firmware: failed to load) (\S+))", 2,
         QT_TRANSLATE_NOOP("Diag", "Un composant n'a pas son micrologiciel (%1)"),
         QT_TRANSLATE_NOOP("Diag", "Un composant (souvent le Wi-Fi, le Bluetooth ou la carte graphique) peut mal fonctionner. Le détecteur de pilotes peut installer ce qui manque."),
         "page:drivers", QT_TRANSLATE_NOOP("Diag", "Ouvrir Pilotes")},
        {"disk-error", R"((I/O error, dev (\w+)|EXT4-fs error|BTRFS error|Buffer I/O error|ata\d+.*failed command))", 2,
         QT_TRANSLATE_NOOP("Diag", "Le disque signale des erreurs"),
         QT_TRANSLATE_NOOP("Diag", "Sauvegardez vos documents dès maintenant sur un disque externe ou en ligne : le disque pourrait être en train de faiblir."),
         "page:backup", QT_TRANSLATE_NOOP("Diag", "Ouvrir Sauvegarde")},
        {"oom", R"((Out of memory: Killed process \d+ \((\S+)\)|oom-kill))", 1,
         QT_TRANSLATE_NOOP("Diag", "La mémoire a été saturée"),
         QT_TRANSLATE_NOOP("Diag", "Une application a été fermée car la mémoire était pleine. Fermez les onglets ou applications inutiles."),
         "", ""},
        {"bluetooth", R"((bluetoothd.*(Failed to set mode|Authentication Failed|Connection refused)|Bluetooth: hci\d+: .*(failed|timeout)))", 1,
         QT_TRANSLATE_NOOP("Diag", "Le Bluetooth rencontre des erreurs"),
         QT_TRANSLATE_NOOP("Diag", "Éteignez puis rallumez le Bluetooth depuis le centre de contrôle, puis ré-appairez l'appareil."),
         "", ""},
        {"gpu-hang", R"((GPU HANG|amdgpu.*ring .* timeout|nouveau .*fifo.*(fault|error)|i915.*GPU HANG))", 2,
         QT_TRANSLATE_NOOP("Diag", "La carte graphique s'est bloquée"),
         QT_TRANSLATE_NOOP("Diag", "Installez les pilotes graphiques recommandés et les mises à jour du système."),
         "page:drivers", QT_TRANSLATE_NOOP("Diag", "Ouvrir Pilotes")},
        {"audio", R"((pipewire.*(error|failed)|wireplumber.*(error|failed)|snd_hda_intel.*(failed|timeout)))", 1,
         QT_TRANSLATE_NOOP("Diag", "Le son rencontre des erreurs"),
         QT_TRANSLATE_NOOP("Diag", "Vérifiez la sortie audio choisie dans Paramètres → Son. Une déconnexion de la session relance le service du son."),
         "page:sound", QT_TRANSLATE_NOOP("Diag", "Ouvrir Son")},
        {"service-failed", R"(Failed to start (?:\S+\.(?:service|mount|socket|timer) - )?(.+?)\.?$)", 1,
         QT_TRANSLATE_NOOP("Diag", "Un service n'a pas démarré : %1"),
         QT_TRANSLATE_NOOP("Diag", "Si une fonction manque, redémarrez l'ordinateur. Si le problème revient, installez les mises à jour."),
         "page:updates", QT_TRANSLATE_NOOP("Diag", "Ouvrir Mises à jour")},
        {"shell-crash", R"(vinx-shell: arrêt anormal)", 1,
         QT_TRANSLATE_NOOP("Diag", "Le bureau VinX a redémarré après une erreur"),
         QT_TRANSLATE_NOOP("Diag", "Il s'est relancé tout seul. Si cela se répète, installez les mises à jour."),
         "page:updates", QT_TRANSLATE_NOOP("Diag", "Ouvrir Mises à jour")},
    };
    return rules;
}

// Analyse des lignes de journal → problèmes uniques : [{ id, severity, title, advice, action,
// actionLabel, count, sample }], les plus graves et les plus fréquents d'abord.
inline QVariantList diagnoseLog(const QString &log, const std::function<QString(const char *)> &tr)
{
    struct Hit { const DiagRule *rule; QString detail; int count; QString sample; };
    QList<Hit> hits;
    QList<QRegularExpression> res;
    for (const DiagRule &r : diagRules())
        res << QRegularExpression(QString::fromUtf8(r.pattern), QRegularExpression::CaseInsensitiveOption);
    for (const QString &line : log.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        for (int i = 0; i < diagRules().size(); ++i) {
            const auto m = res[i].match(line);
            if (!m.hasMatch())
                continue;
            const DiagRule *rule = &diagRules()[i];
            // Une entrée par règle (et par détail pour les micrologiciels et services).
            const bool perDetail = QByteArray(rule->id) == "firmware-missing" || QByteArray(rule->id) == "service-failed";
            const QString detail = perDetail ? m.captured(m.lastCapturedIndex()).trimmed() : QString();
            auto it = std::find_if(hits.begin(), hits.end(), [&](const Hit &h) { return h.rule == rule && h.detail == detail; });
            if (it != hits.end())
                ++it->count;
            else
                hits.append({rule, detail, 1, line.trimmed().left(300)});
            break;
        }
    }
    // Les déconnexions Wi-Fi isolées sont normales (mise en veille) : seulement si fréquentes.
    hits.erase(std::remove_if(hits.begin(), hits.end(), [](const Hit &h) { return QByteArray(h.rule->id) == "wifi-drop" && h.count < 3; }), hits.end());
    std::sort(hits.begin(), hits.end(), [](const Hit &a, const Hit &b) {
        return a.rule->severity != b.rule->severity ? a.rule->severity > b.rule->severity : a.count > b.count;
    });
    QVariantList out;
    for (const Hit &h : hits) {
        QString title = tr(h.rule->title);
        if (title.contains(QLatin1String("%1")))
            title = title.arg(h.detail.isEmpty() ? QStringLiteral("?") : h.detail);
        out.append(QVariantMap{{QStringLiteral("id"), QString::fromLatin1(h.rule->id)},
                               {QStringLiteral("severity"), h.rule->severity},
                               {QStringLiteral("title"), title},
                               {QStringLiteral("advice"), tr(h.rule->advice)},
                               {QStringLiteral("action"), QString::fromLatin1(h.rule->action)},
                               {QStringLiteral("actionLabel"), tr(h.rule->actionLabel)},
                               {QStringLiteral("count"), h.count},
                               {QStringLiteral("sample"), h.sample}});
    }
    return out;
}

// « df -P / » : pourcentage d'occupation de la racine (-1 si inconnu).
inline int parseDfUsage(const QString &out)
{
    static const QRegularExpression re(QStringLiteral("\\s(\\d+)%\\s+/\\s*$"), QRegularExpression::MultilineOption);
    const auto m = re.match(out);
    return m.hasMatch() ? m.captured(1).toInt() : -1;
}
