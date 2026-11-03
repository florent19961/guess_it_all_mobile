# widgets/

Widgets reutilisables organises en deux sous-repertoires.

## Sous-repertoires

| Repertoire | Role |
|------------|------|
| `common/` | Composants UI reutilisables (boutons, inputs, modals, sliders, toggles) |
| `effects/` | Effets visuels et animations de fond |
| `fiesta/` | Squelette et cartes des ecrans de choix du mode Fiesta (retour systeme Android gere) ; kit visuel du tour Fiesta (`fiesta_turn_widgets.dart`) |

## Kit visuel du tour Fiesta (`fiesta/fiesta_turn_widgets.dart`)

Purement presentationnel : aucune logique de jeu, tout passe par des callbacks (`null` = bouton
desactive). Pas encore branche : les stories du tour le cablent dans `turn_screen.dart`.

| Widget | Constructeur | Branche par |
|--------|--------------|-------------|
| `FiestaWordCard` | `({required String word, bool reversed = false, VoidCallback? onGuessed, VoidCallback? onPass, String passLabel = 'Passer', String? label, double fontSize = 56})` | 2-11 |
| `TwoWordsLayout` | `({required String firstWord, String? secondWord, bool reversed = false, onGuessedFirst, onPassFirst, onGuessedSecond, onPassSecond, String passLabel = 'Passer'})` | 2-11 |
| `MimeConstraintBanner` | `({required String modifierId})` ; ids acceptes = `MimeConstraintBanner.icons.keys` | 2-8 |

- `FiestaWordCard` anime chaque nouveau mot et **ignore les taps pendant `kWordCardLock`
  (300 ms)** (2-11 critere 9). Etat de widget seulement : rien de persiste, chrono intact.
- `TwoWordsLayout` : une seule carte, sans place vide, quand `secondWord == null`. Cartes cles par
  leur mot : la carte B qui passe seule en tete garde son etat (pas de re-verrou).
- 2-8 ne branche **aucun** de ces widgets : le tour a un mot garde son rendu, 2-8 n'utilise que
  `reversedWordDisplay`.
- Textes du bandeau = `name` / `description` du catalogue (`modifier_catalog.dart`).
- Inversion de l'affichage : `utils/reversed_word.dart` (`reversedWordDisplay`).
