# Revue lot 3 `retours-tour-icones` — round 2

Périmètre relu : les deux MAJOR du rapport R1, le patch incrémental de
`lot3-fix-r1.md` et leurs seuls chemins d'exécution. Revue statique en lecture
seule au commit `3909153` ; aucun test, build ou changement du code applicatif
n'a été exécuté.

## BLOCKER

Aucun.

## MAJOR

Aucun.

## MINOR

Aucun.

## Contrôles ciblés

- La MAJOR sur la hauteur est fermée : `SizedBox(height: _buttonsHeight)`
  contraint la rangée à 114 px dans
  `lib/widgets/common/turn_play_widgets.dart:136`. Le `Row` est étiré dans
  cette contrainte (`:138-183`) ; l'appel de l'écran du tour conserve donc les
  32 px au-dessus et les 72 px au-dessous, quelle que soit la taille du texte
  (`lib/screens/turn_screen.dart:457-481`). Le cas concret « Passe gratuite à
  200 % » est couvert par `test/widgets/turn_large_text_test.dart:22-30`.
- La MAJOR sur le contenu de Passer est fermée : sa colonne est enveloppée par
  `FittedBox(fit: BoxFit.scaleDown)` dans l'espace intérieur borné du bouton
  (`lib/widgets/common/turn_play_widgets.dart:148-157`). Ainsi « Passer /
  (gratuit) », les pénalités et l'état grisé ne peuvent plus étirer la rangée ;
  le geste conserve la surface complète du conteneur de 114 px. À taille normale
  `scaleDown` n'agrandit pas le rendu.
- La MAJOR sur les émojis est fermée : tout glyphe de `ModifierIcon` reçoit
  `TextScaler.noScaling` avant d'être centré dans le `SizedBox.square(size)`
  (`lib/widgets/fiesta/modifier_badge.dart:84-123`). À une police système à
  200 %, `mime_no_arms` et `mime_eyes_closed` gardent donc la métrique dictée
  par leur taille d'icône et le `slash.png` de même taille continue de les
  recouvrir. Le test de régression contrôle la taille intrinsèque du
  `RenderParagraph` (`test/widgets/turn_large_text_test.dart:33-38`).

## Verdict

**READY**
