# ADR 0041 — Écran de connexion : panneau latéral et thème de la session

- **Statut** : accepté
- **Date** : 2026-11-20

## Contexte

Le 20/11/2026, l'utilisateur a levé en partie le gel des fonctions (ADR 0039) pour retravailler
le design. Sur le portable de test, l'écran de connexion était celui de **KDE Breeze**, et non le
thème SDDM « vinx ». SDDM lit `/etc/sddm.conf.d/*` par ordre alphabétique, puis `/etc/sddm.conf`.
Un `Current=breeze` écrit par les réglages KDE (`kde_settings.conf`, paquet `kde-config-sddm`) ou
pendant l'installation passe donc après `10-vinx.conf`. Le thème VinX lui-même
(carte centrée, fond uni) était jugé peu esthétique.

## Décision

- **Dessin** : un panneau latéral minimaliste à **gauche** (environ 30 % de la largeur, entre 380 et 520 px).
  De haut en bas, il contient la marque, l'heure et la date, les comptes (une liste quand il y en a
  plusieurs), le champ de mot de passe en pilule, puis, en bas, la session (s'il y en a plusieurs) et
  veille / redémarrer / éteindre.
  À droite, le fond « VinX Logo » est dessiné en direct à la couleur d'accent, dans la même composition que sur le bureau.
- **Thème suivi** : le clair/sombre et l'accent de la session sont recopiés vers l'écran de connexion.
  vinx-shell appelle `pkexec /usr/lib/vinx/vinx-greeter-sync light|dark ACCENT` seulement quand la
  valeur change (préférence `appearance/greeter`). L'action polkit `org.vinx.greeter-sync` est accordée
  **sans mot de passe** à la session locale active. L'outil n'accepte que deux valeurs connues et n'écrit que
  `/usr/share/sddm/themes/vinx/theme.conf.user` (clés `dark` et `accent`), que SDDM lit après `theme.conf`.
  Test : `greeter-sync`.
- **Thème imposé** : à l'installation ou à la mise à jour de `vinx-shell`, et une seule fois (tant que
  `/etc/sddm.conf.d/zz-vinx-theme.conf` n'existe pas), le `postinst` retire les lignes `Current=`
  différentes de `vinx` de `/etc/sddm.conf` et de `kde_settings.conf`. Il écrit ensuite
  `zz-vinx-theme.conf`, lu en dernier.

## Conséquences

- Un choix ultérieur de thème SDDM dans les réglages KDE reste respecté (la correction ne s'applique qu'une fois).
- L'écran de connexion n'a pas encore été vu sur le matériel réel : il a seulement été vérifié par des captures
  avec de faux objets SDDM.
