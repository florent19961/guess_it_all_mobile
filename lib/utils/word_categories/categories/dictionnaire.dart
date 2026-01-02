// ============================================================
// CATÉGORIE : Dictionnaire
// ============================================================
//
// DESCRIPTION :
// Vocabulaire abstrait et conceptuel : émotions, qualités,
// actions, concepts et mots du langage courant.
//
// SECTIONS EXISTANTES :
// - Émotions positives (joie, amour, bonheur)
// - Émotions négatives (colère, tristesse, peur)
// - États physiques (fatigué, affamé, reposé)
// - États mentaux (concentré, distrait, motivé)
// - Adjectifs descriptifs (grand, petit, rapide)
// - Adjectifs de personnalité (gentil, courageux, timide)
// - Adjectifs taille/forme (énorme, minuscule, allongé)
// - Verbes du quotidien (manger, dormir, marcher)
// - Verbes de communication (parler, expliquer, discuter)
// - Verbes domestiques (ranger, nettoyer, cuisiner)
// - Verbes de mouvement (courir, sauter, grimper)
// - Couleurs (rouge, bleu, vert)
// - Formes géométriques (cercle, carré, triangle)
// - Temporalité (hier, demain, maintenant)
// - Expressions temporelles (parfois, souvent, jamais)
// - Expressions de lieu (devant, derrière, dessus)
// - Textures et sensations (doux, rugueux, lisse)
// - Goûts et saveurs (sucré, salé, amer)
// - Sons et bruits (silence, bruit, musique)
// - Concepts philosophiques (liberté, justice, vérité)
// - Noms abstraits (chance, succès, échec)
// - Contraires et opposés (haut/bas, chaud/froid)
// - Matériaux (bois, métal, plastique)
//
// IDÉES D'ENRICHISSEMENT :
// - Verbes professionnels (négocier, présenter, analyser)
// - Émotions nuancées (mélancolie, euphorie, sérénité)
// - Concepts économiques (inflation, marché, profit)
// - Termes relationnels (amitié, rivalité, complicité)
// - Adverbes courants (rapidement, doucement, soudain)
// - Qualités morales (honnêteté, générosité, loyauté)
//
// CRITÈRES DE DIFFICULTÉ :
// - 1 (Facile) : Mots très courants (content, rouge, marcher)
// - 2 (Moyen) : Moins fréquent mais connu (mélancolique, turquoise)
// - 3 (Difficile) : Abstrait ou littéraire (éphémère, dichotomie)
//
// ============================================================

import '../models.dart';

