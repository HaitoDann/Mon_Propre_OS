# ADR 0028 — VinX sans interfaces KDE, lot 2 : extinction, bulles, mot de passe administrateur

- **Statut** : accepté
- **Date** : 2026-11-18

## Décision

- **Bulles volume, luminosité, micro, disposition du clavier** : plasmashell publiait le service
  D-Bus `org.kde.osdService`, appelé par plasma-pa, powerdevil et kded. `vinx-shell` le publie
  désormais (`DesktopPrompts`, `kdeprompts.h`) et affiche une pilule VinX en bas au centre
  (`Osd.qml`, surface layer-shell sans saisie, au-dessus du dock), effacée après 1,5 s.
- **Extinction** : le service `org.kde.LogoutPrompt` (bouton d'alimentation, applications KDE) est
  repris par `vinx-shell` ; la boîte VinX (`PowerDialog.qml`) propose veille, redémarrer, éteindre,
  fermer la session, et exécute l'action proposée au bout de 30 s. Le menu système et le centre de
  contrôle l'utilisent aussi.
- **Mot de passe administrateur** : `vinx-polkit-agent` (polkit-qt6, `PolkitQt1::Agent::Listener`),
  fenêtre VinX, trois essais. Démarré par l'autostart dans la session VinX ; l'agent de KDE y est
  désactivé (complément `plasma-polkit-agent.service.d`), **seulement si** l'agent VinX est construit.
  Construction facultative tant que le nom du paquet Debian (`libpolkit-qt6-1-dev`) n'est pas confirmé.

## Conséquences

- Tout est vérifiable seulement en session réelle (D-Bus de KDE, polkit, layer-shell).
- Les boutons « Avancé… » des Paramètres (modules KDE) restent à traiter.
