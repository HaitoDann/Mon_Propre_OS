# Tests de VinX OS

| Test | Quand | Ce qu'il vérifie |
|---|---|---|
| Tests du shell (`shell/tests`) | À chaque poussée touchant `shell/` (workflow vinx-shell) | Composants QML, analyseurs (Wi-Fi, imprimantes, mises à jour, dépannage…), Fichiers, comptes, relance du shell |
| Paquet Debian | Idem | Construction, installation et captures de la galerie sous Debian 13 |
| **Démarrage de l'ISO** | Avec l'ISO (`[iso]`, étiquette `v*` ou lancement manuel) | L'ISO démarre dans QEMU jusqu'au bureau VinX |

## Test de démarrage de l'ISO

`distro/tests/boot-test.sh ISO DOSSIER [DÉLAI]` démarre l'ISO en mode live dans QEMU (KVM si
disponible), avec la console sur le port série, et attend :

1. le système a démarré (SDDM ou la session apparaissent dans le journal) ;
2. `vinx-shell: prêt` : la session VinX est ouverte et le bureau affiché (critère de réussite).

Il enregistre une capture d'écran toutes les 15 s, la capture du bureau, le journal de la console
(`console.log`) et un résumé (`resume.txt`) avec les erreurs QML relevées. Sur GitHub, ces fichiers
sont publiés dans l'artefact **vinx-os-test-demarrage** (14 jours).

En local (paquets `qemu-system-x86 socat xorriso imagemagick`) :

```bash
./distro/tests/boot-test.sh distro/out/vinx-os-*.iso /tmp/test-demarrage
```
