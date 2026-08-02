# Catégories de mots & sélection

Détail des listes de mots et du mécanisme qui choisit lesquels sortent en partie.
Le `CLAUDE.md` racine ne garde que le pointeur vers ce fichier.

## Vue d'ensemble

**13 catégories**, **5 822 mots** en français.

| Catégorie | ID | Icône | Mots |
|-----------|-----|-------|------|
| Dictionnaire | `dictionnaire` | 📖 | 750 |
| Nature et Gastronomie | `nature` | 🌿 | 711 |
| Métiers & Sports | `metiers_sports` | 💼 | 673 |
| Noms communs | `noms_communs` | 🔧 | 624 |
| Géographie | `geographie` | 🌍 | 593 |
| Marques | `marques` | 🏷️ | 460 |
| 7ème Art | `7eme_art` | 🎬 | 413 |
| Musique | `musique` | 🎵 | 375 |
| Science et Médecine | `science_medecine` | 🔬 | 349 |
| Univers Arcade | `univers_arcade` | 🎮 | 341 |
| Célébrités | `celebrites` | ⭐ | 323 |
| Expressions | `expressions` | 🇫🇷 | 115 |
| Métro Parisien | `metro_parisien` | 🚇 | 95 |
| **TOTAL** | | | **5 822** |

> 🔴 Ce tableau a été **mesuré**, pas recopié. La version précédente de cette page
> annonçait des comptes inventés (`nature` 883 au lieu de 711, `metiers_sports` 284
> au lieu de 673) et **deux IDs qui n'existent pas** — `arcade` et `metro`, alors que
> le code attend `univers_arcade` et `metro_parisien`. Un `loadCategory('arcade')`
> part droit dans le `catch` silencieux de `utils.dart`.
>
> Re-mesurer avant de citer un chiffre en spec :
> ```bash
> python3 -c "import json,os; c=json.load(open('assets/translations/categories.json'))['categories']; print(sum(len(json.load(open('assets/translations/words/fr/%s.json'%x['id']))['words']) for x in c))"
> ```

## Contenu par catégorie (catégories enrichies, janvier 2026)

### Science et Médecine (`science_medecine`, ex-`medecine`) — 🔬 349 mots
- **Médecine** : anatomie, maladies, symptômes, traitements, spécialités médicales, équipements,
  traumatismes, pathologies, santé mentale, cancers, premiers secours, professions paramédicales.
- **Science** : éléments chimiques, domaines scientifiques, théories et lois, espace et astronomie,
  inventions et découvertes, scientifiques célèbres, phénomènes physiques, unités de mesure,
  biologie cellulaire, chimie, géologie.

### Nature et Gastronomie (`nature`) — 🌿 711 mots
- **Nature** : animaux (sauvages, domestiques, marins, oiseaux, insectes, reptiles, rongeurs,
  cervidés, bovidés), plantes et fleurs, arbres, arbustes, plantes d'intérieur, plantes grimpantes,
  fruits et légumes, champignons, phénomènes naturels, météo, minéraux, géologie, astres,
  écosystèmes, éléments naturels.
- **Gastronomie** : plats italiens, asiatiques, français traditionnels, plats du monde, techniques
  culinaires, ustensiles spécialisés, sauces célèbres, condiments, pâtisseries et desserts
  internationaux, confiseries, fromages, vins et cépages, pains du monde, termes culinaires,
  boissons chaudes/froides/alcoolisées, cocktails, ingrédients, produits laitiers, viandes,
  charcuterie.

### Noms communs (`noms_communs`) — 🔧 624 mots
Objets électroniques, objets quotidiens, mobilier, ustensiles de cuisine, outils, moyens de
transport, véhicules spécifiques, vêtements, sous-vêtements, chaussures, accessoires mode,
instruments de musique, maison et habitat, jouets, électroménager (gros et petit), équipements
sportifs, objets plage/vacances, matériel camping, matériel médical, matériel informatique,
textiles maison, contenants et emballages, objets de décoration, bijoux, objets divers.

### Dictionnaire (`dictionnaire`) — 📖 750 mots
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
- **Univers Arcade** (`univers_arcade`, 🎮) — jeux vidéo, Pokémon, Clash Royale, jeux de société.
- **Expressions** (🇫🇷) — expressions françaises.
- **Musique** (🎵) — chansons, genres, artistes.
- **Marques** (🏷️) — vêtements, tech, alimentation.
- **Métro Parisien** (`metro_parisien`, 🚇) — stations de métro.

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

**Exemple.** Catégorie « Expressions » (115 mots), historique = 110 vus / 5 jamais vus, demande de
40 mots → 5 jamais vus + 35 au `seenCount` le plus bas ; après la partie, les 40 passent à +1.

⚠️ **Couplage à connaître** : la priorisation dépend d'un compteur écrit par le chemin analytics.
Toute story qui touche `AnalyticsService.endGame()` touche donc *aussi* la sélection des mots —
c'est un des points de collision listés dans `guessitall-epic-intake`.
