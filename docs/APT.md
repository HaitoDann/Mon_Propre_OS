# Dépôt APT de VinX OS

Les paquets VinX (`vinx-shell`, qui contient le shell, les Paramètres et le Store) sont publiés
dans un dépôt APT signé, hébergé gratuitement sur GitHub Pages. Un système installé reçoit
ainsi les nouvelles versions par le Store (onglet Mises à jour), sans réinstaller.

## Mise en place (une seule fois)

1. Créer la clé de signature, sur ton poste :
   ```bash
   ./distro/scripts/create-apt-key.sh
   ```
2. Ajouter le contenu de `vinx-apt-signing-key.SECRET.asc` comme secret GitHub
   **APT_SIGNING_KEY** (Settings → Secrets and variables → Actions), puis le sauvegarder hors
   ligne et le supprimer du dossier.
3. Commiter la clé publique `distro/keys/vinx-archive-keyring.asc` et pousser.
4. Activer GitHub Pages : Settings → Pages → Source : **GitHub Actions**.
   (Pages exige un dépôt public, ou un abonnement GitHub payant pour un dépôt privé.)

## Publier une version

1. Augmenter la version dans `shell/debian/changelog` (sinon APT ne voit pas de mise à jour).
2. Créer et pousser une étiquette :
   ```bash
   git tag shell-v0.8.0 && git push origin shell-v0.8.0
   ```
   Le workflow « Dépôt APT » construit le paquet, signe le dépôt et le publie sur
   `https://haitodann.github.io/mon_propre_os/apt`. C'est le seul moment où il consomme des minutes.

## Côté système

Les ISO construites après l'étape 3 contiennent `/etc/apt/sources.list.d/vinx.sources` et la clé
`/usr/share/keyrings/vinx-archive-keyring.gpg`. Sur un système déjà installé sans ce dépôt :

```bash
curl -fsSL https://haitodann.github.io/mon_propre_os/apt/vinx-archive-keyring.asc | sudo gpg --dearmor -o /usr/share/keyrings/vinx-archive-keyring.gpg
printf 'Types: deb\nURIs: https://haitodann.github.io/mon_propre_os/apt\nSuites: trixie\nComponents: main\nSigned-By: /usr/share/keyrings/vinx-archive-keyring.gpg\n' | sudo tee /etc/apt/sources.list.d/vinx.sources
sudo apt update && sudo apt upgrade
```
