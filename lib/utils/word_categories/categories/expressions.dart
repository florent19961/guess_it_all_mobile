// ============================================================
// CATÉGORIE : Expressions
// ============================================================
//
// DESCRIPTION :
// Expressions idiomatiques françaises, proverbes et
// locutions populaires de la langue française.
//
// SECTIONS EXISTANTES :
// - Expressions avec animaux (avoir le cafard, poser un lapin)
// - Expressions avec couleurs (voir rouge, être vert de rage)
// - Expressions avec corps humain (avoir la main verte)
// - Expressions météo (il pleut des cordes)
// - Proverbes français (qui dort dîne, l'habit ne fait pas le moine)
// - Expressions familières courantes
//
// IDÉES D'ENRICHISSEMENT :
// - Expressions régionales françaises
// - Argot moderne et verlan
// - Expressions du monde professionnel
// - Dictons populaires
// - Expressions avec nourriture
// - Expressions sportives (être aux anges, jeter l'éponge)
// - Nouvelles expressions génération Z
//
// CRITÈRES DE DIFFICULTÉ :
// - 1 (Facile) : Très courant (avoir le cafard, tomber dans les pommes)
// - 2 (Moyen) : Connu mais moins utilisé (tirer les vers du nez)
// - 3 (Difficile) : Vieilli ou régional (avoir maille à partir)
//
// ============================================================

import '../models.dart';

