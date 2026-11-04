# Corrections r2 — feat/theme-couleurs

| # | Finding | Décision | Preuve |
|---|---|---|---|
| 1 | MAJOR : Switch désactivé indiscernable | **Corrigé** | `lib/theme/app_theme.dart:75-91` : pouce et piste gardent leur couleur (sélectionné ou non), puis passent à `alpha: 0.38` si `WidgetState.disabled`, comme les valeurs par défaut de Material. |

Limite (résidu assumé, hors périmètre) : Flutter fait primer le `activeTrackColor` passé au widget
sur `switchTheme.trackColor` (`material/switch.dart:975`). Les trois Switch de l'app le passent
(`fiesta_auto_screen.dart:117`, `fiesta_setup_widgets.dart:258`,
`fiesta_ensemble_editor_screen.dart:443`), donc une piste *sélectionnée et désactivée* y resterait
turquoise pleine. Aucun d'eux n'est rendu désactivé aujourd'hui : `onChanged` est toujours fourni,
et `fiesta_setup_widgets.dart:254` affiche un texte « Oui/Non » au lieu du Switch quand
`onChanged` est null. Le pouce, lui, suit bien le thème. Ces `activeTrackColor` deviennent
redondants avec le thème ; les retirer est hors du périmètre de cette lane.
