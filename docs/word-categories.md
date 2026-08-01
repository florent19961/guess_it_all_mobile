# Catégories de mots & sélection

Détail des listes de mots et du mécanisme qui choisit lesquels sortent en partie.
Le `CLAUDE.md` racine ne garde que le pointeur vers ce fichier.

## Vue d'ensemble

**13 catégories**, environ **5 711 mots**.

| Catégorie | ID | Icône | Mots |
|-----------|-----|-------|------|
| Nature et Gastronomie | `nature` | 🌿 | 883 |
| Dictionnaire | `dictionnaire` | 📖 | 870 |
| Noms communs | `noms_communs` | 🔧 | 728 |
| 7ème Art | `7eme_art` | 🎬 | 491 |
| Science et Médecine | `science_medecine` | 🔬 | 484 |
| Marques | `marques` | 🏷️ | 465 |
| Géographie | `geographie` | 🌍 | 384 |
| Célébrités | `celebrites` | ⭐ | 361 |
| Univers Arcade | `arcade` | 🎮 | 324 |
| Métiers & Sports | `metiers_sports` | 💼 | 284 |
| Musique | `musique` | 🎵 | 224 |
| Expressions | `expressions` | 🇫🇷 | 118 |
| Métro Parisien | `metro` | 🚇 | 105 |
| **TOTAL** | | | **5 711** |

> ⚠️ Ces comptes datent de l'enrichissement de janvier 2026. Les **vérifier dans les JSON**
> (`assets/translations/words/fr/`) avant de les citer dans une spec — un chiffre de doc vieillit.

## Contenu par catégorie (catégories enrichies, janvier 2026)

### Science et Médecine (`science_medecine`, ex-`medecine`) — 🔬 484 mots
- **Médecine** : anatomie, maladies, symptômes, traitements, spécialités médicales, équipements,
  traumatismes, pathologies, santé mentale, cancers, premiers secours, professions paramédicales.
- **Science** : éléments chimiques, domaines scientifiques, théories et lois, espace et astronomie,
  inventions et découvertes, scientifiques célèbres, phénomènes physiques, unités de mesure,
  biologie cellulaire, chimie, géologie.

### Nature et Gastronomie (`nature`) — 🌿 883 mots
- **Nature** : animaux (sauvages, domestiques, marins, oiseaux, insectes, reptiles, rongeurs,
  cervidés, bovidés), plantes et fleurs, arbres, arbustes, plantes d'intérieur, plantes grimpantes,
  fruits et légumes, champignons, phénomènes naturels, météo, minéraux, géologie, astres,
  écosystèmes, éléments naturels.
- **Gastronomie** : plats italiens, asiatiques, français traditionnels, plats du monde, techniques
  culinaires, ustensiles spécialisés, sauces célèbres, condiments, pâtisseries et desserts
  internationaux, confiseries, fromages, vins et cépages, pains du monde, termes culinaires,
  boissons chaudes/froides/alcoolisées, cocktails, ingrédients, produits laitiers, viandes,
  charcuterie.

### Noms communs (`noms_communs`) — 🔧 728 mots
Objets électroniques, objets quotidiens, mobilier, ustensiles de cuisine, outils, moyens de
transport, véhicules spécifiques, vêtements, sous-vêtements, chaussures, accessoires mode,
instruments de musique, maison et habitat, jouets, électroménager (gros et petit), équipements
sportifs, objets plage/vacances, matériel camping, matériel médical, matériel informatique,
textiles maison, contenants et emballages, objets de décoration, bijoux, objets divers.

### Dictionnaire (`dictionnaire`) — 📖 870 mots
Émotions positives et négatives, états physiques, états mentaux, adjectifs descriptifs / de
personnalité / de taille-forme, verbes du quotidien / créatifs / de communication / domestiques /
de mouvement, actions physiques et mentales, couleurs, formes géométriques, nombres et quantités,
temporalité, expressions temporelles, expressions de lieu, météo, relations et liens, textures et
sensations, goûts et saveurs, odeurs, sons et bruits, concepts philosophiques, valeurs morales,
noms abstraits, contraires et opposés, matériaux.

### Autres catégories
- **7ème Art** (🎬) — films, séries, anime, personnages.
- **Géographie** (🌍) — pays, villes, monuments, fleuves.
- **Métiers & Sports** (💼) — professions et sports.
- **Célébrités** (⭐) — sportifs, acteurs, chanteurs, influenceurs.
- **Univers Arcade** (🎮) — jeux vidéo, Pokémon, Clash Royale, jeux de société.
- **Expressions** (🇫🇷) — expressions françaises.
- **Musique** (🎵) — chansons, genres, artistes.
- **Marques** (🏷️) — vêtements, tech, alimentation.
- **Métro Parisien** (🚇) — stations de métro.

## Historique des mots — priorisation de ce qui sort

Le tirage **priorise les mots que l'utilisateur n'a jamais vus**.

1. **Mots jamais vus** (`seenCount == 0`) : servis en premier.
2. **Mots les moins vus** : s'il n'y en a plus à 0, on prend les `seenCount == 1`, puis 2, etc.
3. **Randomisation** : au sein d'un même niveau de priorité, les mots sont mélangés.

**Service.** `WordHistoryService` (singleton) tient la map `mot (lowercase) → seenCount`.
Incrémentation à la fin de chaque partie, via `AnalyticsService.endGame()`.

| Clé SharedPreferences | Contenu |
|---|---|
| `guessItAll_word_history` | `Map<String, int>` sérialisée en JSON : mot → nombre de fois joué |

**Exemple.** Catégorie « Expressions » (118 mots), historique = 113 vus / 5 jamais vus, demande de
40 mots → 5 jamais vus + 35 au `seenCount` le plus bas ; après la partie, les 40 passent à +1.

⚠️ **Couplage à connaître** : la priorisation dépend d'un compteur écrit par le chemin analytics.
Toute story qui touche `AnalyticsService.endGame()` touche donc *aussi* la sélection des mots —
c'est un des points de collision listés dans `guessitall-epic-intake`.