const categoryDictionnaire = WordCategory(
  id: 'dictionnaire',
  name: 'Dictionnaire',
  icon: '📖',
  words: [

      // ÉMOTIONS POSITIVES - Facile
      WordWithDifficulty('Joie', difficulty: 1),
      WordWithDifficulty('Bonheur', difficulty: 1),
      WordWithDifficulty('Amour', difficulty: 1),
      WordWithDifficulty('Surprise', difficulty: 1),
      WordWithDifficulty('Plaisir', difficulty: 1),
      WordWithDifficulty('Calme', difficulty: 1),
      WordWithDifficulty('Confiance', difficulty: 1),
      WordWithDifficulty('Espoir', difficulty: 1),

      // ÉMOTIONS POSITIVES - Moyen
      WordWithDifficulty('Excitation', difficulty: 2),
      WordWithDifficulty('Enthousiasme', difficulty: 2),
      WordWithDifficulty('Tendresse', difficulty: 2),
      WordWithDifficulty('Fierté', difficulty: 2),
      WordWithDifficulty('Satisfaction', difficulty: 2),
      WordWithDifficulty('Soulagement', difficulty: 2),
      WordWithDifficulty('Admiration', difficulty: 2),
      WordWithDifficulty('Reconnaissance', difficulty: 2),
      WordWithDifficulty('Compassion', difficulty: 2),
      WordWithDifficulty('Sympathie', difficulty: 2),

      // ÉMOTIONS POSITIVES - Difficile
      WordWithDifficulty('Euphorie', difficulty: 3),
      WordWithDifficulty('Plénitude', difficulty: 3),
      WordWithDifficulty('Émerveillement', difficulty: 3),
      WordWithDifficulty('Gratitude', difficulty: 3),
      WordWithDifficulty('Sérénité', difficulty: 3),
      WordWithDifficulty('Béatitude', difficulty: 3),
      WordWithDifficulty('Exaltation', difficulty: 3),
      WordWithDifficulty('Ravissement', difficulty: 3),

      // ÉMOTIONS NÉGATIVES - Facile
      WordWithDifficulty('Tristesse', difficulty: 1),
      WordWithDifficulty('Colère', difficulty: 1),
      WordWithDifficulty('Peur', difficulty: 1),
      WordWithDifficulty('Douleur', difficulty: 1),
      WordWithDifficulty('Inquiétude', difficulty: 1),
      WordWithDifficulty('Regret', difficulty: 1),

      // ÉMOTIONS NÉGATIVES - Moyen
      WordWithDifficulty('Mélancolie', difficulty: 2),
      WordWithDifficulty('Angoisse', difficulty: 2),
      WordWithDifficulty('Jalousie', difficulty: 2),
      WordWithDifficulty('Honte', difficulty: 2),
      WordWithDifficulty('Ennui', difficulty: 2),
      WordWithDifficulty('Stress', difficulty: 2),
      WordWithDifficulty('Nostalgie', difficulty: 2),
      WordWithDifficulty('Déception', difficulty: 2),
      WordWithDifficulty('Impatience', difficulty: 2),
      WordWithDifficulty('Embarras', difficulty: 2),
      WordWithDifficulty('Solitude', difficulty: 2),

      // ÉMOTIONS NÉGATIVES - Difficile
      WordWithDifficulty('Chagrin', difficulty: 3),
      WordWithDifficulty('Désespoir', difficulty: 3),
      WordWithDifficulty('Fureur', difficulty: 3),
      WordWithDifficulty('Terreur', difficulty: 3),
      WordWithDifficulty('Panique', difficulty: 3),
      WordWithDifficulty('Dégoût', difficulty: 3),
      WordWithDifficulty('Mépris', difficulty: 3),
      WordWithDifficulty('Culpabilité', difficulty: 3),
      WordWithDifficulty('Humiliation', difficulty: 3),
      WordWithDifficulty('Frustration', difficulty: 3),
      WordWithDifficulty('Perplexité', difficulty: 3),
      WordWithDifficulty('Rancœur', difficulty: 3),
      WordWithDifficulty('Amertume', difficulty: 3),
      WordWithDifficulty('Consternation', difficulty: 3),

      // ADJECTIFS DESCRIPTIFS - Facile
      WordWithDifficulty('Grand', difficulty: 1),
      WordWithDifficulty('Petit', difficulty: 1),
      WordWithDifficulty('Beau', difficulty: 1),
      WordWithDifficulty('Joli', difficulty: 1),
      WordWithDifficulty('Gentil', difficulty: 1),
      WordWithDifficulty('Méchant', difficulty: 1),
      WordWithDifficulty('Heureux', difficulty: 1),
      WordWithDifficulty('Triste', difficulty: 1),
      WordWithDifficulty('Chaud', difficulty: 1),
      WordWithDifficulty('Froid', difficulty: 1),
      WordWithDifficulty('Facile', difficulty: 1),
      WordWithDifficulty('Difficile', difficulty: 1),
      WordWithDifficulty('Jeune', difficulty: 1),
      WordWithDifficulty('Vieux', difficulty: 1),
      WordWithDifficulty('Propre', difficulty: 1),
      WordWithDifficulty('Sale', difficulty: 1),

      // ADJECTIFS DESCRIPTIFS - Moyen
      WordWithDifficulty('Magnifique', difficulty: 2),
      WordWithDifficulty('Splendide', difficulty: 2),
      WordWithDifficulty('Courageux', difficulty: 2),
      WordWithDifficulty('Timide', difficulty: 2),
      WordWithDifficulty('Généreux', difficulty: 2),
      WordWithDifficulty('Intelligent', difficulty: 2),
      WordWithDifficulty('Stupide', difficulty: 2),
      WordWithDifficulty('Rapide', difficulty: 2),
      WordWithDifficulty('Lent', difficulty: 2),
      WordWithDifficulty('Fort', difficulty: 2),
      WordWithDifficulty('Faible', difficulty: 2),
      WordWithDifficulty('Amusant', difficulty: 2),
      WordWithDifficulty('Ennuyeux', difficulty: 2),
      WordWithDifficulty('Curieux', difficulty: 2),
      WordWithDifficulty('Patient', difficulty: 2),
      WordWithDifficulty('Honnête', difficulty: 2),
      WordWithDifficulty('Poli', difficulty: 2),

      // ADJECTIFS COMPLEXES - Difficile
      WordWithDifficulty('Magnanime', difficulty: 3),
      WordWithDifficulty('Perspicace', difficulty: 3),
      WordWithDifficulty('Éloquent', difficulty: 3),
      WordWithDifficulty('Époustouflant', difficulty: 3),
      WordWithDifficulty('Majestueux', difficulty: 3),
      WordWithDifficulty('Téméraire', difficulty: 3),
      WordWithDifficulty('Intrépide', difficulty: 3),
      WordWithDifficulty('Pugnace', difficulty: 3),
      WordWithDifficulty('Circonspect', difficulty: 3),
      WordWithDifficulty('Méticuleux', difficulty: 3),
      WordWithDifficulty('Impétueux', difficulty: 3),
      WordWithDifficulty('Belliqueux', difficulty: 3),
      WordWithDifficulty('Versatile', difficulty: 3),
      WordWithDifficulty('Imperturbable', difficulty: 3),

      // VERBES DU QUOTIDIEN - Facile
      WordWithDifficulty('Marcher', difficulty: 1),
      WordWithDifficulty('Courir', difficulty: 1),
      WordWithDifficulty('Sauter', difficulty: 1),
      WordWithDifficulty('Manger', difficulty: 1),
      WordWithDifficulty('Boire', difficulty: 1),
      WordWithDifficulty('Dormir', difficulty: 1),
      WordWithDifficulty('Parler', difficulty: 1),
      WordWithDifficulty('Écouter', difficulty: 1),
      WordWithDifficulty('Regarder', difficulty: 1),
      WordWithDifficulty('Jouer', difficulty: 1),
      WordWithDifficulty('Rire', difficulty: 1),
      WordWithDifficulty('Pleurer', difficulty: 1),
      WordWithDifficulty('Penser', difficulty: 1),
      WordWithDifficulty('Aimer', difficulty: 1),

      // VERBES CRÉATIFS - Moyen
      WordWithDifficulty('Danser', difficulty: 2),
      WordWithDifficulty('Chanter', difficulty: 2),
      WordWithDifficulty('Dessiner', difficulty: 2),
      WordWithDifficulty('Écrire', difficulty: 2),
      WordWithDifficulty('Lire', difficulty: 2),
      WordWithDifficulty('Cuisiner', difficulty: 2),
      WordWithDifficulty('Conduire', difficulty: 2),
      WordWithDifficulty('Nager', difficulty: 2),
      WordWithDifficulty('Grimper', difficulty: 2),
      WordWithDifficulty('Construire', difficulty: 2),
      WordWithDifficulty('Peindre', difficulty: 2),
      WordWithDifficulty('Sculpter', difficulty: 2),
      WordWithDifficulty('Composer', difficulty: 2),
      WordWithDifficulty('Créer', difficulty: 2),

      // VERBES COMPLEXES - Difficile
      WordWithDifficulty('Ramper', difficulty: 2),
      WordWithDifficulty('Jongler', difficulty: 2),
      WordWithDifficulty('Escalader', difficulty: 2),
      WordWithDifficulty('Méditer', difficulty: 2),
      WordWithDifficulty('Scruter', difficulty: 3),
      WordWithDifficulty('Persévérer', difficulty: 3),
      WordWithDifficulty('Contempler', difficulty: 3),
      WordWithDifficulty('Sillonner', difficulty: 3),
      WordWithDifficulty('Vagabonder', difficulty: 2),
      WordWithDifficulty('Déambuler', difficulty: 3),
      WordWithDifficulty('Procrastiner', difficulty: 3),
      WordWithDifficulty('Divaguer', difficulty: 2),

      // ACTIONS PHYSIQUES - Facile
      WordWithDifficulty('Lever', difficulty: 1),
      WordWithDifficulty('Baisser', difficulty: 1),
      WordWithDifficulty('Tourner', difficulty: 1),
      WordWithDifficulty('Pousser', difficulty: 1),
      WordWithDifficulty('Tirer', difficulty: 1),
      WordWithDifficulty('Lancer', difficulty: 1),
      WordWithDifficulty('Attraper', difficulty: 1),
      WordWithDifficulty('Tomber', difficulty: 1),

      // ACTIONS PHYSIQUES - Moyen
      WordWithDifficulty('Soulever', difficulty: 2),
      WordWithDifficulty('Porter', difficulty: 2),
      WordWithDifficulty('Jeter', difficulty: 2),
      WordWithDifficulty('Frapper', difficulty: 2),
      WordWithDifficulty('Caresser', difficulty: 2),
      WordWithDifficulty('Applaudir', difficulty: 2),
      WordWithDifficulty('Siffler', difficulty: 2),
      WordWithDifficulty('Crier', difficulty: 2),

      // ACTIONS MENTALES - Moyen
      WordWithDifficulty('Réfléchir', difficulty: 2),
      WordWithDifficulty('Imaginer', difficulty: 2),
      WordWithDifficulty('Rêver', difficulty: 2),
      WordWithDifficulty('Comprendre', difficulty: 2),
      WordWithDifficulty('Apprendre', difficulty: 2),
      WordWithDifficulty('Mémoriser', difficulty: 2),
      WordWithDifficulty('Oublier', difficulty: 2),
      WordWithDifficulty('Décider', difficulty: 2),

      // ACTIONS MENTALES - Difficile
      WordWithDifficulty('Analyser', difficulty: 3),
      WordWithDifficulty('Synthétiser', difficulty: 2),
      WordWithDifficulty('Conceptualiser', difficulty: 3),
      WordWithDifficulty('Philosopher', difficulty: 3),
      WordWithDifficulty('Ratiociner', difficulty: 3),

      // ADVERBES DE MANIÈRE - Facile
      WordWithDifficulty('Bien', difficulty: 1),
      WordWithDifficulty('Mal', difficulty: 1),
      WordWithDifficulty('Vite', difficulty: 1),
      WordWithDifficulty('Lentement', difficulty: 1),

      // ADVERBES DE MANIÈRE - Moyen
      WordWithDifficulty('Rapidement', difficulty: 2),
      WordWithDifficulty('Doucement', difficulty: 2),
      WordWithDifficulty('Fortement', difficulty: 2),
      WordWithDifficulty('Souvent', difficulty: 2),
      WordWithDifficulty('Parfois', difficulty: 2),
      WordWithDifficulty('Jamais', difficulty: 2),
      WordWithDifficulty('Toujours', difficulty: 2),
      WordWithDifficulty('Ensemble', difficulty: 2),
      WordWithDifficulty('Seul', difficulty: 2),
      WordWithDifficulty('Énormément', difficulty: 2),

      // ADVERBES COMPLEXES - Difficile
      WordWithDifficulty('Promptement', difficulty: 3),
      WordWithDifficulty('Délicatement', difficulty: 3),
      WordWithDifficulty('Méticuleusement', difficulty: 3),
      WordWithDifficulty('Frénétiquement', difficulty: 3),
      WordWithDifficulty('Inlassablement', difficulty: 3),
      WordWithDifficulty('Inexorablement', difficulty: 3),
      WordWithDifficulty('Obstinément', difficulty: 3),
      WordWithDifficulty('Résolument', difficulty: 3),
      WordWithDifficulty('Vaillamment', difficulty: 3),
      WordWithDifficulty('Ardemment', difficulty: 3),

      // COULEURS - Facile
      WordWithDifficulty('Rouge', difficulty: 1),
      WordWithDifficulty('Bleu', difficulty: 1),
      WordWithDifficulty('Jaune', difficulty: 1),
      WordWithDifficulty('Vert', difficulty: 1),
      WordWithDifficulty('Noir', difficulty: 1),
      WordWithDifficulty('Blanc', difficulty: 1),
      WordWithDifficulty('Rose', difficulty: 1),
      WordWithDifficulty('Orange', difficulty: 1),
      WordWithDifficulty('Violet', difficulty: 1),
      WordWithDifficulty('Gris', difficulty: 1),

      // COULEURS - Moyen
      WordWithDifficulty('Turquoise', difficulty: 2),
      WordWithDifficulty('Bordeaux', difficulty: 2),
      WordWithDifficulty('Beige', difficulty: 2),
      WordWithDifficulty('Marron', difficulty: 2),
      WordWithDifficulty('Argenté', difficulty: 2),
      WordWithDifficulty('Doré', difficulty: 2),
      WordWithDifficulty('Pourpre', difficulty: 2),
      WordWithDifficulty('Indigo', difficulty: 2),
      WordWithDifficulty('Émeraude', difficulty: 2),
      WordWithDifficulty('Azur', difficulty: 2),

      // COULEURS - Difficile
      WordWithDifficulty('Écarlate', difficulty: 3),
      WordWithDifficulty('Vermillon', difficulty: 3),
      WordWithDifficulty('Grenat', difficulty: 3),
      WordWithDifficulty('Ocre', difficulty: 2),
      WordWithDifficulty('Cyan', difficulty: 2),
      WordWithDifficulty('Magenta', difficulty: 3),
      WordWithDifficulty('Améthyste', difficulty: 2),
      WordWithDifficulty('Saphir', difficulty: 3),
      WordWithDifficulty('Ivoire', difficulty: 3),
      WordWithDifficulty('Carmin', difficulty: 3),

      // FORMES GÉOMÉTRIQUES - Facile
      WordWithDifficulty('Carré', difficulty: 1),
      WordWithDifficulty('Cercle', difficulty: 1),
      WordWithDifficulty('Triangle', difficulty: 1),
      WordWithDifficulty('Rectangle', difficulty: 1),
      WordWithDifficulty('Rond', difficulty: 1),
      WordWithDifficulty('Ligne', difficulty: 1),
      WordWithDifficulty('Point', difficulty: 1),

      // FORMES GÉOMÉTRIQUES - Moyen
      WordWithDifficulty('Losange', difficulty: 2),
      WordWithDifficulty('Ovale', difficulty: 2),
      WordWithDifficulty('Hexagone', difficulty: 2),
      WordWithDifficulty('Pentagone', difficulty: 2),
      WordWithDifficulty('Étoile', difficulty: 2),
      WordWithDifficulty('Cube', difficulty: 2),
      WordWithDifficulty('Sphère', difficulty: 2),
      WordWithDifficulty('Cylindre', difficulty: 2),
      WordWithDifficulty('Pyramide', difficulty: 2),

      // FORMES GÉOMÉTRIQUES - Difficile
      WordWithDifficulty('Parallélépipède', difficulty: 2),
      WordWithDifficulty('Octogone', difficulty: 2),
      WordWithDifficulty('Trapèze', difficulty: 2),
      WordWithDifficulty('Ellipse', difficulty: 3),
      WordWithDifficulty('Prisme', difficulty: 3),
      WordWithDifficulty('Tétraèdre', difficulty: 3),
      WordWithDifficulty('Dodécaèdre', difficulty: 3),
      WordWithDifficulty('Icosaèdre', difficulty: 3),

      // NOMBRES ET QUANTITÉS - Facile
      WordWithDifficulty('Un', difficulty: 1),
      WordWithDifficulty('Deux', difficulty: 1),
      WordWithDifficulty('Trois', difficulty: 1),
      WordWithDifficulty('Dix', difficulty: 1),
      WordWithDifficulty('Cent', difficulty: 1),
      WordWithDifficulty('Mille', difficulty: 1),
      WordWithDifficulty('Beaucoup', difficulty: 1),
      WordWithDifficulty('Peu', difficulty: 1),

      // NOMBRES ET QUANTITÉS - Moyen
      WordWithDifficulty('Dizaine', difficulty: 2),
      WordWithDifficulty('Centaine', difficulty: 2),
      WordWithDifficulty('Paire', difficulty: 1),
      WordWithDifficulty('Trio', difficulty: 2),
      WordWithDifficulty('Douzaine', difficulty: 2),
      WordWithDifficulty('Moitié', difficulty: 1),
      WordWithDifficulty('Quart', difficulty: 1),
      WordWithDifficulty('Tiers', difficulty: 1),
      WordWithDifficulty('Double', difficulty: 1),
      WordWithDifficulty('Triple', difficulty: 1),

      // NOMBRES ET QUANTITÉS - Difficile
      WordWithDifficulty('Quintuple', difficulty: 2),
      WordWithDifficulty('Décuple', difficulty: 2),
      WordWithDifficulty('Infinité', difficulty: 3),
      WordWithDifficulty('Multitude', difficulty: 3),
      WordWithDifficulty('Poignée', difficulty: 2),
      WordWithDifficulty('Kyrielle', difficulty: 3),
      WordWithDifficulty('Pléthore', difficulty: 3),

      // TEMPORALITÉ - Facile
      WordWithDifficulty('Matin', difficulty: 1),
      WordWithDifficulty('Midi', difficulty: 1),
      WordWithDifficulty('Soir', difficulty: 1),
      WordWithDifficulty('Nuit', difficulty: 1),
      WordWithDifficulty('Jour', difficulty: 1),
      WordWithDifficulty('Semaine', difficulty: 1),
      WordWithDifficulty('Mois', difficulty: 1),
      WordWithDifficulty('Année', difficulty: 1),
      WordWithDifficulty('Hier', difficulty: 1),
      WordWithDifficulty('Aujourd\'hui', difficulty: 1),
      WordWithDifficulty('Demain', difficulty: 1),

      // TEMPORALITÉ - Moyen
      WordWithDifficulty('Printemps', difficulty: 1),
      WordWithDifficulty('Été', difficulty: 1),
      WordWithDifficulty('Automne', difficulty: 1),
      WordWithDifficulty('Hiver', difficulty: 1),
      WordWithDifficulty('Aube', difficulty: 2),
      WordWithDifficulty('Crépuscule', difficulty: 2),
      WordWithDifficulty('Décennie', difficulty: 2),
      WordWithDifficulty('Siècle', difficulty: 1),
      WordWithDifficulty('Instant', difficulty: 2),
      WordWithDifficulty('Moment', difficulty: 2),

      // TEMPORALITÉ - Difficile
      WordWithDifficulty('Millénaire', difficulty: 2),
      WordWithDifficulty('Quinzaine', difficulty: 2),
      WordWithDifficulty('Lustrum', difficulty: 3),
      WordWithDifficulty('Éternité', difficulty: 2),
      WordWithDifficulty('Éphémère', difficulty: 2),
      WordWithDifficulty('Pérennité', difficulty: 3),
      WordWithDifficulty('Postérité', difficulty: 2),

      // MÉTÉO ET PHÉNOMÈNES NATURELS - Facile
      WordWithDifficulty('Pluie', difficulty: 1),
      WordWithDifficulty('Soleil', difficulty: 1),
      WordWithDifficulty('Nuage', difficulty: 1),
      WordWithDifficulty('Vent', difficulty: 1),
      WordWithDifficulty('Neige', difficulty: 1),
      WordWithDifficulty('Orage', difficulty: 1),
      WordWithDifficulty('Ciel', difficulty: 1),

      // MÉTÉO ET PHÉNOMÈNES NATURELS - Moyen
      WordWithDifficulty('Arc-en-ciel', difficulty: 1),
      WordWithDifficulty('Brouillard', difficulty: 1),
      WordWithDifficulty('Tempête', difficulty: 1),
      WordWithDifficulty('Éclair', difficulty: 1),
      WordWithDifficulty('Tonnerre', difficulty: 1),
      WordWithDifficulty('Grêle', difficulty: 1),
      WordWithDifficulty('Canicule', difficulty: 1),
      WordWithDifficulty('Rosée', difficulty: 2),
      WordWithDifficulty('Givre', difficulty: 2),
      WordWithDifficulty('Verglas', difficulty: 1),

      // MÉTÉO ET PHÉNOMÈNES NATURELS - Difficile
      WordWithDifficulty('Blizzard', difficulty: 2),
      WordWithDifficulty('Cyclone', difficulty: 1),
      WordWithDifficulty('Tornade', difficulty: 1),
      WordWithDifficulty('Ouragan', difficulty: 2),
      WordWithDifficulty('Tsunami', difficulty: 1),
      WordWithDifficulty('Trombe', difficulty: 2),
      WordWithDifficulty('Bruine', difficulty: 2),
      WordWithDifficulty('Crachin', difficulty: 2),
      WordWithDifficulty('Avalanche', difficulty: 2),

      // RELATIONS ET LIENS - Facile
      WordWithDifficulty('Ami', difficulty: 1),
      WordWithDifficulty('Famille', difficulty: 1),
      WordWithDifficulty('Père', difficulty: 1),
      WordWithDifficulty('Mère', difficulty: 1),
      WordWithDifficulty('Frère', difficulty: 1),
      WordWithDifficulty('Sœur', difficulty: 1),
      WordWithDifficulty('Enfant', difficulty: 1),
      WordWithDifficulty('Bébé', difficulty: 1),

      // RELATIONS ET LIENS - Moyen
      WordWithDifficulty('Voisin', difficulty: 2),
      WordWithDifficulty('Collègue', difficulty: 2),
      WordWithDifficulty('Cousin', difficulty: 2),
      WordWithDifficulty('Oncle', difficulty: 2),
      WordWithDifficulty('Tante', difficulty: 2),
      WordWithDifficulty('Neveu', difficulty: 2),
      WordWithDifficulty('Nièce', difficulty: 2),
      WordWithDifficulty('Parrain', difficulty: 2),
      WordWithDifficulty('Marraine', difficulty: 2),
      WordWithDifficulty('Camarade', difficulty: 2),

      // RELATIONS ET LIENS - Difficile
      WordWithDifficulty('Aïeul', difficulty: 3),
      WordWithDifficulty('Descendant', difficulty: 2),
      WordWithDifficulty('Ancêtre', difficulty: 2),
      WordWithDifficulty('Rival', difficulty: 2),
      WordWithDifficulty('Antagoniste', difficulty: 3),
      WordWithDifficulty('Complice', difficulty: 3),
      WordWithDifficulty('Allié', difficulty: 2),
      WordWithDifficulty('Contemporain', difficulty: 2),

      // TEXTURES ET SENSATIONS TACTILES - Facile
      WordWithDifficulty('Doux', difficulty: 1),
      WordWithDifficulty('Dur', difficulty: 1),
      WordWithDifficulty('Lisse', difficulty: 1),
      WordWithDifficulty('Mou', difficulty: 1),
      WordWithDifficulty('Sec', difficulty: 1),
      WordWithDifficulty('Mouillé', difficulty: 1),

      // TEXTURES ET SENSATIONS TACTILES - Moyen
      WordWithDifficulty('Rugueux', difficulty: 2),
      WordWithDifficulty('Collant', difficulty: 2),
      WordWithDifficulty('Glissant', difficulty: 2),
      WordWithDifficulty('Râpeux', difficulty: 2),
      WordWithDifficulty('Moelleux', difficulty: 2),
      WordWithDifficulty('Soyeux', difficulty: 2),
      WordWithDifficulty('Épineux', difficulty: 3),
      WordWithDifficulty('Pelucheux', difficulty: 3),

      // TEXTURES ET SENSATIONS TACTILES - Difficile
      WordWithDifficulty('Visqueux', difficulty: 3),
      WordWithDifficulty('Granuleux', difficulty: 3),
      WordWithDifficulty('Velouté', difficulty: 3),
      WordWithDifficulty('Spongieux', difficulty: 3),
      WordWithDifficulty('Friable', difficulty: 3),
      WordWithDifficulty('Grumeleux', difficulty: 3),
      WordWithDifficulty('Croustillant', difficulty: 3),

      // GOÛTS ET SAVEURS - Facile
      WordWithDifficulty('Sucré', difficulty: 1),
      WordWithDifficulty('Salé', difficulty: 1),
      WordWithDifficulty('Bon', difficulty: 1),
      WordWithDifficulty('Mauvais', difficulty: 1),

      // GOÛTS ET SAVEURS - Moyen
      WordWithDifficulty('Amer', difficulty: 2),
      WordWithDifficulty('Acide', difficulty: 2),
      WordWithDifficulty('Épicé', difficulty: 2),
      WordWithDifficulty('Piquant', difficulty: 2),
      WordWithDifficulty('Fade', difficulty: 2),
      WordWithDifficulty('Savoureux', difficulty: 2),
      WordWithDifficulty('Délicieux', difficulty: 2),

      // GOÛTS ET SAVEURS - Difficile
      WordWithDifficulty('Âcre', difficulty: 3),
      WordWithDifficulty('Aigre-doux', difficulty: 3),
      WordWithDifficulty('Astringent', difficulty: 3),
      WordWithDifficulty('Umami', difficulty: 3),
      WordWithDifficulty('Âpre', difficulty: 3),
      WordWithDifficulty('Succulent', difficulty: 3),

      // ODEURS - Facile
      WordWithDifficulty('Parfum', difficulty: 1),
      WordWithDifficulty('Odeur', difficulty: 1),
      WordWithDifficulty('Fleur', difficulty: 1),

      // ODEURS - Moyen
      WordWithDifficulty('Parfumé', difficulty: 2),
      WordWithDifficulty('Fleuri', difficulty: 2),
      WordWithDifficulty('Boisé', difficulty: 2),
      WordWithDifficulty('Mentholé', difficulty: 2),
      WordWithDifficulty('Fruité', difficulty: 2),
      WordWithDifficulty('Aromatique', difficulty: 2),

      // ODEURS - Difficile
      WordWithDifficulty('Musqué', difficulty: 3),
      WordWithDifficulty('Nauséabond', difficulty: 3),
      WordWithDifficulty('Fétide', difficulty: 3),
      WordWithDifficulty('Pestilentiel', difficulty: 3),
      WordWithDifficulty('Entêtant', difficulty: 3),
      WordWithDifficulty('Capiteux', difficulty: 3),

      // SONS ET BRUITS - Facile
      WordWithDifficulty('Bruit', difficulty: 1),
      WordWithDifficulty('Cri', difficulty: 1),
      WordWithDifficulty('Chant', difficulty: 1),
      WordWithDifficulty('Musique', difficulty: 1),
      WordWithDifficulty('Silence', difficulty: 1),

      // SONS ET BRUITS - Moyen
      WordWithDifficulty('Murmure', difficulty: 2),
      WordWithDifficulty('Chuchotement', difficulty: 2),
      WordWithDifficulty('Sifflement', difficulty: 2),
      WordWithDifficulty('Bourdonnement', difficulty: 2),
      WordWithDifficulty('Craquement', difficulty: 2),
      WordWithDifficulty('Grincement', difficulty: 2),
      WordWithDifficulty('Claquement', difficulty: 2),
      WordWithDifficulty('Tintement', difficulty: 3),
      WordWithDifficulty('Vrombissement', difficulty: 2),

      // SONS ET BRUITS - Difficile
      WordWithDifficulty('Tumulte', difficulty: 3),
      WordWithDifficulty('Vacarme', difficulty: 3),
      WordWithDifficulty('Fracas', difficulty: 3),
      WordWithDifficulty('Crescendo', difficulty: 3),
      WordWithDifficulty('Cacophonie', difficulty: 3),
      WordWithDifficulty('Stridulation', difficulty: 3),
      WordWithDifficulty('Bruissement', difficulty: 3),

      // CONCEPTS PHILOSOPHIQUES - Facile
      WordWithDifficulty('Vérité', difficulty: 1),
      WordWithDifficulty('Liberté', difficulty: 1),
      WordWithDifficulty('Paix', difficulty: 1),
      WordWithDifficulty('Guerre', difficulty: 1),

      // CONCEPTS PHILOSOPHIQUES - Moyen
      WordWithDifficulty('Justice', difficulty: 2),
      WordWithDifficulty('Égalité', difficulty: 2),
      WordWithDifficulty('Sagesse', difficulty: 2),
      WordWithDifficulty('Connaissance', difficulty: 2),
      WordWithDifficulty('Conscience', difficulty: 2),
      WordWithDifficulty('Raison', difficulty: 2),
      WordWithDifficulty('Bonté', difficulty: 2),
      WordWithDifficulty('Beauté', difficulty: 2),

      // CONCEPTS PHILOSOPHIQUES - Difficile
      WordWithDifficulty('Transcendance', difficulty: 3),
      WordWithDifficulty('Immanence', difficulty: 3),
      WordWithDifficulty('Métaphysique', difficulty: 3),
      WordWithDifficulty('Ontologie', difficulty: 3),
      WordWithDifficulty('Épistémologie', difficulty: 3),
      WordWithDifficulty('Dialectique', difficulty: 3),
      WordWithDifficulty('Absolu', difficulty: 3),
      WordWithDifficulty('Nihilisme', difficulty: 3),

      // VALEURS MORALES - Facile
      WordWithDifficulty('Respect', difficulty: 1),
      WordWithDifficulty('Partage', difficulty: 1),
      WordWithDifficulty('Aide', difficulty: 1),

      // VALEURS MORALES - Moyen
      WordWithDifficulty('Honnêteté', difficulty: 2),
      WordWithDifficulty('Loyauté', difficulty: 2),
      WordWithDifficulty('Courage', difficulty: 2),
      WordWithDifficulty('Persévérance', difficulty: 2),
      WordWithDifficulty('Humilité', difficulty: 2),
      WordWithDifficulty('Tolérance', difficulty: 2),
      WordWithDifficulty('Bienveillance', difficulty: 2),
      WordWithDifficulty('Solidarité', difficulty: 2),

      // VALEURS MORALES - Difficile
      WordWithDifficulty('Intégrité', difficulty: 3),
      WordWithDifficulty('Probité', difficulty: 3),
      WordWithDifficulty('Abnégation', difficulty: 3),
      WordWithDifficulty('Altruisme', difficulty: 3),
      WordWithDifficulty('Mansuétude', difficulty: 3),
      WordWithDifficulty('Magnanimité', difficulty: 3),
      WordWithDifficulty('Clémence', difficulty: 3),

      // MATÉRIAUX - Facile
      WordWithDifficulty('Bois', difficulty: 1),
      WordWithDifficulty('Fer', difficulty: 1),
      WordWithDifficulty('Pierre', difficulty: 1),
      WordWithDifficulty('Verre', difficulty: 1),
      WordWithDifficulty('Papier', difficulty: 1),
      WordWithDifficulty('Tissu', difficulty: 1),

      // MATÉRIAUX - Moyen
      WordWithDifficulty('Plastique', difficulty: 2),
      WordWithDifficulty('Métal', difficulty: 2),
      WordWithDifficulty('Acier', difficulty: 2),
      WordWithDifficulty('Cuivre', difficulty: 2),
      WordWithDifficulty('Bronze', difficulty: 2),
      WordWithDifficulty('Argent', difficulty: 2),
      WordWithDifficulty('Or', difficulty: 2),
      WordWithDifficulty('Marbre', difficulty: 2),
      WordWithDifficulty('Granit', difficulty: 3),
      WordWithDifficulty('Béton', difficulty: 2),
      WordWithDifficulty('Céramique', difficulty: 3),

      // MATÉRIAUX - Difficile
      WordWithDifficulty('Aluminium', difficulty: 2),
      WordWithDifficulty('Titane', difficulty: 2),
      WordWithDifficulty('Platine', difficulty: 2),
      WordWithDifficulty('Porcelaine', difficulty: 2),
      WordWithDifficulty('Ébène', difficulty: 2),
      WordWithDifficulty('Cachemire', difficulty: 3),
      WordWithDifficulty('Velours', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - ÉTATS PHYSIQUES
      // ============================================

      // ÉTATS PHYSIQUES - Facile
      WordWithDifficulty('Fatigué', difficulty: 1),
      WordWithDifficulty('Reposé', difficulty: 1),
      WordWithDifficulty('Malade', difficulty: 1),
      WordWithDifficulty('En forme', difficulty: 1),
      WordWithDifficulty('Affamé', difficulty: 1),
      WordWithDifficulty('Rassasié', difficulty: 2),
      WordWithDifficulty('Assoiffé', difficulty: 2),
      WordWithDifficulty('Endormi', difficulty: 1),
      WordWithDifficulty('Éveillé', difficulty: 1),
      WordWithDifficulty('Énergique', difficulty: 1),
      WordWithDifficulty('Épuisé', difficulty: 2),
      WordWithDifficulty('Ivre', difficulty: 2),
      WordWithDifficulty('Sobre', difficulty: 2),
      WordWithDifficulty('Blessé', difficulty: 1),
      WordWithDifficulty('Guéri', difficulty: 2),

      // ÉTATS PHYSIQUES - Moyen
      WordWithDifficulty('Fébrile', difficulty: 3),
      WordWithDifficulty('Convalescent', difficulty: 3),
      WordWithDifficulty('Somnolent', difficulty: 2),
      WordWithDifficulty('Vigoureux', difficulty: 2),
      WordWithDifficulty('Affaibli', difficulty: 2),
      WordWithDifficulty('Revigoré', difficulty: 3),
      WordWithDifficulty('Exténué', difficulty: 3),
      WordWithDifficulty('Alerte', difficulty: 2),
      WordWithDifficulty('Apathique', difficulty: 3),
      WordWithDifficulty('Dynamique', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - ÉTATS MENTAUX/SITUATIONS
      // ============================================

      // ÉTATS MENTAUX - Facile
      WordWithDifficulty('Occupé', difficulty: 1),
      WordWithDifficulty('Libre', difficulty: 1),
      WordWithDifficulty('Pressé', difficulty: 1),
      WordWithDifficulty('Détendu', difficulty: 1),
      WordWithDifficulty('Concentré', difficulty: 1),
      WordWithDifficulty('Distrait', difficulty: 2),
      WordWithDifficulty('Motivé', difficulty: 1),
      WordWithDifficulty('Démotivé', difficulty: 2),
      WordWithDifficulty('Confus', difficulty: 2),
      WordWithDifficulty('Clair', difficulty: 1),
      WordWithDifficulty('Perdu', difficulty: 1),
      WordWithDifficulty('Sûr', difficulty: 1),
      WordWithDifficulty('Hésitant', difficulty: 2),
      WordWithDifficulty('Décidé', difficulty: 2),
      WordWithDifficulty('Prêt', difficulty: 1),
      WordWithDifficulty('Débordé', difficulty: 2),

      // ÉTATS MENTAUX - Moyen
      WordWithDifficulty('Serein', difficulty: 2),
      WordWithDifficulty('Angoissé', difficulty: 2),
      WordWithDifficulty('Préoccupé', difficulty: 2),
      WordWithDifficulty('Insouciant', difficulty: 2),
      WordWithDifficulty('Absorbé', difficulty: 2),
      WordWithDifficulty('Rêveur', difficulty: 2),
      WordWithDifficulty('Lucide', difficulty: 2),
      WordWithDifficulty('Hagard', difficulty: 3),
      WordWithDifficulty('Médusé', difficulty: 3),
      WordWithDifficulty('Ébahi', difficulty: 2),
      WordWithDifficulty('Interloqué', difficulty: 3),
      WordWithDifficulty('Abasourdi', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - ADJECTIFS DE PERSONNALITÉ
      // ============================================

      // PERSONNALITÉ - Facile
      WordWithDifficulty('Sympa', difficulty: 1),
      WordWithDifficulty('Drôle', difficulty: 1),
      WordWithDifficulty('Sérieux', difficulty: 1),
      WordWithDifficulty('Nerveux', difficulty: 1),
      WordWithDifficulty('Bavard', difficulty: 1),
      WordWithDifficulty('Silencieux', difficulty: 1),
      WordWithDifficulty('Sociable', difficulty: 2),
      WordWithDifficulty('Réservé', difficulty: 2),
      WordWithDifficulty('Optimiste', difficulty: 2),
      WordWithDifficulty('Pessimiste', difficulty: 2),
      WordWithDifficulty('Créatif', difficulty: 2),
      WordWithDifficulty('Pratique', difficulty: 2),

      // PERSONNALITÉ - Moyen
      WordWithDifficulty('Ambitieux', difficulty: 2),
      WordWithDifficulty('Modeste', difficulty: 2),
      WordWithDifficulty('Orgueilleux', difficulty: 2),
      WordWithDifficulty('Humble', difficulty: 2),
      WordWithDifficulty('Autoritaire', difficulty: 2),
      WordWithDifficulty('Docile', difficulty: 2),
      WordWithDifficulty('Rebelle', difficulty: 2),
      WordWithDifficulty('Conformiste', difficulty: 3),
      WordWithDifficulty('Original', difficulty: 2),
      WordWithDifficulty('Excentrique', difficulty: 2),
      WordWithDifficulty('Impulsif', difficulty: 2),
      WordWithDifficulty('Réfléchi', difficulty: 2),
      WordWithDifficulty('Spontané', difficulty: 2),
      WordWithDifficulty('Calculateur', difficulty: 2),
      WordWithDifficulty('Naïf', difficulty: 2),
      WordWithDifficulty('Rusé', difficulty: 2),
      WordWithDifficulty('Malin', difficulty: 1),
      WordWithDifficulty('Bête', difficulty: 1),
      WordWithDifficulty('Sensible', difficulty: 2),
      WordWithDifficulty('Insensible', difficulty: 2),
      WordWithDifficulty('Émotif', difficulty: 2),
      WordWithDifficulty('Chaleureux', difficulty: 2),
      WordWithDifficulty('Distant', difficulty: 2),
      WordWithDifficulty('Avare', difficulty: 2),
      WordWithDifficulty('Dépensier', difficulty: 2),
      WordWithDifficulty('Économe', difficulty: 2),
      WordWithDifficulty('Paresseux', difficulty: 1),
      WordWithDifficulty('Travailleur', difficulty: 2),
      WordWithDifficulty('Perfectionniste', difficulty: 2),
      WordWithDifficulty('Négligent', difficulty: 2),
      WordWithDifficulty('Soigneux', difficulty: 2),
      WordWithDifficulty('Maladroit', difficulty: 2),
      WordWithDifficulty('Adroit', difficulty: 2),
      WordWithDifficulty('Gourmand', difficulty: 1),

      // PERSONNALITÉ - Difficile
      WordWithDifficulty('Susceptible', difficulty: 3),
      WordWithDifficulty('Stoïque', difficulty: 3),
      WordWithDifficulty('Volubile', difficulty: 3),
      WordWithDifficulty('Taciturne', difficulty: 3),
      WordWithDifficulty('Affable', difficulty: 3),
      WordWithDifficulty('Bourru', difficulty: 3),
      WordWithDifficulty('Bougon', difficulty: 2),
      WordWithDifficulty('Enjoué', difficulty: 2),
      WordWithDifficulty('Morose', difficulty: 3),
      WordWithDifficulty('Jovial', difficulty: 2),
      WordWithDifficulty('Acariâtre', difficulty: 3),
      WordWithDifficulty('Débonnaire', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - VERBES DE COMMUNICATION
      // ============================================

      // COMMUNICATION - Facile
      WordWithDifficulty('Dire', difficulty: 1),
      WordWithDifficulty('Demander', difficulty: 1),
      WordWithDifficulty('Répondre', difficulty: 1),
      WordWithDifficulty('Expliquer', difficulty: 1),
      WordWithDifficulty('Raconter', difficulty: 1),
      WordWithDifficulty('Appeler', difficulty: 1),
      WordWithDifficulty('Chuchoter', difficulty: 2),
      WordWithDifficulty('Murmurer', difficulty: 2),
      WordWithDifficulty('Hurler', difficulty: 2),
      WordWithDifficulty('Annoncer', difficulty: 1),
      WordWithDifficulty('Informer', difficulty: 2),
      WordWithDifficulty('Prévenir', difficulty: 2),
      WordWithDifficulty('Avertir', difficulty: 2),
      WordWithDifficulty('Promettre', difficulty: 2),
      WordWithDifficulty('Jurer', difficulty: 2),

      // COMMUNICATION - Moyen
      WordWithDifficulty('Discuter', difficulty: 1),
      WordWithDifficulty('Négocier', difficulty: 2),
      WordWithDifficulty('Convaincre', difficulty: 2),
      WordWithDifficulty('Persuader', difficulty: 2),
      WordWithDifficulty('Argumenter', difficulty: 2),
      WordWithDifficulty('Débattre', difficulty: 2),
      WordWithDifficulty('Contredire', difficulty: 2),
      WordWithDifficulty('Approuver', difficulty: 2),
      WordWithDifficulty('Refuser', difficulty: 1),
      WordWithDifficulty('Accepter', difficulty: 1),
      WordWithDifficulty('Proposer', difficulty: 1),
      WordWithDifficulty('Suggérer', difficulty: 2),
      WordWithDifficulty('Conseiller', difficulty: 2),
      WordWithDifficulty('Recommander', difficulty: 2),
      WordWithDifficulty('Avouer', difficulty: 2),
      WordWithDifficulty('Confesser', difficulty: 2),
      WordWithDifficulty('Mentir', difficulty: 1),
      WordWithDifficulty('Tromper', difficulty: 2),
      WordWithDifficulty('Rassurer', difficulty: 2),
      WordWithDifficulty('Inquiéter', difficulty: 2),
      WordWithDifficulty('Féliciter', difficulty: 2),
      WordWithDifficulty('Complimenter', difficulty: 2),
      WordWithDifficulty('Critiquer', difficulty: 2),
      WordWithDifficulty('Reprocher', difficulty: 2),
      WordWithDifficulty('Insulter', difficulty: 2),
      WordWithDifficulty('Menacer', difficulty: 2),
      WordWithDifficulty('Supplier', difficulty: 2),
      WordWithDifficulty('Implorer', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - VERBES DOMESTIQUES
      // ============================================

      // VERBES DOMESTIQUES - Facile
      WordWithDifficulty('Ranger', difficulty: 1),
      WordWithDifficulty('Nettoyer', difficulty: 1),
      WordWithDifficulty('Laver', difficulty: 1),
      WordWithDifficulty('Sécher', difficulty: 1),
      WordWithDifficulty('Repasser', difficulty: 2),
      WordWithDifficulty('Plier', difficulty: 1),
      WordWithDifficulty('Balayer', difficulty: 1),
      WordWithDifficulty('Aspirer', difficulty: 2),
      WordWithDifficulty('Frotter', difficulty: 2),
      WordWithDifficulty('Essuyer', difficulty: 1),
      WordWithDifficulty('Rincer', difficulty: 2),
      WordWithDifficulty('Tremper', difficulty: 2),
      WordWithDifficulty('Accrocher', difficulty: 1),
      WordWithDifficulty('Décrocher', difficulty: 2),
      WordWithDifficulty('Débrancher', difficulty: 2),
      WordWithDifficulty('Brancher', difficulty: 1),
      WordWithDifficulty('Allumer', difficulty: 1),
      WordWithDifficulty('Éteindre', difficulty: 1),
      WordWithDifficulty('Ouvrir', difficulty: 1),
      WordWithDifficulty('Fermer', difficulty: 1),
      WordWithDifficulty('Verrouiller', difficulty: 2),
      WordWithDifficulty('Déverrouiller', difficulty: 2),

      // VERBES DOMESTIQUES - Moyen
      WordWithDifficulty('Récurer', difficulty: 3),
      WordWithDifficulty('Dégraisser', difficulty: 3),
      WordWithDifficulty('Détartrer', difficulty: 3),
      WordWithDifficulty('Dépoussiérer', difficulty: 2),
      WordWithDifficulty('Aérer', difficulty: 2),
      WordWithDifficulty('Ventiler', difficulty: 2),
      WordWithDifficulty('Chauffer', difficulty: 1),
      WordWithDifficulty('Refroidir', difficulty: 2),
      WordWithDifficulty('Congeler', difficulty: 2),
      WordWithDifficulty('Décongeler', difficulty: 2),
      WordWithDifficulty('Réchauffer', difficulty: 1),
      WordWithDifficulty('Cuire', difficulty: 1),
      WordWithDifficulty('Mijoter', difficulty: 2),
      WordWithDifficulty('Bouillir', difficulty: 2),
      WordWithDifficulty('Frire', difficulty: 2),
      WordWithDifficulty('Griller', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - NOMS ABSTRAITS
      // ============================================

      // NOMS ABSTRAITS - Facile
      WordWithDifficulty('Chance', difficulty: 1),
      WordWithDifficulty('Malchance', difficulty: 1),
      WordWithDifficulty('Succès', difficulty: 1),
      WordWithDifficulty('Échec', difficulty: 1),
      WordWithDifficulty('Victoire', difficulty: 1),
      WordWithDifficulty('Défaite', difficulty: 1),
      WordWithDifficulty('Effort', difficulty: 1),
      WordWithDifficulty('Repos', difficulty: 1),
      WordWithDifficulty('Travail', difficulty: 1),
      WordWithDifficulty('Loisir', difficulty: 2),
      WordWithDifficulty('Vacances', difficulty: 1),
      WordWithDifficulty('Fête', difficulty: 1),
      WordWithDifficulty('Voyage', difficulty: 1),
      WordWithDifficulty('Aventure', difficulty: 1),
      WordWithDifficulty('Rêve', difficulty: 1),
      WordWithDifficulty('Cauchemar', difficulty: 1),
      WordWithDifficulty('Secret', difficulty: 1),
      WordWithDifficulty('Mystère', difficulty: 1),
      WordWithDifficulty('Problème', difficulty: 1),
      WordWithDifficulty('Solution', difficulty: 1),
      WordWithDifficulty('Question', difficulty: 1),
      WordWithDifficulty('Réponse', difficulty: 1),
      WordWithDifficulty('Idée', difficulty: 1),
      WordWithDifficulty('Opinion', difficulty: 2),
      WordWithDifficulty('Avis', difficulty: 1),

      // NOMS ABSTRAITS - Moyen
      WordWithDifficulty('Destin', difficulty: 2),
      WordWithDifficulty('Hasard', difficulty: 2),
      WordWithDifficulty('Coïncidence', difficulty: 2),
      WordWithDifficulty('Miracle', difficulty: 1),
      WordWithDifficulty('Tragédie', difficulty: 2),
      WordWithDifficulty('Drame', difficulty: 2),
      WordWithDifficulty('Comédie', difficulty: 1),
      WordWithDifficulty('Ironie', difficulty: 2),
      WordWithDifficulty('Paradoxe', difficulty: 3),
      WordWithDifficulty('Dilemme', difficulty: 2),
      WordWithDifficulty('Choix', difficulty: 1),
      WordWithDifficulty('Décision', difficulty: 1),
      WordWithDifficulty('Conséquence', difficulty: 2),
      WordWithDifficulty('Cause', difficulty: 2),
      WordWithDifficulty('Effet', difficulty: 2),
      WordWithDifficulty('Excuse', difficulty: 1),
      WordWithDifficulty('Prétexte', difficulty: 2),
      WordWithDifficulty('Motif', difficulty: 2),
      WordWithDifficulty('But', difficulty: 1),
      WordWithDifficulty('Objectif', difficulty: 2),
      WordWithDifficulty('Ambition', difficulty: 2),
      WordWithDifficulty('Désir', difficulty: 2),
      WordWithDifficulty('Envie', difficulty: 1),
      WordWithDifficulty('Besoin', difficulty: 1),
      WordWithDifficulty('Nécessité', difficulty: 2),
      WordWithDifficulty('Urgence', difficulty: 2),
      WordWithDifficulty('Priorité', difficulty: 2),
      WordWithDifficulty('Importance', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - EXPRESSIONS DE LIEU
      // ============================================

      // LIEUX - Facile
      WordWithDifficulty('Devant', difficulty: 1),
      WordWithDifficulty('Derrière', difficulty: 1),
      WordWithDifficulty('Dessus', difficulty: 1),
      WordWithDifficulty('Dessous', difficulty: 1),
      WordWithDifficulty('Dedans', difficulty: 1),
      WordWithDifficulty('Dehors', difficulty: 1),
      WordWithDifficulty('À côté', difficulty: 1),
      WordWithDifficulty('À droite', difficulty: 1),
      WordWithDifficulty('À gauche', difficulty: 1),
      WordWithDifficulty('En haut', difficulty: 1),
      WordWithDifficulty('En bas', difficulty: 1),
      WordWithDifficulty('Au milieu', difficulty: 1),
      WordWithDifficulty('Au centre', difficulty: 1),
      WordWithDifficulty('Au bord', difficulty: 1),
      WordWithDifficulty('Au fond', difficulty: 1),
      WordWithDifficulty('Près', difficulty: 1),
      WordWithDifficulty('Loin', difficulty: 1),
      WordWithDifficulty('Ici', difficulty: 1),
      WordWithDifficulty('Là-bas', difficulty: 1),
      WordWithDifficulty('Partout', difficulty: 1),
      WordWithDifficulty('Nulle part', difficulty: 2),
      WordWithDifficulty('Quelque part', difficulty: 2),
      WordWithDifficulty('Ailleurs', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - ADJECTIFS TAILLE/FORME
      // ============================================

      // TAILLE ET DIMENSIONS - Facile
      WordWithDifficulty('Énorme', difficulty: 1),
      WordWithDifficulty('Minuscule', difficulty: 1),
      WordWithDifficulty('Gigantesque', difficulty: 2),
      WordWithDifficulty('Microscopique', difficulty: 2),
      WordWithDifficulty('Long', difficulty: 1),
      WordWithDifficulty('Court', difficulty: 1),
      WordWithDifficulty('Large', difficulty: 1),
      WordWithDifficulty('Étroit', difficulty: 2),
      WordWithDifficulty('Épais', difficulty: 2),
      WordWithDifficulty('Fin', difficulty: 1),
      WordWithDifficulty('Mince', difficulty: 1),
      WordWithDifficulty('Gros', difficulty: 1),
      WordWithDifficulty('Maigre', difficulty: 1),
      WordWithDifficulty('Lourd', difficulty: 1),
      WordWithDifficulty('Léger', difficulty: 1),
      WordWithDifficulty('Profond', difficulty: 2),
      WordWithDifficulty('Superficiel', difficulty: 3),
      WordWithDifficulty('Plat', difficulty: 1),
      WordWithDifficulty('Bombé', difficulty: 2),
      WordWithDifficulty('Creux', difficulty: 2),
      WordWithDifficulty('Plein', difficulty: 1),
      WordWithDifficulty('Vide', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - VERBES DE MOUVEMENT
      // ============================================

      // MOUVEMENT - Facile
      WordWithDifficulty('Avancer', difficulty: 1),
      WordWithDifficulty('Reculer', difficulty: 1),
      WordWithDifficulty('Monter', difficulty: 1),
      WordWithDifficulty('Descendre', difficulty: 1),
      WordWithDifficulty('Entrer', difficulty: 1),
      WordWithDifficulty('Sortir', difficulty: 1),
      WordWithDifficulty('Partir', difficulty: 1),
      WordWithDifficulty('Arriver', difficulty: 1),
      WordWithDifficulty('Venir', difficulty: 1),
      WordWithDifficulty('Aller', difficulty: 1),
      WordWithDifficulty('Revenir', difficulty: 1),
      WordWithDifficulty('Repartir', difficulty: 2),
      WordWithDifficulty('Traverser', difficulty: 1),
      WordWithDifficulty('Passer', difficulty: 1),
      WordWithDifficulty('Contourner', difficulty: 2),
      WordWithDifficulty('Longer', difficulty: 2),
      WordWithDifficulty('Suivre', difficulty: 1),
      WordWithDifficulty('Précéder', difficulty: 2),
      WordWithDifficulty('Accompagner', difficulty: 2),
      WordWithDifficulty('Guider', difficulty: 2),

      // MOUVEMENT - Moyen
      WordWithDifficulty('Glisser', difficulty: 2),
      WordWithDifficulty('Rouler', difficulty: 1),
      WordWithDifficulty('Déraper', difficulty: 2),
      WordWithDifficulty('Patiner', difficulty: 2),
      WordWithDifficulty('Flotter', difficulty: 2),
      WordWithDifficulty('Couler', difficulty: 2),
      WordWithDifficulty('Plonger', difficulty: 2),
      WordWithDifficulty('Émerger', difficulty: 3),
      WordWithDifficulty('Surgir', difficulty: 2),
      WordWithDifficulty('Jaillir', difficulty: 3),
      WordWithDifficulty('Bondir', difficulty: 2),
      WordWithDifficulty('Rebondir', difficulty: 2),
      WordWithDifficulty('Voler', difficulty: 1),
      WordWithDifficulty('Planer', difficulty: 2),
      WordWithDifficulty('Atterrir', difficulty: 2),
      WordWithDifficulty('Décoller', difficulty: 2),
      WordWithDifficulty('Se pencher', difficulty: 2),
      WordWithDifficulty('Se redresser', difficulty: 2),
      WordWithDifficulty('Se courber', difficulty: 2),
      WordWithDifficulty('Se plier', difficulty: 2),
      WordWithDifficulty('S\'étirer', difficulty: 2),
      WordWithDifficulty('Se contracter', difficulty: 3),
      WordWithDifficulty('Pivoter', difficulty: 2),
      WordWithDifficulty('Tournoyer', difficulty: 2),
      WordWithDifficulty('Virevolter', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - CONTRAIRES ET OPPOSÉS
      // ============================================

      // CONTRAIRES - Facile
      WordWithDifficulty('Début', difficulty: 1),
      WordWithDifficulty('Entrée', difficulty: 1),
      WordWithDifficulty('Sortie', difficulty: 1),
      WordWithDifficulty('Arrivée', difficulty: 1),
      WordWithDifficulty('Départ', difficulty: 1),
      WordWithDifficulty('Naissance', difficulty: 1),
      WordWithDifficulty('Mort', difficulty: 1),
      WordWithDifficulty('Vie', difficulty: 1),
      WordWithDifficulty('Santé', difficulty: 1),
      WordWithDifficulty('Maladie', difficulty: 1),
      WordWithDifficulty('Richesse', difficulty: 2),
      WordWithDifficulty('Pauvreté', difficulty: 2),
      WordWithDifficulty('Abondance', difficulty: 2),
      WordWithDifficulty('Pénurie', difficulty: 3),
      WordWithDifficulty('Présence', difficulty: 2),
      WordWithDifficulty('Absence', difficulty: 2),
      WordWithDifficulty('Réalité', difficulty: 2),
      WordWithDifficulty('Fiction', difficulty: 2),
      WordWithDifficulty('Mensonge', difficulty: 1),
      WordWithDifficulty('Ordre', difficulty: 1),
      WordWithDifficulty('Désordre', difficulty: 2),
      WordWithDifficulty('Chaos', difficulty: 2),
      WordWithDifficulty('Harmonie', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - EXPRESSIONS TEMPORELLES
      // ============================================

      // TEMPS - Facile
      WordWithDifficulty('Avant', difficulty: 1),
      WordWithDifficulty('Après', difficulty: 1),
      WordWithDifficulty('Pendant', difficulty: 1),
      WordWithDifficulty('Durant', difficulty: 2),
      WordWithDifficulty('Depuis', difficulty: 1),
      WordWithDifficulty('Jusqu\'à', difficulty: 1),
      WordWithDifficulty('Bientôt', difficulty: 1),
      WordWithDifficulty('Maintenant', difficulty: 1),
      WordWithDifficulty('Récemment', difficulty: 2),
      WordWithDifficulty('Autrefois', difficulty: 2),
      WordWithDifficulty('Jadis', difficulty: 3),
      WordWithDifficulty('Naguère', difficulty: 3),
      WordWithDifficulty('Désormais', difficulty: 2),
      WordWithDifficulty('Dorénavant', difficulty: 3),
      WordWithDifficulty('Immédiatement', difficulty: 2),
      WordWithDifficulty('Instantanément', difficulty: 3),
      WordWithDifficulty('Progressivement', difficulty: 2),
      WordWithDifficulty('Graduellement', difficulty: 3),
      WordWithDifficulty('Soudainement', difficulty: 2),
      WordWithDifficulty('Brusquement', difficulty: 2),

      // ============================================
      // FIN ENRICHISSEMENT DICTIONNAIRE
      // ============================================

  ],
);
