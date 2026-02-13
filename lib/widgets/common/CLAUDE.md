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
| `app_modal.dart` | `AppModal` | Dialog avec titre, bouton fermer, contenu scrollable. Methode statique `AppModal.show()` |
| `app_back_button.dart` | `AppBackButton` | Bouton retour circulaire rose (position absolue top-left) |
| `home_button.dart` | `HomeButton` | Bouton accueil circulaire cyan avec confirmation pendant partie active |
| `back_button.dart` | `GameBackButton` | Bouton retour custom avec etat disabled |
