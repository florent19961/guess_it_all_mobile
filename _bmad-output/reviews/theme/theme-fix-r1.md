# Corrections r1 — feat/theme-couleurs

Ratios calculés avec la formule WCAG 2.x (luminance relative sRGB).

| # | Finding | Décision | Preuve |
|---|---|---|---|
| 1 | MAJOR : pouce blanc sur turquoise (1,76:1) | **Corrigé** | `lib/theme/app_theme.dart:75-79` : pouce sélectionné `backgroundMain` sur `secondaryCyan` = **8,33:1** ; pouce non sélectionné blanc sur `gray700` = **10,31:1** (gray400 aurait donné 4,06:1). Piste turquoise / `gray700` et `trackOutlineColor` transparent inchangés (`:80-85`). |
| 2 | MINOR : texte d'action de la SnackBar bleu nuit sur `gray700` (1,42:1) | **Corrigé** | `lib/theme/app_theme.dart:99` : `actionTextColor: AppColors.secondaryCyan` → turquoise sur `gray700` = **5,87:1**. |

Doc `lib/theme/CLAUDE.md` mise à jour (couleurs du pouce). Aucun test ajouté (thème).
