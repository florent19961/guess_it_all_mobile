# Revue lot 3 `retours-tour-icones` — round 1

Périmètre relu : le patch `lot3-patch-r1.diff` et ses chemins d'exécution dans
ce worktree, par rapport à `origin/feat/retours-regles`, sans lancer de
`git diff`. Revue statique en lecture seule ; aucun test ni build n'a été
lancé.

## BLOCKER

Aucun.

## MAJOR

### MAJOR — Les émojis des icônes débordent et le slash ne les couvre plus avec une grande police système

- Emplacement : `lib/widgets/fiesta/modifier_badge.dart:85`
- Preuve : `_glyph()` fixe le côté de son parent à `size` (`SizedBox.square`,
  lignes 110-121), mais le `Text` ne fixe pas `textScaler`. `inherit: false`
  empêche l'héritage du `DefaultTextStyle` ; il ne désactive pas le
  `MediaQuery.textScaler` employé par `Text`. Son `fontSize` est donc agrandi
  par la taille de texte système, alors que la boîte et `slash.png` restent à
  `size`.
- Scénario de défaillance concret : sur iOS ou Android avec la taille de texte
  à 200 %, `mime_no_arms` ou `mime_eyes_closed` dans une pastille de 16 px (ou
  un cercle de réserve) rend un émoji d'environ 23 px dans une boîte de 16 px.
  Il peint hors de la boîte et la diagonale de 16 px ne barre plus toute
  l'icône. Le centrage commun exigé par D6 n'est alors plus vrai ; le débordement
  peut aussi recouvrir le libellé voisin.
- Correction proposée : rendre le glyphe d'icône indépendant de la taille de
  texte, par exemple `textScaler: TextScaler.noScaling` sur ce `Text`, puis
  vérifier les quatre tailles utilisées (16, 20, 26 et 64 px) sur Android et
  iOS avec une police système agrandie.

### MAJOR — `IntrinsicHeight` ne garantit pas les boutons à 114 px et déplace la zone d'action à grande police

- Emplacement : `lib/widgets/common/turn_play_widgets.dart:133`
- Preuve : la hauteur de la ligne est celle du plus grand enfant intrinsèque.
  Le bouton Trouvé la porte normalement à `48 + 2 × 33 = 114` px (lignes
  161-173), mais la colonne Passer n'a aucune borne verticale (lignes 99-128).
  Lorsque le libellé et, surtout, `passDetail` suivent un `textScaler` élevé,
  leur hauteur intrinsèque plus les 16 px de padding dépasse 114 ;
  `IntrinsicHeight` étire alors les deux boutons.
- Scénario de défaillance concret : avec une taille de texte système élevée,
  pendant une passe gratuite ou avec `-5s`, la colonne « Passer / (gratuit) »
  dépasse la hauteur de l'icône Valider. La rangée devient plus haute que 114
  px et décale le contenu au-dessus et la marge de 72 px vers le bouton de fin
  de tour, contrairement à D7 (« même hauteur », sans déplacement entre les
  états).
- Correction proposée : imposer la hauteur contractuelle de la rangée (114 px)
  plutôt que de la déduire avec `IntrinsicHeight`, puis choisir explicitement
  le comportement accessible du contenu trop grand (mise à l'échelle, variante
  de libellé ou adaptation de la mise en page) et couvrir ce cas par un widget
  test avec un `TextScaler` élevé.

## MINOR

Aucun.

## Contrôles sans finding

- `PassState` respecte l'ordre arrêté : blocage, dernier mot, puis temps ; le
  passage en pause fournit bien une raison `null`, donc ni bulle ni action.
  Le `reset()` ne relance pas la bulle lors des rebuilds du chrono.
- La bulle est hors flux, ignore les pointeurs et reste contenue horizontalement
  par le `Positioned(left: 0, right: 0)`. La nouvelle assertion de widget
  détecte bien un gel du chrono (`TurnClock` passerait de deadline à état gelé)
  et l'absence de déplacement. Elle ne prouve pas à elle seule l'absence d'un
  appel UI à `passWord`, mais la garde est directement exercée par
  `test/providers/fiesta_turn_effects_test.dart`.
- `cancelSent` conserve sa garde `sentThisTurn.contains(sent)` ; le toucher
  d'une puce périmée ou après le démarrage du tour est donc sans effet.
- La pastille `block_guesser` retombe sur le nom du catalogue lorsqu'un joueur
  ancien est introuvable, et les ids sans `turnLabel` restent masqués. Les 14
  PNG attendus sont présents, en RGBA 192 × 192, et le répertoire est déclaré
  dans `pubspec.yaml`.
- Aucune branche spécifique Android/iOS, ni usage de `Platform.*`, n'est
  introduit. Le centrage réel des émojis reste néanmoins à confirmer sur les
  deux appareils, comme prévu par la recette device.

## Verdict

**NOT READY** — corriger les deux écarts de mise en page à grande taille de
texte avant validation.
