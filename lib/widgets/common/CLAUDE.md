# widgets/common/

Composants UI reutilisables du design system.

## Widgets

| Widget | Classe | Role |
|--------|--------|------|
| `app_button.dart` | `AppButton` | Bouton avec variantes (primary/secondary/danger/ghost), tailles (S/M/L), icone, fullWidth, animation press |
| `app_input.dart` | `AppInput` | Champ texte avec erreur, bouton clear, maxLength, capitalisation. Wrappe dans Material pour support TextField |
| `app_counter.dart` | `AppCounter` | Compteur +/- avec affichage numerique (police Bangers) |
| `app_toggle.dart` | `AppToggle` | Toggle 2 options (ex: Custom/Random) |
| `app_slider.dart` | `AppSlider` | Slider avec label et unite (pour turnDuration, passPenalty, totalWords) |
| `app_modal.dart` | `AppModal` | Dialog a contenu **libre** (widget quelconque), titre + bouton fermer, scrollable. `AppModal.show()` |
| `app_confirm_dialog.dart` | `AppConfirmDialog` | Confirmation « Annuler / Confirmer ». `AppConfirmDialog.show()` rend un `bool` — et **`false` si on ferme en tapant a cote** : l'absence de choix n'est jamais un accord |
| `game_dialogs.dart` | (fonctions) | Confirmations **propres au jeu**, dont le texte ET l'action sont une decision produit : `showBackToVerificationDialog()`, partagee par les ecrans jeu / transition / resultats |
| `app_back_button.dart` | `AppBackButton` | Bouton retour circulaire rose (position absolue top-left) |
| `home_button.dart` | `HomeButton` | Bouton accueil circulaire cyan avec confirmation pendant partie active |
| `back_button.dart` | `GameBackButton` | Bouton retour custom avec etat disabled |

## Choisir entre `AppModal` et `AppConfirmDialog`

Question binaire (« veux-tu … ? ») → **`AppConfirmDialog`**. Contenu arbitraire a
afficher (liste, formulaire, stats) → **`AppModal`**. Ne recopie plus un
`AlertDialog` a la main : les six qui existaient etaient identiques a la bordure
pres, et toute retouche visuelle demandait six modifications coherentes.
