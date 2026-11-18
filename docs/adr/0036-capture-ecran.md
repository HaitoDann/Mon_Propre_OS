# ADR 0036 — Capture d'écran VinX

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

Spectacle (KDE) est complet mais chargé (modes, enregistrement vidéo, réglages). Besoin courant :
« montrer quelque chose » dans un mail ou un document, avec une flèche ou un passage masqué.

## Décision

`vinx-screenshot` (`shell/apps/screenshot`), Spectacle masqué (`Hidden=true`, raccourcis neutralisés) :

- **Méta+Maj+S** : les écrans sont figés (une fenêtre plein écran par écran) ; barre d'outils
  *Zone · Fenêtre · Écran · Retardateur (3, 5, 10 s) · Capturer*. Zone : tracer, déplacer, Entrée ou double-clic.
  Fenêtre : KWin propose de cliquer sur la fenêtre voulue. Écran : clic sur l'écran.
- **Impr. écran** (`--full`) : tout l'écran, copié et enregistré, bulle « Capture enregistrée » avec
  *Annoter* et *Ouvrir le dossier*.
- **Toute capture est copiée aussitôt** (choix de l'utilisateur), puis la fenêtre d'annotation s'ouvre :
  flèche, cadre, surligner, flouter (pixellisation, irréversible), texte ; 5 couleurs ; Annuler (Ctrl+Z),
  Copier (Ctrl+C), Enregistrer dans Images › Captures (Ctrl+S), nom daté sans « : ».
- Les annotations sont dessinées en pleine résolution en C++ (`captureutil.h`, testé), pas d'après l'aperçu.
- Images des écrans : interface D-Bus `org.kde.KWin.ScreenShot2` de KWin (accès réservé aux programmes dont
  le `.desktop` déclare `X-KDE-DBUS-Restricted-Interfaces`), image brute lue dans un tube.
- La copie est confiée au shell (`org.vinx.Shell.copyImageFile`) : l'image reste dans le presse-papiers après
  la fermeture de l'outil (ADR 0037).

## Conséquences

- Pas d'enregistrement vidéo (hors du besoin courant).
- `--image` / `VINX_SCREENSHOT_IMAGE` remplacent l'écran pour les tests et la documentation.
- Non vérifié ici (pas de KWin) : l'appel ScreenShot2, le choix de fenêtre, les raccourcis, le multi-écran
  avec mise à l'échelle.
