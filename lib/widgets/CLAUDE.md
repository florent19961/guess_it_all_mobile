# widgets/

Widgets reutilisables organises en deux sous-repertoires.

## Sous-repertoires

| Repertoire | Role |
|------------|------|
| `common/` | Composants UI reutilisables (boutons, inputs, modals, sliders, toggles) |
| `effects/` | Effets visuels et animations de fond |
| `fiesta/` | Cartes Fiesta (`FiestaCard`, `FiestaLine`, `FiestaHint`) ; kit visuel du tour Fiesta (`fiesta_turn_widgets.dart`) ; annonces de partie (2-5) : `ModifierBadge(s)`, `ModifierCard`, `RoundDrawLine` (tirage de la manche en une ligne, transition), `MalusReveal` (plein ecran avant le tour, reutilisable 2-8 / 2-10), `FiestaTurnZone` (`turn_cartridges.dart`, Fiesta v2 lane 2 : avant-tour « Ce tour / Réserve », cercles ~50 px qui rapetissent jusqu'à 36 px (la réserve seule jusqu'à 32 px) pour tenir sans défiler (« Ce tour » sur plusieurs rangées, colonne Bonus ajustée ; jamais de défilement), appui long = explication, feuille « Contre quelle équipe ? », puces « Envoyé » « [icône] → X », un appui propose d'annuler ; lit et appelle le `GameProvider`), `CatchUpLine` (« Rattrapage » en une ligne, transition) et `BlockedGuesser` (selecteur « Les adversaires choisissent » + annonce « X ne repond pas », 2-8) ; kit 2-10 (`offer_widgets.dart`, sans Provider) : `PickThreeCard`, `PassPhonePanel`, `OfferChoiceBody` (rangées de cartes, une par rangée ; sélection rangée → index tenue par l'appelant, cartes sans effet grisées), `AppBoostLine` (une ligne, transition) ; couleurs : `modifierColor` = malus `AppColors.malus` (#F87171), bonus `AppColors.success` ; `FiestaInfoLine` (`fiesta_setup_widgets.dart`) = gabarit « Libellé : … » de ces lignes |
| `help/` | Aides de prise en main : `HelpButton` (« ? »), `CoachMarks` (voile + bulle, étapes `CoachStep` ciblées par `GlobalKey`), textes par écran (`help_content.dart`), `TutorialPager`, `FirstGamePrompt` (tuto des règles d'office au 1er « Jouer »), `FirstGameHelp` (aides auto de la 1re partie). Branchement écran par écran → `help/WIRING.md` |

## Kit visuel du tour Fiesta (`fiesta/fiesta_turn_widgets.dart`)

Purement presentationnel : aucune logique de jeu, tout passe par des callbacks (`null` = bouton
desactive). Pas encore branche : les stories du tour le cablent dans `turn_screen.dart`.

| Widget | Constructeur | Branche par |
|--------|--------------|-------------|
| `FiestaWordCard` | `({required String word, bool reversed = false, VoidCallback? onGuessed, VoidCallback? onPass, String passLabel = 'Passer', String? label, double fontSize = 56})` | 2-11 |
| `TwoWordsLayout` | `({required String firstWord, String? secondWord, bool reversed = false, onGuessedFirst, onPassFirst, onGuessedSecond, onPassSecond, String passLabel = 'Passer'})` | 2-11 |

- `FiestaWordCard` anime chaque nouveau mot et **ignore les taps pendant `kWordCardLock`
  (300 ms)** (2-11 critere 9). Etat de widget seulement : rien de persiste, chrono intact.
- `TwoWordsLayout` : une seule carte, sans place vide, quand `secondWord == null`. Cartes cles par
  leur mot : la carte B qui passe seule en tete garde son etat (pas de re-verrou).
- 2-8 ne branche **aucun** de ces widgets : le tour a un mot garde son rendu, 2-8 n'utilise que
  `reversedWordDisplay`.
- Inversion de l'affichage : `utils/reversed_word.dart` (`reversedWordDisplay`).
