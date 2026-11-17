# ADR 0019 — Wi-Fi, écrans, imprimantes, utilisateurs et pilotes natifs

- **Statut** : accepté
- **Date** : 2026-11-17

## Décision

Les pages qui renvoyaient vers les modules de réglages KDE deviennent natives (style VinX).
Chaque page garde un lien « Avancé… » vers KDE pour les cas rares.

| Fonction | Interface | Moteur |
|---|---|---|
| Wi-Fi | Centre de contrôle et Paramètres → Réseau : réseaux proches, signal, cadenas, mot de passe sur place, réseau masqué, oublier, déconnecter | `nmcli` (NetworkManager) |
| Écrans | Paramètres → Écrans : disposition par glisser-déposer avec accroche aux bords, écran principal, duplication, activation, définition, échelle ; au branchement, bulle « Étendre / Dupliquer / Seulement lui » | `kscreen-doctor` (KDE) |
| Imprimantes | Paramètres → Imprimantes : liste, imprimantes réseau sans pilote détectées et ajoutées en un clic, défaut, page de test, annulation | CUPS (`lpstat`, `driverless`, `lpadmin -m everywhere`) |
| Utilisateurs | Paramètres → Utilisateurs : création (standard ou administrateur), mot de passe, type de compte, suppression | AccountsService (D-Bus), mots de passe hachés en yescrypt |
| Pilotes | Paramètres → Pilotes : composants détectés, pilotes et micrologiciels recommandés, installation ; pilote NVIDIA proposé si une carte NVIDIA est présente | `lspci`, `isenkram-lookup`, APT |

Les actions administrateur passent par `/usr/lib/vinx/vinx-admin` (pkexec, action polkit
`org.vinx.admin`), qui valide strictement chaque argument (nom de file d'impression, URI,
nom de paquet). Le dépôt « non-free » n'est activé que si l'utilisateur installe le pilote NVIDIA.

## Conséquences

- Paquets : network-manager, accountsservice, cups-filters, isenkram-cli, pciutils.
- Les commandes `nmcli` reçoivent le mot de passe Wi-Fi en argument (visible brièvement dans la
  liste des processus de l'utilisateur) ; à remplacer par l'API D-Bus de NetworkManager si besoin.
- La duplication d'écran utilise `kscreen-doctor … mirror` si disponible, sinon superpose les écrans.
