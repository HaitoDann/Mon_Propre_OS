# ADR 0029 — Compatibilité Microsoft Office

- **Statut** : accepté
- **Date** : 2026-11-18

## Décision

- **Polices métriquement compatibles** fournies avec VinX : Carlito (Calibri), Caladea (Cambria),
  Liberation (Arial, Times New Roman, Courier New) — paquets `fonts-crosextra-carlito`,
  `fonts-crosextra-caladea`, `fonts-liberation` (ISO et `Recommends` de vinx-shell). Leurs règles
  fontconfig substituent automatiquement les polices Microsoft : la mise en page est conservée.
- **Formats Microsoft par défaut** : `vinx-msformats.xcd` (installé dans
  `/usr/lib/libreoffice/share/registry`) fait enregistrer Writer, Calc et Impress en .docx, .xlsx,
  .pptx, sans l'avertissement « Garder le format actuel ? ».
- **Paramètres → Bureautique** : choix Microsoft Office / OpenDocument, écrit dans le profil de
  l'utilisateur (`registrymodifications.xcu`, prioritaire ; analyse testée `officeparse.h`), état
  des polices et bouton d'installation si elles manquent.

## Conséquences

- Si LibreOffice est ouvert pendant le changement, il réécrit son profil en se fermant : la page
  demande de le fermer d'abord.
- Non vérifié sur une vraie installation de LibreOffice (pas de LibreOffice ici).