const categoryExpressions = WordCategory(
  id: 'expressions',
  name: 'Expressions',
  icon: '🇫🇷',
  words: [

      // EXPRESSIONS AVEC ANIMAUX - Facile
      WordWithDifficulty('Avoir le cafard', difficulty: 1),
      WordWithDifficulty('Poser un lapin', difficulty: 1),
      WordWithDifficulty('Avoir la chair de poule', difficulty: 1),
      WordWithDifficulty('Donner sa langue au chat', difficulty: 1),
      WordWithDifficulty('Avoir une faim de loup', difficulty: 1),
      WordWithDifficulty('Pleurer comme un veau', difficulty: 1),
      WordWithDifficulty('Avoir un chat dans la gorge', difficulty: 1),
      WordWithDifficulty('Dormir comme un loir', difficulty: 1),
      WordWithDifficulty('Être têtu comme une mule', difficulty: 1),

      // EXPRESSIONS AVEC ANIMAUX - Moyen
      //WordWithDifficulty('Quand les poules auront des dents', difficulty: 2),
      WordWithDifficulty('Être le dindon de la farce', difficulty: 2),
      WordWithDifficulty('Avoir une mémoire d\'éléphant', difficulty: 2),
      WordWithDifficulty('Noyer le poisson', difficulty: 2),
      WordWithDifficulty('Faire l\'autruche', difficulty: 2),
      WordWithDifficulty('Être rusé comme un renard', difficulty: 2),
      WordWithDifficulty('Être muet comme une carpe', difficulty: 2),
      WordWithDifficulty('Monter sur ses grands chevaux', difficulty: 2),

      // EXPRESSIONS AVEC ANIMAUX - Difficile
      //WordWithDifficulty('Avoir d\'autres chats à fouetter', difficulty: 3),
      WordWithDifficulty('Être une poule mouillée', difficulty: 3),
      WordWithDifficulty('Chercher la petite bête', difficulty: 3),
      WordWithDifficulty('Avoir le bourdon', difficulty: 3),
      WordWithDifficulty('Être une tête de mule', difficulty: 3),
      WordWithDifficulty('Ménager la chèvre et le chou', difficulty: 3),
      WordWithDifficulty('Être le bouc émissaire', difficulty: 3),
      //WordWithDifficulty('Être serrés comme des sardines', difficulty: 3),

      // EXPRESSIONS AVEC LE CORPS - Facile
      WordWithDifficulty('Avoir le cœur sur la main', difficulty: 1),
      WordWithDifficulty('Coûter les yeux de la tête', difficulty: 1),
      WordWithDifficulty('Mettre les pieds dans le plat', difficulty: 1),
      WordWithDifficulty('Prendre ses jambes à son cou', difficulty: 1),
      //WordWithDifficulty('Avoir les yeux plus gros que le ventre', difficulty: 1),
      WordWithDifficulty('Tourner sept fois sa langue', difficulty: 1),
      WordWithDifficulty('Avoir le cœur brisé', difficulty: 1),

      // EXPRESSIONS AVEC LE CORPS - Moyen
      WordWithDifficulty('Avoir la tête dans les nuages', difficulty: 2),
      WordWithDifficulty('Se creuser la tête', difficulty: 2),
      WordWithDifficulty('Avoir un poil dans la main', difficulty: 2),
      WordWithDifficulty('Avoir le bras long', difficulty: 2),
      WordWithDifficulty('Garder la tête froide', difficulty: 2),
      WordWithDifficulty('Casser les pieds', difficulty: 2),
      WordWithDifficulty('Faire la sourde oreille', difficulty: 2),
      WordWithDifficulty('Lever le coude', difficulty: 2),
      WordWithDifficulty('Se mordre les doigts', difficulty: 2),
      WordWithDifficulty('En avoir plein le dos', difficulty: 2),
      WordWithDifficulty('Se tourner les pouces', difficulty: 2),
      //WordWithDifficulty('Avoir les dents qui rayent le parquet', difficulty: 2),

      // EXPRESSIONS AVEC LE CORPS - Difficile
      //WordWithDifficulty('Avoir l\'estomac dans les talons', difficulty: 3),
      WordWithDifficulty('Se mettre le doigt dans l\'œil', difficulty: 3),
      WordWithDifficulty('Avoir les dents longues', difficulty: 3),
      WordWithDifficulty('Avoir du nez', difficulty: 3),
      WordWithDifficulty('Manger sur le pouce', difficulty: 3),
      //WordWithDifficulty('Ne pas avoir la langue dans sa poche', difficulty: 3),
      WordWithDifficulty('Avoir l\'estomac accroché', difficulty: 3),
      WordWithDifficulty('Se faire des cheveux blancs', difficulty: 3),
      WordWithDifficulty('Avoir le compas dans l\'œil', difficulty: 3),
      WordWithDifficulty('Mettre les bouchées doubles', difficulty: 3),

      // EXPRESSIONS CULINAIRES - Facile
      WordWithDifficulty('Tomber dans les pommes', difficulty: 1),
      WordWithDifficulty('Avoir la patate', difficulty: 1),
      WordWithDifficulty('C\'est la cerise sur le gâteau', difficulty: 1),
      WordWithDifficulty('Casser du sucre sur le dos', difficulty: 1),
      WordWithDifficulty('Mettre son grain de sel', difficulty: 1),

      // EXPRESSIONS CULINAIRES - Moyen
      //WordWithDifficulty('Mettre du beurre dans les épinards', difficulty: 2),
      WordWithDifficulty('Raconter des salades', difficulty: 2),
      WordWithDifficulty('Être dans les choux', difficulty: 2),
      WordWithDifficulty('Ramener sa fraise', difficulty: 2),
      WordWithDifficulty('Couper la poire en deux', difficulty: 2),
      WordWithDifficulty('Mettre de l\'eau dans son vin', difficulty: 2),
      WordWithDifficulty('Avoir du pain sur la planche', difficulty: 2),
      WordWithDifficulty('Gagner son pain', difficulty: 2),
      WordWithDifficulty('Avoir la banane', difficulty: 2),

      // EXPRESSIONS CULINAIRES - Difficile
      WordWithDifficulty('Mi-figue mi-raisin', difficulty: 3),
      WordWithDifficulty('Ne pas être dans son assiette', difficulty: 3),
      WordWithDifficulty('En faire tout un fromage', difficulty: 3),
      WordWithDifficulty('Être haut comme trois pommes', difficulty: 3),
      WordWithDifficulty('Pédaler dans la semoule', difficulty: 3),
      WordWithDifficulty('Les carottes sont cuites', difficulty: 3),
      WordWithDifficulty('Appuyer sur le champignon', difficulty: 3),
      WordWithDifficulty('Occupe-toi de tes oignons', difficulty: 3),

      // EXPRESSIONS QUOTIDIENNES - Facile
      WordWithDifficulty('Jeter l\'éponge', difficulty: 1),
      WordWithDifficulty('Tourner autour du pot', difficulty: 1),
      WordWithDifficulty('Avoir le melon', difficulty: 1),
      WordWithDifficulty('Casser sa pipe', difficulty: 1),
      WordWithDifficulty('Battre de l\'aile', difficulty: 1),
      WordWithDifficulty('Avoir un coup de foudre', difficulty: 1),
      WordWithDifficulty('Être dans la lune', difficulty: 1),

      // EXPRESSIONS QUOTIDIENNES - Moyen
      WordWithDifficulty('Mettre les voiles', difficulty: 2),
      WordWithDifficulty('Tirer les vers du nez', difficulty: 2),
      WordWithDifficulty('Mettre la puce à l\'oreille', difficulty: 2),
      WordWithDifficulty('Brûler les étapes', difficulty: 2),
      WordWithDifficulty('Faire chou blanc', difficulty: 2),
      WordWithDifficulty('Être à côté de la plaque', difficulty: 2),
      WordWithDifficulty('Tomber à pic', difficulty: 2),
      //WordWithDifficulty('Rouler quelqu\'un dans la farine', difficulty: 2),
      WordWithDifficulty('Casser les oreilles', difficulty: 2),
      //WordWithDifficulty('Se faire rouler dans la farine', difficulty: 2),
      WordWithDifficulty('Avoir un coup de pompe', difficulty: 2),
      WordWithDifficulty('Mettre les points sur les i', difficulty: 2),

      // EXPRESSIONS QUOTIDIENNES - Difficile
      WordWithDifficulty('Être au bout du rouleau', difficulty: 3),
      WordWithDifficulty('Perdre la boule', difficulty: 3),
      WordWithDifficulty('Se prendre un râteau', difficulty: 3),
      WordWithDifficulty('Passer du coq à l\'âne', difficulty: 3),
      WordWithDifficulty('Faire d\'une pierre deux coups', difficulty: 3),
      WordWithDifficulty('Se mettre sur son trente-et-un', difficulty: 3),
      WordWithDifficulty('Être dans de beaux draps', difficulty: 3),
      WordWithDifficulty('Payer les pots cassés', difficulty: 3),
      WordWithDifficulty('Tirer son épingle du jeu', difficulty: 3),
      WordWithDifficulty('Avoir un verre dans le nez', difficulty: 3),
      //WordWithDifficulty('Prendre des vessies pour des lanternes', difficulty: 3),
      WordWithDifficulty('Être né de la dernière pluie', difficulty: 3),
      WordWithDifficulty('Se faire l\'avocat du diable', difficulty: 3),
      WordWithDifficulty('Découvrir le pot aux roses', difficulty: 3),

      // EXPRESSIONS MÉTÉO ET NATURE - Moyen
      //WordWithDifficulty('Faire la pluie et le beau temps', difficulty: 2),
      WordWithDifficulty('Après la pluie le beau temps', difficulty: 2),
      WordWithDifficulty('Être dans le vent', difficulty: 2),
      WordWithDifficulty('Souffler le chaud et le froid', difficulty: 2),

      // EXPRESSIONS MÉTÉO ET NATURE - Difficile
      WordWithDifficulty('Avoir un vent de panique', difficulty: 3),
      WordWithDifficulty('Jeter un froid', difficulty: 3),
      WordWithDifficulty('Briser la glace', difficulty: 3),
      WordWithDifficulty('Être dans le brouillard', difficulty: 3),
      WordWithDifficulty('Essuyer les plâtres', difficulty: 3),
    
  ],
);
