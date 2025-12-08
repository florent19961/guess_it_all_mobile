import 'dart:math';

class WordWithDifficulty {
  final String word;
  final int difficulty; // 1=facile, 2=moyen, 3=difficile

  const WordWithDifficulty(this.word, {this.difficulty = 2});
}

class WordCategory {
  final String id;
  final String name;
  final String icon;
  final List<WordWithDifficulty> words;

  const WordCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.words,
  });
}

// ============================================================================
// CATÉGORIES DE MOTS
// ============================================================================

final Map<String, WordCategory> wordCategories = {
  // ==========================================================================
  // 7ÈME ART (Films, Séries, Disney, Animation, Manga)
  // ==========================================================================
  '7eme_art': WordCategory(
    id: '7eme_art',
    name: '7ème Art',
    icon: '🎬',
    words: const [
      // FILMS CLASSIQUES - Facile
      WordWithDifficulty('Titanic', difficulty: 1),
      WordWithDifficulty('Avatar', difficulty: 1),
      WordWithDifficulty('Star Wars', difficulty: 1),
      WordWithDifficulty('Jurassic Park', difficulty: 1),
      WordWithDifficulty('Le Roi Lion', difficulty: 1),
      WordWithDifficulty('Harry Potter', difficulty: 1),
      WordWithDifficulty('Forrest Gump', difficulty: 2),
      WordWithDifficulty('Retour vers le futur', difficulty: 2),
      WordWithDifficulty('Indiana Jones', difficulty: 1),
      WordWithDifficulty('Pirates des Caraïbes', difficulty: 1),
      WordWithDifficulty('Transformers', difficulty: 2),
      WordWithDifficulty('Fast and Furious', difficulty: 1),
      WordWithDifficulty('Mission Impossible', difficulty: 1),
      WordWithDifficulty('James Bond', difficulty: 1),
      WordWithDifficulty('La La Land', difficulty: 2),
      WordWithDifficulty('E.T.', difficulty: 2),
      WordWithDifficulty('Les Dents de la Mer', difficulty: 1),
      WordWithDifficulty('Ghostbusters', difficulty: 2),
      WordWithDifficulty('King Kong', difficulty: 2),
      WordWithDifficulty('Godzilla', difficulty: 2),

      // FILMS CLASSIQUES - Moyen
      WordWithDifficulty('Le Parrain', difficulty: 2),
      WordWithDifficulty('Matrix', difficulty: 2),
      WordWithDifficulty('Inception', difficulty: 2),
      WordWithDifficulty('Gladiator', difficulty: 2),
      WordWithDifficulty('Le Seigneur des Anneaux', difficulty: 1),
      WordWithDifficulty('Pulp Fiction', difficulty: 2),
      WordWithDifficulty('Terminator', difficulty: 2),
      WordWithDifficulty('Alien', difficulty: 2),
      WordWithDifficulty('Rocky', difficulty: 2),
      WordWithDifficulty('Shrek', difficulty: 2),
      WordWithDifficulty('Interstellar', difficulty: 2),
      WordWithDifficulty('Top Gun', difficulty: 2),
      WordWithDifficulty('Le Loup de Wall Street', difficulty: 2),
      WordWithDifficulty('Gravity', difficulty: 2),
      WordWithDifficulty('Dune', difficulty: 2),
      WordWithDifficulty('Blade Runner', difficulty: 3),
      WordWithDifficulty('Mad Max', difficulty: 2),
      WordWithDifficulty('Apocalypse Now', difficulty: 2),
      WordWithDifficulty('Scarface', difficulty: 2),
      WordWithDifficulty('Taxi Driver', difficulty: 2),
      WordWithDifficulty('Reservoir Dogs', difficulty: 2),
      WordWithDifficulty('Kill Bill', difficulty: 2),
      WordWithDifficulty('Django Unchained', difficulty: 2),
      WordWithDifficulty('Le Prestige', difficulty: 2),

      // FILMS CLASSIQUES - Difficile
      WordWithDifficulty('Le Silence des Agneaux', difficulty: 3),
      WordWithDifficulty('Les Évadés', difficulty: 3),
      WordWithDifficulty('La Liste de Schindler', difficulty: 3),
      WordWithDifficulty('Il faut sauver le soldat Ryan', difficulty: 3),
      WordWithDifficulty('Fight Club', difficulty: 3),
      WordWithDifficulty('Seven', difficulty: 3),
      WordWithDifficulty('Shutter Island', difficulty: 3),
      WordWithDifficulty('The Truman Show', difficulty: 3),
      WordWithDifficulty('Eternal Sunshine', difficulty: 3),
      WordWithDifficulty('Whiplash', difficulty: 3),
      WordWithDifficulty('Gone Girl', difficulty: 3),
      WordWithDifficulty('No Country for Old Men', difficulty: 3),
      WordWithDifficulty('There Will Be Blood', difficulty: 3),
      WordWithDifficulty('2001 L\'Odyssée de l\'espace', difficulty: 3),
      WordWithDifficulty('Vol au-dessus d\'un nid de coucou', difficulty: 3),
      WordWithDifficulty('Un Américain bien tranquille', difficulty: 3),
      WordWithDifficulty('La Vie est belle', difficulty: 3),
      WordWithDifficulty('Le Pont de la rivière Kwaï', difficulty: 3),
      WordWithDifficulty('Lawrence d\'Arabie', difficulty: 3),
      WordWithDifficulty('Citizen Kane', difficulty: 3),

      // SUPER-HÉROS - Facile
      WordWithDifficulty('Batman', difficulty: 1),
      WordWithDifficulty('Superman', difficulty: 1),
      WordWithDifficulty('Spider-Man', difficulty: 1),
      WordWithDifficulty('Iron Man', difficulty: 2),
      WordWithDifficulty('Avengers', difficulty: 2),
      WordWithDifficulty('Thor', difficulty: 2),
      WordWithDifficulty('Hulk', difficulty: 1),
      WordWithDifficulty('X-Men', difficulty: 2),
      WordWithDifficulty('Les Gardiens de la Galaxie', difficulty: 2),
      WordWithDifficulty('Ant-Man', difficulty: 3),

      // SUPER-HÉROS - Moyen
      WordWithDifficulty('Black Panther', difficulty: 2),
      WordWithDifficulty('Joker', difficulty: 2),
      WordWithDifficulty('Captain America', difficulty: 2),
      WordWithDifficulty('Wonder Woman', difficulty: 2),
      WordWithDifficulty('Doctor Strange', difficulty: 2),
      WordWithDifficulty('Deadpool', difficulty: 3),
      WordWithDifficulty('Black Widow', difficulty: 2),
      WordWithDifficulty('Aquaman', difficulty: 2),
      WordWithDifficulty('Shazam', difficulty: 2),
      WordWithDifficulty('Venom', difficulty: 2),
      WordWithDifficulty('Eternals', difficulty: 2),

      // SUPER-HÉROS - Difficile
      WordWithDifficulty('Batman : The Dark Knight', difficulty: 2),
      WordWithDifficulty('Logan', difficulty: 3),
      WordWithDifficulty('Watchmen', difficulty: 3),
      WordWithDifficulty('V pour Vendetta', difficulty: 3),
      WordWithDifficulty('Kick-Ass', difficulty: 3),
      WordWithDifficulty('Hellboy', difficulty: 3),

      // DISNEY / PIXAR - Facile
      WordWithDifficulty('La Reine des Neiges', difficulty: 1),
      WordWithDifficulty('Toy Story', difficulty: 1),
      WordWithDifficulty('Nemo', difficulty: 2),
      WordWithDifficulty('Cendrillon', difficulty: 1),
      WordWithDifficulty('Aladdin', difficulty: 1),
      WordWithDifficulty('Vaiana', difficulty: 2),
      WordWithDifficulty('Raiponce', difficulty: 2),
      WordWithDifficulty('Mulan', difficulty: 1),
      WordWithDifficulty('La Belle et la Bête', difficulty: 1),
      WordWithDifficulty('Pocahontas', difficulty: 1),
      WordWithDifficulty('Cars', difficulty: 1),
      WordWithDifficulty('Blanche-Neige', difficulty: 1),
      WordWithDifficulty('La Petite Sirène', difficulty: 1),
      WordWithDifficulty('Dumbo', difficulty: 1),
      WordWithDifficulty('Bambi', difficulty: 1),

      // DISNEY / PIXAR - Moyen
      WordWithDifficulty('Ratatouille', difficulty: 2),
      WordWithDifficulty('Vice-Versa', difficulty: 2),
      WordWithDifficulty('Coco', difficulty: 2),
      WordWithDifficulty('Wall-E', difficulty: 2),
      WordWithDifficulty('Monstres et Cie', difficulty: 2),
      WordWithDifficulty('Les Indestructibles', difficulty: 2),
      WordWithDifficulty('Rebelle', difficulty: 2),
      WordWithDifficulty('Encanto', difficulty: 3),
      WordWithDifficulty('Zootopie', difficulty: 2),
      WordWithDifficulty('Là-haut', difficulty: 2),
      WordWithDifficulty('Dory', difficulty: 3),
      WordWithDifficulty('Luca', difficulty: 2),
      WordWithDifficulty('Alerte Rouge', difficulty: 3),
      WordWithDifficulty('Strange World', difficulty: 3),

      // DISNEY / PIXAR - Difficile
      WordWithDifficulty('La Princesse et la Grenouille', difficulty: 3),
      WordWithDifficulty('Atlantide', difficulty: 3),
      WordWithDifficulty('Hercule', difficulty: 2),
      WordWithDifficulty('Tarzan', difficulty: 2),
      WordWithDifficulty('Soul', difficulty: 3),
      WordWithDifficulty('Rox et Rouky', difficulty: 3),
      WordWithDifficulty('Dinosaure', difficulty: 2),
      WordWithDifficulty('Kuzco', difficulty: 3),
      WordWithDifficulty('La Planète au Trésor', difficulty: 3),
      WordWithDifficulty('Frère des Ours', difficulty: 3),

      // ANIMATION NON-DISNEY - Facile
      WordWithDifficulty('Kung Fu Panda', difficulty: 1),
      WordWithDifficulty('Madagascar', difficulty: 1),
      WordWithDifficulty('Les Minions', difficulty: 2),
      WordWithDifficulty('Moi Moche et Méchant', difficulty: 1),
      WordWithDifficulty('L\'Âge de Glace', difficulty: 1),
      WordWithDifficulty('Shrek', difficulty: 1),
      WordWithDifficulty('Le Chat Potté', difficulty: 2),
      WordWithDifficulty('Les Trolls', difficulty: 2),
      WordWithDifficulty('Rio', difficulty: 2),

      // ANIMATION NON-DISNEY - Moyen
      WordWithDifficulty('Dragons', difficulty: 2),
      WordWithDifficulty('Lego Movie', difficulty: 3),
      WordWithDifficulty('Les Croods', difficulty: 3),
      WordWithDifficulty('Boss Baby', difficulty: 3),
      WordWithDifficulty('Wallace et Gromit', difficulty: 2),
      WordWithDifficulty('Chicken Run', difficulty: 3),
      WordWithDifficulty('Tempête de boulettes géantes', difficulty: 3),

      // ANIMATION NON-DISNEY - Difficile
      WordWithDifficulty('Le Voyage de Chihiro', difficulty: 2),
      WordWithDifficulty('Mon Voisin Totoro', difficulty: 3),
      WordWithDifficulty('Princesse Mononoké', difficulty: 3),
      WordWithDifficulty('Le Château Ambulant', difficulty: 3),
      WordWithDifficulty('Ponyo sur la Falaise', difficulty: 3),
      WordWithDifficulty('Porco Rosso', difficulty: 3),

      // SÉRIES - Facile
      WordWithDifficulty('Friends', difficulty: 1),
      WordWithDifficulty('Game of Thrones', difficulty: 1),
      WordWithDifficulty('Stranger Things', difficulty: 2),
      WordWithDifficulty('La Casa de Papel', difficulty: 2),
      WordWithDifficulty('The Walking Dead', difficulty: 2),
      WordWithDifficulty('Grey\'s Anatomy', difficulty: 1),
      WordWithDifficulty('How I Met Your Mother', difficulty: 2),
      WordWithDifficulty('The Big Bang Theory', difficulty: 2),
      WordWithDifficulty('Vikings', difficulty: 2),
      WordWithDifficulty('Lupin', difficulty: 2),

      // SÉRIES - Moyen
      WordWithDifficulty('Breaking Bad', difficulty: 2),
      WordWithDifficulty('Peaky Blinders', difficulty: 2),
      WordWithDifficulty('Narcos', difficulty: 2),
      WordWithDifficulty('Black Mirror', difficulty: 2),
      WordWithDifficulty('Sherlock', difficulty: 2),
      WordWithDifficulty('Squid Game', difficulty: 2),
      WordWithDifficulty('Wednesday', difficulty: 2),
      WordWithDifficulty('The Witcher', difficulty: 2),
      WordWithDifficulty('The Crown', difficulty: 2),
      WordWithDifficulty('Bridgerton', difficulty: 2),
      WordWithDifficulty('Emily in Paris', difficulty: 2),
      WordWithDifficulty('Succession', difficulty: 3),
      WordWithDifficulty('The Mandalorian', difficulty: 3),
      WordWithDifficulty('The Last of Us', difficulty: 2),
      WordWithDifficulty('Westworld', difficulty: 2),
      WordWithDifficulty('The Boys', difficulty: 2),

      // SÉRIES - Difficile
      WordWithDifficulty('The Office', difficulty: 3),
      WordWithDifficulty('Lost', difficulty: 3),
      WordWithDifficulty('Prison Break', difficulty: 3),
      WordWithDifficulty('Dexter', difficulty: 3),
      WordWithDifficulty('House', difficulty: 3),
      WordWithDifficulty('Better Call Saul', difficulty: 3),
      WordWithDifficulty('Ozark', difficulty: 3),
      WordWithDifficulty('True Detective', difficulty: 3),
      WordWithDifficulty('Fargo', difficulty: 3),
      WordWithDifficulty('The Wire', difficulty: 3),
      WordWithDifficulty('The Sopranos', difficulty: 3),
      WordWithDifficulty('Mad Men', difficulty: 3),
      WordWithDifficulty('Six Feet Under', difficulty: 3),
      WordWithDifficulty('Fleabag', difficulty: 3),

      // FILMS FRANÇAIS - Facile
      WordWithDifficulty('Intouchables', difficulty: 1),
      WordWithDifficulty('Taxi', difficulty: 1),
      WordWithDifficulty('Astérix et Obélix Mission Cléopâtre', difficulty: 1),
      WordWithDifficulty('Les Trois Frères', difficulty: 3),

      // FILMS FRANÇAIS - Moyen
      WordWithDifficulty('Amélie Poulain', difficulty: 2),
      WordWithDifficulty('Les Choristes', difficulty: 2),
      WordWithDifficulty('Le Fabuleux Destin d\'Amélie Poulain', difficulty: 2),
      WordWithDifficulty('OSS 117', difficulty: 2),
      WordWithDifficulty('Qu\'est-ce qu\'on a fait au Bon Dieu', difficulty: 2),
      WordWithDifficulty('La Famille Bélier', difficulty: 2),
      WordWithDifficulty('Le Prénom', difficulty: 2),
      WordWithDifficulty('Les Tuche', difficulty: 2),

      // FILMS FRANÇAIS - Difficile
      WordWithDifficulty('La Haine', difficulty: 3),
      WordWithDifficulty('Le Dîner de Cons', difficulty: 3),
      WordWithDifficulty('Bienvenue chez les Ch\'tis', difficulty: 3),
      WordWithDifficulty('Les Visiteurs', difficulty: 2),
      WordWithDifficulty('Le Grand Bleu', difficulty: 2),
      WordWithDifficulty('Léon', difficulty: 2),
      WordWithDifficulty('Nikita', difficulty: 3),
      WordWithDifficulty('La Boum', difficulty: 2),
      WordWithDifficulty('Les Bronzés', difficulty: 2),
      WordWithDifficulty('Le Père Noël est une ordure', difficulty: 3),

      // MANGA/ANIME - Facile
      WordWithDifficulty('Naruto', difficulty: 1),
      WordWithDifficulty('Dragon Ball', difficulty: 1),
      WordWithDifficulty('One Piece', difficulty: 1),
      WordWithDifficulty('Pokémon', difficulty: 1),
      WordWithDifficulty('Sailor Moon', difficulty: 3),
      WordWithDifficulty('Olive et Tom', difficulty: 1),
      WordWithDifficulty('Les Chevaliers du Zodiaque', difficulty: 3),

      // MANGA/ANIME - Moyen
      WordWithDifficulty('L\'Attaque des Titans', difficulty: 2),
      WordWithDifficulty('Death Note', difficulty: 2),
      WordWithDifficulty('Demon Slayer', difficulty: 2),
      WordWithDifficulty('My Hero Academia', difficulty: 3),
      WordWithDifficulty('One Punch Man', difficulty: 3),
      WordWithDifficulty('Fairy Tail', difficulty: 3),
      WordWithDifficulty('Black Clover', difficulty: 3),
      WordWithDifficulty('Bleach', difficulty: 3),
      WordWithDifficulty('Fullmetal Alchemist', difficulty: 3),
      WordWithDifficulty('Sword Art Online', difficulty: 3),

      // MANGA/ANIME - Difficile
      WordWithDifficulty('Hunter x Hunter', difficulty: 2),
      WordWithDifficulty('Jujutsu Kaisen', difficulty: 3),
      WordWithDifficulty('Tokyo Ghoul', difficulty: 3),
      WordWithDifficulty('Vinland Saga', difficulty: 3),

      // PERSONNAGES DE FILMS/SÉRIES - Facile
      WordWithDifficulty('Mickey Mouse', difficulty: 1),
      WordWithDifficulty('Donald Duck', difficulty: 1),
      WordWithDifficulty('Elsa', difficulty: 3),
      WordWithDifficulty('Simba', difficulty: 1),
      WordWithDifficulty('Woody', difficulty: 2),
      WordWithDifficulty('Buzz l\'Éclair', difficulty: 1),
      WordWithDifficulty('Shrek', difficulty: 1),
      WordWithDifficulty('Dory', difficulty: 2),
      WordWithDifficulty('Olaf', difficulty: 2),
      WordWithDifficulty('Maui', difficulty: 3),
      WordWithDifficulty('Anna', difficulty: 3),

      // PERSONNAGES DE FILMS/SÉRIES - Moyen
      WordWithDifficulty('Dark Vador', difficulty: 1),
      WordWithDifficulty('Voldemort', difficulty: 1),
      WordWithDifficulty('Thanos', difficulty: 3),
      WordWithDifficulty('Sauron', difficulty: 2),
      WordWithDifficulty('Gandalf', difficulty: 2),
      WordWithDifficulty('Frodon', difficulty: 2),
      WordWithDifficulty('Hermione', difficulty: 2),
      WordWithDifficulty('Ron Weasley', difficulty: 2),
      WordWithDifficulty('Dumbledore', difficulty: 2),
      WordWithDifficulty('Severus Rogue', difficulty: 2),
      WordWithDifficulty('Jack Sparrow', difficulty: 2),
      WordWithDifficulty('Tony Stark', difficulty: 3),
      WordWithDifficulty('Peter Parker', difficulty: 3),
      WordWithDifficulty('Bruce Wayne', difficulty: 2),

      // PERSONNAGES DE FILMS/SÉRIES - Difficile
      WordWithDifficulty('Hannibal Lecter', difficulty: 3),
      WordWithDifficulty('Don Corleone', difficulty: 3),

      // DESSINS ANIMÉS TV - Facile
      WordWithDifficulty('Bob l\'éponge', difficulty: 1),
      WordWithDifficulty('Les Simpson', difficulty: 1),
      WordWithDifficulty('Scooby-Doo', difficulty: 1),
      WordWithDifficulty('Tom et Jerry', difficulty: 1),
      WordWithDifficulty('Dora l\'Exploratrice', difficulty: 1),
      WordWithDifficulty('Peppa Pig', difficulty: 2),
      WordWithDifficulty('Pat Patrouille', difficulty: 3),
      WordWithDifficulty('Les Télétubbies', difficulty: 1),

      // DESSINS ANIMÉS TV - Moyen
      WordWithDifficulty('Rick et Morty', difficulty: 2),
      WordWithDifficulty('South Park', difficulty: 2),
      WordWithDifficulty('Totally Spies', difficulty: 2),
      WordWithDifficulty('Code Lyoko', difficulty: 2),
      WordWithDifficulty('Avatar le dernier maître de l\'air', difficulty: 3),

      // DESSINS ANIMÉS TV - Difficile
      WordWithDifficulty('Ben 10', difficulty: 3),
      WordWithDifficulty('Inspecteur Gadget', difficulty: 3),
      WordWithDifficulty('Il était une fois la vie', difficulty: 3),
      WordWithDifficulty('Il était une fois l\'homme', difficulty: 3),
      WordWithDifficulty('Les Mystérieuses Cités d\'Or', difficulty: 3),
      WordWithDifficulty('Wakfu', difficulty: 3),
      WordWithDifficulty('Oggy et les Cafards', difficulty: 3),
      WordWithDifficulty('Les zinzins de l\'espace', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // GÉOGRAPHIE (Pays, Villes, Fleuves, Régions, Monuments)
  // ==========================================================================
  'geographie': WordCategory(
    id: 'geographie',
    name: 'Géographie',
    icon: '🌍',
    words: const [
      // PAYS EUROPE - Facile
      WordWithDifficulty('France', difficulty: 1),
      WordWithDifficulty('Allemagne', difficulty: 1),
      WordWithDifficulty('Italie', difficulty: 1),
      WordWithDifficulty('Espagne', difficulty: 1),
      WordWithDifficulty('Royaume-Uni', difficulty: 1),
      WordWithDifficulty('Angleterre', difficulty: 1),
      WordWithDifficulty('Russie', difficulty: 1),

      // PAYS EUROPE - Moyen
      WordWithDifficulty('Belgique', difficulty: 2),
      WordWithDifficulty('Pays-Bas', difficulty: 2),
      WordWithDifficulty('Suisse', difficulty: 2),
      WordWithDifficulty('Portugal', difficulty: 2),
      WordWithDifficulty('Grèce', difficulty: 2),
      WordWithDifficulty('Pologne', difficulty: 2),
      WordWithDifficulty('Suède', difficulty: 2),
      WordWithDifficulty('Norvège', difficulty: 2),
      WordWithDifficulty('Irlande', difficulty: 2),
      WordWithDifficulty('Écosse', difficulty: 2),
      WordWithDifficulty('Turquie', difficulty: 2),
      WordWithDifficulty('Ukraine', difficulty: 2),

      // PAYS EUROPE - Difficile
      WordWithDifficulty('Autriche', difficulty: 3),
      WordWithDifficulty('Roumanie', difficulty: 3),
      WordWithDifficulty('Hongrie', difficulty: 3),
      WordWithDifficulty('Tchéquie', difficulty: 3),
      WordWithDifficulty('Finlande', difficulty: 3),
      WordWithDifficulty('Danemark', difficulty: 3),
      WordWithDifficulty('Islande', difficulty: 3),
      WordWithDifficulty('Croatie', difficulty: 3),
      WordWithDifficulty('Slovénie', difficulty: 3),
      WordWithDifficulty('Serbie', difficulty: 3),
      WordWithDifficulty('Bulgarie', difficulty: 3),
      WordWithDifficulty('Slovaquie', difficulty: 3),
      WordWithDifficulty('Estonie', difficulty: 3),
      WordWithDifficulty('Lettonie', difficulty: 3),
      WordWithDifficulty('Lituanie', difficulty: 3),
      WordWithDifficulty('Luxembourg', difficulty: 3),
      WordWithDifficulty('Malte', difficulty: 3),
      WordWithDifficulty('Chypre', difficulty: 3),

      // PAYS AMÉRIQUES - Facile
      WordWithDifficulty('États-Unis', difficulty: 1),
      WordWithDifficulty('Canada', difficulty: 1),
      WordWithDifficulty('Mexique', difficulty: 1),
      WordWithDifficulty('Brésil', difficulty: 1),

      // PAYS AMÉRIQUES - Moyen
      WordWithDifficulty('Argentine', difficulty: 2),
      WordWithDifficulty('Chili', difficulty: 2),
      WordWithDifficulty('Pérou', difficulty: 2),
      WordWithDifficulty('Colombie', difficulty: 2),
      WordWithDifficulty('Venezuela', difficulty: 2),
      WordWithDifficulty('Cuba', difficulty: 2),

      // PAYS AMÉRIQUES - Difficile
      WordWithDifficulty('Uruguay', difficulty: 3),
      WordWithDifficulty('Équateur', difficulty: 3),
      WordWithDifficulty('Bolivie', difficulty: 3),
      WordWithDifficulty('Paraguay', difficulty: 3),
      WordWithDifficulty('Costa Rica', difficulty: 3),
      WordWithDifficulty('Panama', difficulty: 3),
      WordWithDifficulty('Guatemala', difficulty: 3),

      // PAYS ASIE - Facile
      WordWithDifficulty('Chine', difficulty: 1),
      WordWithDifficulty('Japon', difficulty: 1),
      WordWithDifficulty('Inde', difficulty: 1),

      // PAYS ASIE - Moyen
      WordWithDifficulty('Corée du Sud', difficulty: 2),
      WordWithDifficulty('Thaïlande', difficulty: 2),
      WordWithDifficulty('Vietnam', difficulty: 2),
      WordWithDifficulty('Malaisie', difficulty: 2),
      WordWithDifficulty('Singapour', difficulty: 2),
      WordWithDifficulty('Indonésie', difficulty: 2),
      WordWithDifficulty('Philippines', difficulty: 2),
      WordWithDifficulty('Pakistan', difficulty: 2),
      WordWithDifficulty('Iran', difficulty: 2),
      WordWithDifficulty('Irak', difficulty: 2),

      // PAYS ASIE - Difficile
      WordWithDifficulty('Bangladesh', difficulty: 3),
      WordWithDifficulty('Sri Lanka', difficulty: 3),
      WordWithDifficulty('Népal', difficulty: 3),
      WordWithDifficulty('Birmanie', difficulty: 3),
      WordWithDifficulty('Cambodge', difficulty: 3),
      WordWithDifficulty('Laos', difficulty: 3),
      WordWithDifficulty('Mongolie', difficulty: 3),
      WordWithDifficulty('Kazakhstan', difficulty: 3),
      WordWithDifficulty('Ouzbékistan', difficulty: 3),
      WordWithDifficulty('Afghanistan', difficulty: 3),

      // PAYS AFRIQUE - Facile
      WordWithDifficulty('Égypte', difficulty: 1),
      WordWithDifficulty('Maroc', difficulty: 1),
      WordWithDifficulty('Afrique du Sud', difficulty: 1),

      // PAYS AFRIQUE - Moyen
      WordWithDifficulty('Algérie', difficulty: 2),
      WordWithDifficulty('Tunisie', difficulty: 2),
      WordWithDifficulty('Kenya', difficulty: 2),
      WordWithDifficulty('Nigeria', difficulty: 3),
      WordWithDifficulty('Éthiopie', difficulty: 3),
      WordWithDifficulty('Sénégal', difficulty: 2),
      WordWithDifficulty('Cameroun', difficulty: 2),

      // PAYS AFRIQUE - Difficile
      WordWithDifficulty('Libye', difficulty: 3),
      WordWithDifficulty('Ghana', difficulty: 3),
      WordWithDifficulty('Côte d\'Ivoire', difficulty: 3),
      WordWithDifficulty('Congo', difficulty: 3),
      WordWithDifficulty('Madagascar', difficulty: 2),
      WordWithDifficulty('Tanzanie', difficulty: 3),

      // PAYS OCÉANIE - Facile
      WordWithDifficulty('Australie', difficulty: 1),

      // PAYS OCÉANIE - Moyen
      WordWithDifficulty('Nouvelle-Zélande', difficulty: 2),

      // PAYS OCÉANIE - Difficile
      WordWithDifficulty('Fidji', difficulty: 3),
      WordWithDifficulty('Samoa', difficulty: 3),

      // VILLES FRANÇAISES - Facile
      WordWithDifficulty('Paris', difficulty: 1),
      WordWithDifficulty('Marseille', difficulty: 1),
      WordWithDifficulty('Lyon', difficulty: 1),
      WordWithDifficulty('Toulouse', difficulty: 1),
      WordWithDifficulty('Nice', difficulty: 1),
      WordWithDifficulty('Bordeaux', difficulty: 1),

      // VILLES FRANÇAISES - Moyen
      WordWithDifficulty('Nantes', difficulty: 2),
      WordWithDifficulty('Strasbourg', difficulty: 2),
      WordWithDifficulty('Lille', difficulty: 2),
      WordWithDifficulty('Rennes', difficulty: 2),
      WordWithDifficulty('Montpellier', difficulty: 2),
      WordWithDifficulty('Grenoble', difficulty: 2),

      // VILLES FRANÇAISES - Difficile
      WordWithDifficulty('Dijon', difficulty: 3),
      WordWithDifficulty('Angers', difficulty: 3),
      WordWithDifficulty('Brest', difficulty: 3),
      WordWithDifficulty('Le Havre', difficulty: 3),
      WordWithDifficulty('Reims', difficulty: 3),
      WordWithDifficulty('Saint-Étienne', difficulty: 3),

      // VILLES MONDIALES - Facile
      WordWithDifficulty('Londres', difficulty: 1),
      WordWithDifficulty('New York', difficulty: 1),
      WordWithDifficulty('Tokyo', difficulty: 1),
      WordWithDifficulty('Rome', difficulty: 1),
      WordWithDifficulty('Madrid', difficulty: 1),
      WordWithDifficulty('Berlin', difficulty: 1),
      WordWithDifficulty('Pékin', difficulty: 1),
      WordWithDifficulty('Los Angeles', difficulty: 1),
      WordWithDifficulty('Chicago', difficulty: 1),

      // VILLES MONDIALES - Moyen
      WordWithDifficulty('Moscou', difficulty: 2),
      WordWithDifficulty('Amsterdam', difficulty: 2),
      WordWithDifficulty('Barcelone', difficulty: 2),
      WordWithDifficulty('Lisbonne', difficulty: 2),
      WordWithDifficulty('Athènes', difficulty: 2),
      WordWithDifficulty('Vienne', difficulty: 2),
      WordWithDifficulty('Prague', difficulty: 2),
      WordWithDifficulty('Sydney', difficulty: 2),
      WordWithDifficulty('Rio de Janeiro', difficulty: 2),
      WordWithDifficulty('Le Caire', difficulty: 2),
      WordWithDifficulty('Istanbul', difficulty: 2),
      WordWithDifficulty('Dubaï', difficulty: 2),
      WordWithDifficulty('Mumbai', difficulty: 3),
      WordWithDifficulty('Shanghai', difficulty: 2),
      WordWithDifficulty('Hong Kong', difficulty: 2),
      WordWithDifficulty('Séoul', difficulty: 2),
      WordWithDifficulty('Bangkok', difficulty: 2),

      // VILLES MONDIALES - Difficile
      WordWithDifficulty('Budapest', difficulty: 3),
      WordWithDifficulty('Bucarest', difficulty: 3),
      WordWithDifficulty('Stockholm', difficulty: 3),
      WordWithDifficulty('Oslo', difficulty: 3),
      WordWithDifficulty('Helsinki', difficulty: 3),
      WordWithDifficulty('Copenhague', difficulty: 3),
      WordWithDifficulty('Varsovie', difficulty: 3),
      WordWithDifficulty('Cracovie', difficulty: 3),
      WordWithDifficulty('Naples', difficulty: 3),
      WordWithDifficulty('Florence', difficulty: 3),
      WordWithDifficulty('Venise', difficulty: 3),
      WordWithDifficulty('Milan', difficulty: 3),

      // MONUMENTS - Facile
      WordWithDifficulty('Tour Eiffel', difficulty: 1),
      WordWithDifficulty('Statue de la Liberté', difficulty: 1),
      WordWithDifficulty('Big Ben', difficulty: 1),
      WordWithDifficulty('Colisée', difficulty: 1),
      WordWithDifficulty('Tour de Pise', difficulty: 1),
      WordWithDifficulty('Notre-Dame de Paris', difficulty: 1),
      WordWithDifficulty('Arc de Triomphe', difficulty: 1),

      // MONUMENTS - Moyen
      WordWithDifficulty('Sagrada Familia', difficulty: 2),
      WordWithDifficulty('Taj Mahal', difficulty: 2),
      WordWithDifficulty('Grande Muraille de Chine', difficulty: 2),
      WordWithDifficulty('Pyramides de Gizeh', difficulty: 2),
      WordWithDifficulty('Christ Rédempteur', difficulty: 2),
      WordWithDifficulty('Opéra de Sydney', difficulty: 2),
      WordWithDifficulty('Empire State Building', difficulty: 2),
      WordWithDifficulty('Golden Gate', difficulty: 2),
      WordWithDifficulty('Buckingham Palace', difficulty: 2),

      // MONUMENTS - Difficile
      WordWithDifficulty('Château de Versailles', difficulty: 3),
      WordWithDifficulty('Mont Saint-Michel', difficulty: 3),
      WordWithDifficulty('Acropole', difficulty: 3),
      WordWithDifficulty('Parthénon', difficulty: 3),
      WordWithDifficulty('Stonehenge', difficulty: 3),
      WordWithDifficulty('Machu Picchu', difficulty: 3),
      WordWithDifficulty('Angkor Vat', difficulty: 3),
      WordWithDifficulty('Petra', difficulty: 3),
      WordWithDifficulty('Kremlin', difficulty: 3),
      WordWithDifficulty('Basilique Saint-Pierre', difficulty: 3),
      WordWithDifficulty('La cité interdite', difficulty: 3),

      // FLEUVES - Facile
      WordWithDifficulty('Seine', difficulty: 1),
      WordWithDifficulty('Nil', difficulty: 1),

      // FLEUVES - Moyen
      WordWithDifficulty('Amazone', difficulty: 2),
      WordWithDifficulty('Mississippi', difficulty: 2),
      WordWithDifficulty('Rhin', difficulty: 2),
      WordWithDifficulty('Danube', difficulty: 2),
      WordWithDifficulty('Tamise', difficulty: 2),
      WordWithDifficulty('Gange', difficulty: 2),

      // FLEUVES - Difficile
      WordWithDifficulty('Loire', difficulty: 3),
      WordWithDifficulty('Rhône', difficulty: 3),
      WordWithDifficulty('Garonne', difficulty: 3),
      WordWithDifficulty('Volga', difficulty: 3),

      // RÉGIONS FRANÇAISES - Facile
      WordWithDifficulty('Bretagne', difficulty: 1),
      WordWithDifficulty('Normandie', difficulty: 1),
      WordWithDifficulty('Provence', difficulty: 1),
      WordWithDifficulty('Alsace', difficulty: 1),
      WordWithDifficulty('Corse', difficulty: 1),

      // RÉGIONS FRANÇAISES - Moyen
      WordWithDifficulty('Occitanie', difficulty: 2),
      WordWithDifficulty('Nouvelle-Aquitaine', difficulty: 2),
      WordWithDifficulty('Grand Est', difficulty: 2),

      // RÉGIONS FRANÇAISES - Difficile
      WordWithDifficulty('Auvergne', difficulty: 3),
      WordWithDifficulty('Bourgogne', difficulty: 3),
      WordWithDifficulty('Aquitaine', difficulty: 3),
      WordWithDifficulty('Languedoc', difficulty: 3),
      WordWithDifficulty('Lorraine', difficulty: 3),
      WordWithDifficulty('Franche-Comté', difficulty: 3),
      WordWithDifficulty('Limousin', difficulty: 3),
      WordWithDifficulty('Poitou-Charentes', difficulty: 3),

      // OCÉANS ET MERS - Facile
      WordWithDifficulty('Océan Atlantique', difficulty: 1),
      WordWithDifficulty('Océan Pacifique', difficulty: 1),
      WordWithDifficulty('Mer Méditerranée', difficulty: 1),

      // OCÉANS ET MERS - Moyen
      WordWithDifficulty('Océan Indien', difficulty: 1),
      WordWithDifficulty('Mer des Caraïbes', difficulty: 2),
      WordWithDifficulty('Mer Rouge', difficulty: 2),
      WordWithDifficulty('Mer Noire', difficulty: 2),
      WordWithDifficulty('Mer Baltique', difficulty: 2),

      // OCÉANS ET MERS - Difficile
      WordWithDifficulty('Océan Arctique', difficulty: 3),
      WordWithDifficulty('Mer Caspienne', difficulty: 3),
      WordWithDifficulty('Mer du Nord', difficulty: 3),

      // ÉLÉMENTS NATURELS - Facile
      WordWithDifficulty('Sahara', difficulty: 1),
      WordWithDifficulty('Alpes', difficulty: 1),
      WordWithDifficulty('Everest', difficulty: 1),

      // ÉLÉMENTS NATURELS - Moyen
      WordWithDifficulty('Himalaya', difficulty: 1),
      WordWithDifficulty('Amazonie', difficulty: 1),
      WordWithDifficulty('Pyrénées', difficulty: 1),
      WordWithDifficulty('Cordillère des Andes', difficulty: 2),
      WordWithDifficulty('Kilimandjaro', difficulty: 2),

      // ÉLÉMENTS NATURELS - Difficile
      WordWithDifficulty('Grand Canyon', difficulty: 3),
      WordWithDifficulty('Chutes du Niagara', difficulty: 3),
      WordWithDifficulty('Grande Barrière de Corail', difficulty: 3),
      WordWithDifficulty('Mont Blanc', difficulty: 3),
      WordWithDifficulty('Vésuve', difficulty: 3),
      WordWithDifficulty('Etna', difficulty: 3),
      WordWithDifficulty('Yellowstone', difficulty: 3),
      WordWithDifficulty('Désert de Gobi', difficulty: 3),
      WordWithDifficulty('Patagonie', difficulty: 3),
      WordWithDifficulty('Antarctique', difficulty: 2),
    ],
  ),

  // ==========================================================================
  // NATURE (Animaux, Insectes, Plantes, Fleurs, Arbres, Fruits, Légumes)
  // ==========================================================================
  'nature': WordCategory(
    id: 'nature',
    name: 'Nature',
    icon: '🌿',
    words: const [
      // ANIMAUX SAUVAGES - Facile
      WordWithDifficulty('Lion', difficulty: 1),
      WordWithDifficulty('Tigre', difficulty: 1),
      WordWithDifficulty('Éléphant', difficulty: 1),
      WordWithDifficulty('Girafe', difficulty: 1),
      WordWithDifficulty('Zèbre', difficulty: 1),
      WordWithDifficulty('Ours', difficulty: 1),
      WordWithDifficulty('Loup', difficulty: 1),
      WordWithDifficulty('Renard', difficulty: 1),
      WordWithDifficulty('Singe', difficulty: 1),
      WordWithDifficulty('Crocodile', difficulty: 1),
      WordWithDifficulty('Serpent', difficulty: 1),
      WordWithDifficulty('Aigle', difficulty: 1),
      WordWithDifficulty('Pingouin', difficulty: 1),
      WordWithDifficulty('Kangourou', difficulty: 1),

      // ANIMAUX DOMESTIQUES - Facile
      WordWithDifficulty('Chat', difficulty: 1),
      WordWithDifficulty('Chien', difficulty: 1),
      WordWithDifficulty('Lapin', difficulty: 1),
      WordWithDifficulty('Cheval', difficulty: 1),
      WordWithDifficulty('Vache', difficulty: 1),
      WordWithDifficulty('Cochon', difficulty: 1),
      WordWithDifficulty('Mouton', difficulty: 1),
      WordWithDifficulty('Poule', difficulty: 1),
      WordWithDifficulty('Coq', difficulty: 1),
      WordWithDifficulty('Canard', difficulty: 1),
      WordWithDifficulty('Oie', difficulty: 2),
      WordWithDifficulty('Hamster', difficulty: 2),

      // ANIMAUX MARINS - Facile
      WordWithDifficulty('Dauphin', difficulty: 1),
      WordWithDifficulty('Requin', difficulty: 1),
      WordWithDifficulty('Baleine', difficulty: 1),
      WordWithDifficulty('Poisson', difficulty: 1),
      WordWithDifficulty('Crabe', difficulty: 1),
      WordWithDifficulty('Étoile de mer', difficulty: 1),

      // FÉLINS - Moyen
      WordWithDifficulty('Léopard', difficulty: 2),
      WordWithDifficulty('Panthère', difficulty: 2),
      WordWithDifficulty('Guépard', difficulty: 2),
      WordWithDifficulty('Lynx', difficulty: 2),
      WordWithDifficulty('Puma', difficulty: 2),

      // GRANDS MAMMIFÈRES - Moyen
      WordWithDifficulty('Rhinocéros', difficulty: 2),
      WordWithDifficulty('Hippopotame', difficulty: 2),
      WordWithDifficulty('Gorille', difficulty: 2),
      WordWithDifficulty('Chimpanzé', difficulty: 2),
      WordWithDifficulty('Orang-outan', difficulty: 2),
      WordWithDifficulty('Panda', difficulty: 2),
      WordWithDifficulty('Koala', difficulty: 2),
      WordWithDifficulty('Buffle', difficulty: 2),
      WordWithDifficulty('Bison', difficulty: 2),

      // ANIMAUX MARINS - Moyen
      WordWithDifficulty('Orque', difficulty: 2),
      WordWithDifficulty('Otarie', difficulty: 2),
      WordWithDifficulty('Phoque', difficulty: 2),
      WordWithDifficulty('Pieuvre', difficulty: 2),
      WordWithDifficulty('Méduse', difficulty: 2),
      WordWithDifficulty('Raie', difficulty: 2),
      WordWithDifficulty('Thon', difficulty: 2),
      WordWithDifficulty('Saumon', difficulty: 2),
      WordWithDifficulty('Tortue marine', difficulty: 2),

      // REPTILES - Moyen
      WordWithDifficulty('Caméléon', difficulty: 2),
      WordWithDifficulty('Iguane', difficulty: 2),
      WordWithDifficulty('Lézard', difficulty: 2),
      WordWithDifficulty('Tortue', difficulty: 2),
      WordWithDifficulty('Python', difficulty: 2),
      WordWithDifficulty('Cobra', difficulty: 2),

      // OISEAUX - Moyen
      WordWithDifficulty('Perroquet', difficulty: 2),
      WordWithDifficulty('Flamant rose', difficulty: 2),
      WordWithDifficulty('Autruche', difficulty: 2),
      WordWithDifficulty('Hibou', difficulty: 2),
      WordWithDifficulty('Chouette', difficulty: 2),
      WordWithDifficulty('Faucon', difficulty: 2),
      WordWithDifficulty('Vautour', difficulty: 2),
      WordWithDifficulty('Corbeau', difficulty: 2),
      WordWithDifficulty('Pie', difficulty: 2),
      WordWithDifficulty('Mouette', difficulty: 2),
      WordWithDifficulty('Cigogne', difficulty: 2),

      // PETITS MAMMIFÈRES - Moyen
      WordWithDifficulty('Écureuil', difficulty: 2),
      WordWithDifficulty('Hérisson', difficulty: 2),
      WordWithDifficulty('Castor', difficulty: 2),
      WordWithDifficulty('Taupe', difficulty: 2),
      WordWithDifficulty('Souris', difficulty: 2),
      WordWithDifficulty('Rat', difficulty: 2),

      // FÉLINS - Difficile
      WordWithDifficulty('Jaguar', difficulty: 3),

      // CANIDÉS - Difficile
      WordWithDifficulty('Fennec', difficulty: 3),
      WordWithDifficulty('Chacal', difficulty: 3),
      WordWithDifficulty('Coyote', difficulty: 3),
      WordWithDifficulty('Dingo', difficulty: 3),

      // HERBIVORES - Difficile
      WordWithDifficulty('Chameau', difficulty: 3),
      WordWithDifficulty('Dromadaire', difficulty: 3),
      WordWithDifficulty('Yak', difficulty: 3),
      WordWithDifficulty('Antilope', difficulty: 3),
      WordWithDifficulty('Gazelle', difficulty: 3),
      WordWithDifficulty('Cerf', difficulty: 2),
      WordWithDifficulty('Renne', difficulty: 2),
      WordWithDifficulty('Élan', difficulty: 3),

      // PRIMATES - Difficile
      WordWithDifficulty('Babouin', difficulty: 3),
      WordWithDifficulty('Ouistiti', difficulty: 3),
      WordWithDifficulty('Lémurien', difficulty: 3),
      WordWithDifficulty('Macaque', difficulty: 3),

      // ANIMAUX MARINS - Difficile
      WordWithDifficulty('Morse', difficulty: 3),
      WordWithDifficulty('Lamantin', difficulty: 3),
      WordWithDifficulty('Narval', difficulty: 3),
      WordWithDifficulty('Béluga', difficulty: 3),
      WordWithDifficulty('Calmar', difficulty: 3),
      WordWithDifficulty('Hippocampe', difficulty: 3),
      WordWithDifficulty('Murène', difficulty: 3),
      WordWithDifficulty('Barracuda', difficulty: 3),

      // REPTILES - Difficile
      WordWithDifficulty('Alligator', difficulty: 3),
      WordWithDifficulty('Anaconda', difficulty: 3),
      WordWithDifficulty('Varan', difficulty: 3),
      WordWithDifficulty('Gecko', difficulty: 3),
      WordWithDifficulty('Salamandre', difficulty: 3),

      // OISEAUX EXOTIQUES - Difficile
      WordWithDifficulty('Toucan', difficulty: 3),
      WordWithDifficulty('Pélican', difficulty: 3),
      WordWithDifficulty('Paon', difficulty: 3),
      WordWithDifficulty('Colibri', difficulty: 3),
      WordWithDifficulty('Condor', difficulty: 3),
      WordWithDifficulty('Albatros', difficulty: 3),
      WordWithDifficulty('Cacatoès', difficulty: 3),

      // PETITS MAMMIFÈRES - Difficile
      WordWithDifficulty('Loutre', difficulty: 3),
      WordWithDifficulty('Raton laveur', difficulty: 3),
      WordWithDifficulty('Blaireau', difficulty: 2),
      WordWithDifficulty('Belette', difficulty: 3),
      WordWithDifficulty('Hermine', difficulty: 3),
      WordWithDifficulty('Furet', difficulty: 3),

      // ANIMAUX D'AUSTRALIE - Difficile
      WordWithDifficulty('Wallaby', difficulty: 3),
      WordWithDifficulty('Wombat', difficulty: 3),
      WordWithDifficulty('Ornithorynque', difficulty: 3),
      WordWithDifficulty('Koala', difficulty: 3),
      WordWithDifficulty('Diable de Tasmanie', difficulty: 3),

      // INSECTES - Facile
      WordWithDifficulty('Papillon', difficulty: 1),
      WordWithDifficulty('Abeille', difficulty: 1),
      WordWithDifficulty('Fourmi', difficulty: 1),
      WordWithDifficulty('Coccinelle', difficulty: 1),
      WordWithDifficulty('Mouche', difficulty: 1),
      WordWithDifficulty('Moustique', difficulty: 1),
      WordWithDifficulty('Araignée', difficulty: 1),
      WordWithDifficulty('Guêpe', difficulty: 1),

      // INSECTES - Moyen
      WordWithDifficulty('Libellule', difficulty: 2),
      WordWithDifficulty('Sauterelle', difficulty: 2),
      WordWithDifficulty('Criquet', difficulty: 2),
      WordWithDifficulty('Cigale', difficulty: 2),
      WordWithDifficulty('Grillon', difficulty: 2),
      WordWithDifficulty('Bourdon', difficulty: 2),
      WordWithDifficulty('Frelon', difficulty: 2),
      WordWithDifficulty('Mille-pattes', difficulty: 2),

      // INSECTES - Difficile
      WordWithDifficulty('Scarabée', difficulty: 3),
      WordWithDifficulty('Mante religieuse', difficulty: 3),
      WordWithDifficulty('Phasme', difficulty: 3),
      WordWithDifficulty('Hanneton', difficulty: 3),
      WordWithDifficulty('Puceron', difficulty: 3),
      WordWithDifficulty('Termite', difficulty: 2),

      // PLANTES/FLEURS - Facile
      WordWithDifficulty('Rose', difficulty: 1),
      WordWithDifficulty('Tulipe', difficulty: 1),
      WordWithDifficulty('Marguerite', difficulty: 1),
      WordWithDifficulty('Tournesol', difficulty: 1),
      WordWithDifficulty('Muguet', difficulty: 1),
      WordWithDifficulty('Pensée', difficulty: 3),

      // PLANTES/FLEURS - Moyen
      WordWithDifficulty('Orchidée', difficulty: 2),
      WordWithDifficulty('Lavande', difficulty: 2),
      WordWithDifficulty('Jasmin', difficulty: 3),
      WordWithDifficulty('Pivoine', difficulty: 3),
      WordWithDifficulty('Coquelicot', difficulty: 2),
      WordWithDifficulty('Lilas', difficulty: 2),
      WordWithDifficulty('Hortensia', difficulty: 3),
      WordWithDifficulty('Géranium', difficulty: 3),
      WordWithDifficulty('Bégonia', difficulty: 3),
      WordWithDifficulty('Iris', difficulty: 3),

      // PLANTES/FLEURS - Difficile
      WordWithDifficulty('Narcisse', difficulty: 3),
      WordWithDifficulty('Jonquille', difficulty: 3),
      WordWithDifficulty('Dahlia', difficulty: 3),
      WordWithDifficulty('Glycine', difficulty: 3),
      WordWithDifficulty('Rhododendron', difficulty: 3),
      WordWithDifficulty('Camélia', difficulty: 3),
      WordWithDifficulty('Magnolia', difficulty: 3),
      WordWithDifficulty('Hibiscus', difficulty: 3),

      // ARBRES - Facile
      WordWithDifficulty('Chêne', difficulty: 1),
      WordWithDifficulty('Sapin', difficulty: 1),
      WordWithDifficulty('Pin', difficulty: 1),
      WordWithDifficulty('Palmier', difficulty: 1),
      WordWithDifficulty('Pommier', difficulty: 1),
      WordWithDifficulty('Cerisier', difficulty: 2),

      // ARBRES - Moyen
      WordWithDifficulty('Érable', difficulty: 2),
      WordWithDifficulty('Hêtre', difficulty: 2),
      WordWithDifficulty('Bouleau', difficulty: 2),
      WordWithDifficulty('Platane', difficulty: 2),
      WordWithDifficulty('Tilleul', difficulty: 2),
      WordWithDifficulty('Peuplier', difficulty: 2),
      WordWithDifficulty('Saule', difficulty: 2),
      WordWithDifficulty('Marronnier', difficulty: 2),

      // ARBRES - Difficile
      WordWithDifficulty('Séquoia', difficulty: 3),
      WordWithDifficulty('Baobab', difficulty: 3),
      WordWithDifficulty('Cyprès', difficulty: 3),
      WordWithDifficulty('Cèdre', difficulty: 3),
      WordWithDifficulty('Olivier', difficulty: 3),
      WordWithDifficulty('Eucalyptus', difficulty: 3),
      WordWithDifficulty('Acacia', difficulty: 3),
      WordWithDifficulty('Châtaignier', difficulty: 3),
      WordWithDifficulty('Noyer', difficulty: 3),

      // FRUITS - Facile
      WordWithDifficulty('Pomme', difficulty: 1),
      WordWithDifficulty('Banane', difficulty: 1),
      WordWithDifficulty('Orange', difficulty: 1),
      WordWithDifficulty('Fraise', difficulty: 1),
      WordWithDifficulty('Cerise', difficulty: 1),
      WordWithDifficulty('Raisin', difficulty: 1),
      WordWithDifficulty('Pêche', difficulty: 1),
      WordWithDifficulty('Poire', difficulty: 1),
      WordWithDifficulty('Kiwi', difficulty: 1),
      WordWithDifficulty('Ananas', difficulty: 1),
      WordWithDifficulty('Pastèque', difficulty: 1),
      WordWithDifficulty('Melon', difficulty: 1),
      WordWithDifficulty('Prune', difficulty: 1),

      // FRUITS - Moyen
      WordWithDifficulty('Abricot', difficulty: 2),
      WordWithDifficulty('Mangue', difficulty: 2),
      WordWithDifficulty('Citron', difficulty: 2),
      WordWithDifficulty('Pamplemousse', difficulty: 2),
      WordWithDifficulty('Framboise', difficulty: 2),
      WordWithDifficulty('Myrtille', difficulty: 2),
      WordWithDifficulty('Mûre', difficulty: 2),
      WordWithDifficulty('Nectarine', difficulty: 2),
      WordWithDifficulty('Mandarine', difficulty: 2),
      WordWithDifficulty('Clémentine', difficulty: 2),
      WordWithDifficulty('Figue', difficulty: 2),
      WordWithDifficulty('Datte', difficulty: 2),
      WordWithDifficulty('Avocat', difficulty: 2),

      // FRUITS - Difficile
      WordWithDifficulty('Grenade', difficulty: 3),
      WordWithDifficulty('Litchi', difficulty: 3),
      WordWithDifficulty('Papaye', difficulty: 3),
      WordWithDifficulty('Fruit de la passion', difficulty: 3),
      WordWithDifficulty('Goyave', difficulty: 3),
      WordWithDifficulty('Kumquat', difficulty: 3),
      WordWithDifficulty('Coing', difficulty: 3),
      WordWithDifficulty('Cassis', difficulty: 3),
      WordWithDifficulty('Groseille', difficulty: 3),

      // LÉGUMES - Facile
      WordWithDifficulty('Carotte', difficulty: 1),
      WordWithDifficulty('Tomate', difficulty: 1),
      WordWithDifficulty('Salade', difficulty: 1),
      WordWithDifficulty('Concombre', difficulty: 1),
      WordWithDifficulty('Pomme de terre', difficulty: 1),
      WordWithDifficulty('Oignon', difficulty: 1),
      WordWithDifficulty('Poivron', difficulty: 1),
      WordWithDifficulty('Radis', difficulty: 1),
      WordWithDifficulty('Maïs', difficulty: 1),

      // LÉGUMES - Moyen
      WordWithDifficulty('Courgette', difficulty: 2),
      WordWithDifficulty('Aubergine', difficulty: 2),
      WordWithDifficulty('Brocoli', difficulty: 2),
      WordWithDifficulty('Chou-fleur', difficulty: 2),
      WordWithDifficulty('Épinard', difficulty: 2),
      WordWithDifficulty('Haricot', difficulty: 2),
      WordWithDifficulty('Petit pois', difficulty: 2),
      WordWithDifficulty('Poireau', difficulty: 2),
      WordWithDifficulty('Céleri', difficulty: 2),
      WordWithDifficulty('Champignon', difficulty: 2),
      WordWithDifficulty('Chou', difficulty: 2),
      WordWithDifficulty('Courge', difficulty: 2),
      WordWithDifficulty('Citrouille', difficulty: 2),

      // LÉGUMES - Difficile
      WordWithDifficulty('Asperge', difficulty: 3),
      WordWithDifficulty('Artichaut', difficulty: 3),
      WordWithDifficulty('Betterave', difficulty: 3),
      WordWithDifficulty('Navet', difficulty: 3),
      WordWithDifficulty('Panais', difficulty: 3),
      WordWithDifficulty('Rutabaga', difficulty: 3),
      WordWithDifficulty('Topinambour', difficulty: 3),
      WordWithDifficulty('Endive', difficulty: 3),
      WordWithDifficulty('Fenouil', difficulty: 3),
      WordWithDifficulty('Salsifis', difficulty: 3),

      // PLATS - Facile
      WordWithDifficulty('Pizza', difficulty: 1),
      WordWithDifficulty('Burger', difficulty: 1),
      WordWithDifficulty('Pâtes', difficulty: 1),
      WordWithDifficulty('Tacos', difficulty: 1),
      WordWithDifficulty('Crêpe', difficulty: 1),
      WordWithDifficulty('Sandwich', difficulty: 1),
      WordWithDifficulty('Frites', difficulty: 1),
      WordWithDifficulty('Omelette', difficulty: 1),
      WordWithDifficulty('Salade', difficulty: 1),
      WordWithDifficulty('Soupe', difficulty: 1),

      // PLATS - Moyen
      WordWithDifficulty('Risotto', difficulty: 2),
      WordWithDifficulty('Paella', difficulty: 2),
      WordWithDifficulty('Sushi', difficulty: 2),
      WordWithDifficulty('Curry', difficulty: 2),
      WordWithDifficulty('Couscous', difficulty: 2),
      WordWithDifficulty('Raclette', difficulty: 2),
      WordWithDifficulty('Fondue', difficulty: 2),
      WordWithDifficulty('Lasagnes', difficulty: 2),
      WordWithDifficulty('Kebab', difficulty: 2),
      WordWithDifficulty('Nems', difficulty: 2),
      WordWithDifficulty('Fajitas', difficulty: 2),
      WordWithDifficulty('Burritos', difficulty: 2),
      WordWithDifficulty('Wrap', difficulty: 2),
      WordWithDifficulty('Poke bowl', difficulty: 2),

      // PLATS - Difficile
      WordWithDifficulty('Tajine', difficulty: 3),
      WordWithDifficulty('Tartiflette', difficulty: 3),
      WordWithDifficulty('Quiche', difficulty: 3),
      WordWithDifficulty('Gratin dauphinois', difficulty: 3),
      WordWithDifficulty('Ramen', difficulty: 3),
      WordWithDifficulty('Pot-au-feu', difficulty: 3),
      WordWithDifficulty('Blanquette de veau', difficulty: 3),
      WordWithDifficulty('Bœuf bourguignon', difficulty: 3),
      WordWithDifficulty('Cassoulet', difficulty: 3),
      WordWithDifficulty('Bouillabaisse', difficulty: 3),
      WordWithDifficulty('Choucroute', difficulty: 3),

      // PÂTISSERIE - Facile
      WordWithDifficulty('Gâteau', difficulty: 1),
      WordWithDifficulty('Tarte', difficulty: 1),
      WordWithDifficulty('Cookie', difficulty: 1),
      WordWithDifficulty('Gaufre', difficulty: 1),
      WordWithDifficulty('Glace', difficulty: 1),
      WordWithDifficulty('Bonbon', difficulty: 1),
      WordWithDifficulty('Chocolat', difficulty: 1),
      WordWithDifficulty('Croissant', difficulty: 1),
      WordWithDifficulty('Pain au chocolat', difficulty: 1),

      // PÂTISSERIE - Moyen
      WordWithDifficulty('Macaron', difficulty: 2),
      WordWithDifficulty('Éclair', difficulty: 2),
      WordWithDifficulty('Brownie', difficulty: 2),
      WordWithDifficulty('Cheesecake', difficulty: 2),
      WordWithDifficulty('Pancake', difficulty: 2),
      WordWithDifficulty('Muffin', difficulty: 2),
      WordWithDifficulty('Cupcake', difficulty: 2),
      WordWithDifficulty('Donut', difficulty: 2),
      WordWithDifficulty('Churros', difficulty: 2),
      WordWithDifficulty('Religieuse', difficulty: 2),
      WordWithDifficulty('Chausson aux pommes', difficulty: 2),

      // PÂTISSERIE - Difficile
      WordWithDifficulty('Mousse au chocolat', difficulty: 3),
      WordWithDifficulty('Crème brûlée', difficulty: 3),
      WordWithDifficulty('Tiramisu', difficulty: 3),
      WordWithDifficulty('Mille-feuille', difficulty: 3),
      WordWithDifficulty('Profiterole', difficulty: 3),
      WordWithDifficulty('Paris-Brest', difficulty: 3),
      WordWithDifficulty('Tarte Tatin', difficulty: 3),
      WordWithDifficulty('Opéra', difficulty: 3),
      WordWithDifficulty('Fraisier', difficulty: 3),
      WordWithDifficulty('Saint-Honoré', difficulty: 3),
      WordWithDifficulty('Forêt-Noire', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // MÉTIERS & SPORTS
  // ==========================================================================
  'metiers_sports': WordCategory(
    id: 'metiers_sports',
    name: 'Métiers & Sports',
    icon: '💼',
    words: const [
      // MÉTIERS SANTÉ - Facile
      WordWithDifficulty('Médecin', difficulty: 1),
      WordWithDifficulty('Infirmier', difficulty: 1),
      WordWithDifficulty('Dentiste', difficulty: 1),
      WordWithDifficulty('Pharmacien', difficulty: 1),

      // MÉTIERS SANTÉ - Moyen
      WordWithDifficulty('Chirurgien', difficulty: 2),
      WordWithDifficulty('Vétérinaire', difficulty: 2),
      WordWithDifficulty('Sage-femme', difficulty: 2),
      WordWithDifficulty('Ambulancier', difficulty: 2),
      WordWithDifficulty('Radiologue', difficulty: 2),

      // MÉTIERS SANTÉ - Difficile
      WordWithDifficulty('Kinésithérapeute', difficulty: 2),
      WordWithDifficulty('Ostéopathe', difficulty: 2),
      WordWithDifficulty('Psychologue', difficulty: 2),
      WordWithDifficulty('Cardiologue', difficulty: 2),
      WordWithDifficulty('Dermatologue', difficulty: 2),
      WordWithDifficulty('Ophtalmologue', difficulty: 2),
      WordWithDifficulty('Pédiatre', difficulty: 2),
      WordWithDifficulty('Anesthésiste', difficulty: 3),
      WordWithDifficulty('Orthophoniste', difficulty: 3),
      WordWithDifficulty('Podologue', difficulty: 2),

      // MÉTIERS ÉDUCATION - Facile
      WordWithDifficulty('Professeur', difficulty: 1),
      WordWithDifficulty('Instituteur', difficulty: 1),
      WordWithDifficulty('Éducateur', difficulty: 1),

      // MÉTIERS ÉDUCATION - Moyen
      WordWithDifficulty('Directeur d\'école', difficulty: 2),
      WordWithDifficulty('Psychologue scolaire', difficulty: 2),
      WordWithDifficulty('Bibliothécaire', difficulty: 2),

      // MÉTIERS SÉCURITÉ - Facile
      WordWithDifficulty('Pompier', difficulty: 1),
      WordWithDifficulty('Policier', difficulty: 1),
      WordWithDifficulty('Gendarme', difficulty: 1),

      // MÉTIERS SÉCURITÉ - Moyen
      WordWithDifficulty('Militaire', difficulty: 2),
      WordWithDifficulty('Agent de sécurité', difficulty: 3),
      WordWithDifficulty('Maître-chien', difficulty: 3),

      // MÉTIERS SÉCURITÉ - Difficile
      WordWithDifficulty('Démineur', difficulty: 3),
      WordWithDifficulty('Garde du corps', difficulty: 3),

      // MÉTIERS ALIMENTATION - Facile
      WordWithDifficulty('Boulanger', difficulty: 1),
      WordWithDifficulty('Cuisinier', difficulty: 1),
      WordWithDifficulty('Serveur', difficulty: 1),

      // MÉTIERS ALIMENTATION - Moyen
      WordWithDifficulty('Pâtissier', difficulty: 2),
      WordWithDifficulty('Boucher', difficulty: 1),
      WordWithDifficulty('Poissonnier', difficulty: 1),
      WordWithDifficulty('Sommelier', difficulty: 2),
      WordWithDifficulty('Barman', difficulty: 2),
      WordWithDifficulty('Chef cuisinier', difficulty: 2),

      // MÉTIERS ALIMENTATION - Difficile
      WordWithDifficulty('Fromager', difficulty: 2),
      WordWithDifficulty('Chocolatier', difficulty: 2),
      WordWithDifficulty('Glacier', difficulty: 2),
      WordWithDifficulty('Traiteur', difficulty: 2),

      // MÉTIERS ARTISANAT - Facile
      WordWithDifficulty('Coiffeur', difficulty: 1),
      WordWithDifficulty('Mécanicien', difficulty: 1),
      WordWithDifficulty('Menuisier', difficulty: 1),

      // MÉTIERS ARTISANAT - Moyen
      WordWithDifficulty('Électricien', difficulty: 1),
      WordWithDifficulty('Plombier', difficulty: 1),
      WordWithDifficulty('Maçon', difficulty: 2),
      WordWithDifficulty('Peintre', difficulty: 1),
      WordWithDifficulty('Jardinier', difficulty: 1),
      WordWithDifficulty('Carreleur', difficulty: 3),

      // MÉTIERS ARTISANAT - Difficile
      WordWithDifficulty('Ébéniste', difficulty: 3),
      WordWithDifficulty('Charpentier', difficulty: 3),
      WordWithDifficulty('Serrurier', difficulty: 2),
      WordWithDifficulty('Couvreur', difficulty: 3),
      WordWithDifficulty('Tapissier', difficulty: 3),
      WordWithDifficulty('Vitrier', difficulty: 3),
      WordWithDifficulty('Forgeron', difficulty: 3),

      // MÉTIERS TRANSPORT - Facile
      WordWithDifficulty('Chauffeur', difficulty: 1),
      WordWithDifficulty('Conducteur de bus', difficulty: 1),
      WordWithDifficulty('Pilote', difficulty: 1),

      // MÉTIERS TRANSPORT - Moyen
      WordWithDifficulty('Chauffeur de taxi', difficulty: 2),
      WordWithDifficulty('Conducteur de train', difficulty: 2),
      WordWithDifficulty('Hôtesse de l\'air', difficulty: 2),

      // MÉTIERS TRANSPORT - Difficile
      WordWithDifficulty('Contrôleur aérien', difficulty: 3),

      // MÉTIERS JURIDIQUE - Moyen
      WordWithDifficulty('Avocat', difficulty: 1),
      WordWithDifficulty('Juge', difficulty: 1),
      WordWithDifficulty('Commissaire de police', difficulty: 2),

      // MÉTIERS JURIDIQUE - Difficile
      WordWithDifficulty('Notaire', difficulty: 3),
      WordWithDifficulty('Huissier', difficulty: 3),
      WordWithDifficulty('Greffier', difficulty: 3),
      WordWithDifficulty('Magistrat', difficulty: 3),
      WordWithDifficulty('Procureur', difficulty: 3),

      // MÉTIERS CRÉATIFS - Moyen
      WordWithDifficulty('Architecte', difficulty: 2),
      WordWithDifficulty('Journaliste', difficulty: 2),
      WordWithDifficulty('Photographe', difficulty: 2),
      WordWithDifficulty('Designer', difficulty: 3),
      WordWithDifficulty('Graphiste', difficulty: 3),
      WordWithDifficulty('Musicien', difficulty: 1),
      WordWithDifficulty('Acteur', difficulty: 1),

      // MÉTIERS CRÉATIFS - Difficile
      WordWithDifficulty('Scénariste', difficulty: 3),
      WordWithDifficulty('Monteur', difficulty: 3),
      WordWithDifficulty('Ingénieur du son', difficulty: 3),
      WordWithDifficulty('Réalisateur', difficulty: 2),
      WordWithDifficulty('Illustrateur', difficulty: 3),

      // MÉTIERS TECH - Moyen
      WordWithDifficulty('Développeur', difficulty: 3),
      WordWithDifficulty('Informaticien', difficulty: 2),
      WordWithDifficulty('Webdesigner', difficulty: 3),

      // MÉTIERS TECH - Difficile
      WordWithDifficulty('Data scientist', difficulty: 3),
      WordWithDifficulty('Administrateur système', difficulty: 3),

      // MÉTIERS COMMERCE - Facile
      WordWithDifficulty('Vendeur', difficulty: 1),
      WordWithDifficulty('Caissier', difficulty: 1),

      // MÉTIERS COMMERCE - Moyen
      WordWithDifficulty('Comptable', difficulty: 2),
      WordWithDifficulty('Commercial', difficulty: 2),
      WordWithDifficulty('Agent immobilier', difficulty: 2),
      WordWithDifficulty('Banquier', difficulty: 1),

      // MÉTIERS COMMERCE - Difficile
      WordWithDifficulty('Expert-comptable', difficulty: 3),
      WordWithDifficulty('Commissaire aux comptes', difficulty: 3),
      WordWithDifficulty('Trader', difficulty: 3),

      // MÉTIERS AGRICULTURE - Moyen
      WordWithDifficulty('Agriculteur', difficulty: 1),
      WordWithDifficulty('Éleveur', difficulty: 2),
      WordWithDifficulty('Apiculteur', difficulty: 2),

      // MÉTIERS AGRICULTURE - Difficile
      WordWithDifficulty('Maraîcher', difficulty: 3),
      WordWithDifficulty('Viticulteur', difficulty: 3),
      WordWithDifficulty('Sylviculteur', difficulty: 3),

      // SPORTS COLLECTIFS - Facile
      WordWithDifficulty('Football', difficulty: 1),
      WordWithDifficulty('Basketball', difficulty: 1),
      WordWithDifficulty('Volleyball', difficulty: 1),
      WordWithDifficulty('Handball', difficulty: 1),
      WordWithDifficulty('Rugby', difficulty: 1),

      // SPORTS COLLECTIFS - Moyen
      WordWithDifficulty('Hockey', difficulty: 2),
      WordWithDifficulty('Baseball', difficulty: 2),
      WordWithDifficulty('Water-polo', difficulty: 2),

      // SPORTS COLLECTIFS - Difficile
      WordWithDifficulty('Football américain', difficulty: 3),
      WordWithDifficulty('Hockey sur glace', difficulty: 3),
      WordWithDifficulty('Cricket', difficulty: 3),
      WordWithDifficulty('Ultimate (frisbee)', difficulty: 3),

      // SPORTS RAQUETTE - Facile
      WordWithDifficulty('Tennis', difficulty: 1),
      WordWithDifficulty('Badminton', difficulty: 1),
      WordWithDifficulty('Tennis de table', difficulty: 1),

      // SPORTS RAQUETTE - Moyen
      WordWithDifficulty('Squash', difficulty: 2),
      WordWithDifficulty('Padel', difficulty: 2),

      // SPORTS COMBAT - Facile
      WordWithDifficulty('Boxe', difficulty: 1),
      WordWithDifficulty('Judo', difficulty: 1),
      WordWithDifficulty('Karaté', difficulty: 1),

      // SPORTS COMBAT - Moyen
      WordWithDifficulty('Taekwondo', difficulty: 2),
      WordWithDifficulty('Kung Fu', difficulty: 2),
      WordWithDifficulty('Krav Maga', difficulty: 3),
      WordWithDifficulty('MMA', difficulty: 2),

      // SPORTS COMBAT - Difficile
      WordWithDifficulty('Lutte gréco-romaine', difficulty: 3),
      WordWithDifficulty('Aïkido', difficulty: 3),
      WordWithDifficulty('Jiu-jitsu', difficulty: 3),

      // SPORTS AQUATIQUES - Facile
      WordWithDifficulty('Natation', difficulty: 1),
      WordWithDifficulty('Plongée', difficulty: 2),

      // SPORTS AQUATIQUES - Moyen
      WordWithDifficulty('Surf', difficulty: 1),
      WordWithDifficulty('Voile', difficulty: 2),
      WordWithDifficulty('Canoë-kayak', difficulty: 2),
      WordWithDifficulty('Aviron', difficulty: 2),

      // SPORTS AQUATIQUES - Difficile
      WordWithDifficulty('Wakeboard', difficulty: 3),
      WordWithDifficulty('Kitesurf', difficulty: 3),
      WordWithDifficulty('Planche à voile', difficulty: 3),

      // SPORTS INDIVIDUELS - Facile
      WordWithDifficulty('Cyclisme', difficulty: 1),
      WordWithDifficulty('Course à pied', difficulty: 1),
      WordWithDifficulty('Ski', difficulty: 1),
      WordWithDifficulty('Golf', difficulty: 1),
      WordWithDifficulty('Danse', difficulty: 1),

      // SPORTS INDIVIDUELS - Moyen
      WordWithDifficulty('Athlétisme', difficulty: 2),
      WordWithDifficulty('Gymnastique', difficulty: 2),
      WordWithDifficulty('Escalade', difficulty: 2),
      WordWithDifficulty('Équitation', difficulty: 2),
      WordWithDifficulty('Patinage', difficulty: 2),
      WordWithDifficulty('Skateboard', difficulty: 2),
      WordWithDifficulty('Roller', difficulty: 2),

      // SPORTS INDIVIDUELS - Difficile
      WordWithDifficulty('Triathlon', difficulty: 2),
      WordWithDifficulty('Pentathlon', difficulty: 2),
      WordWithDifficulty('Haltérophilie', difficulty: 2),
      WordWithDifficulty('Escrime', difficulty: 2),
      WordWithDifficulty('Tir à l\'arc', difficulty: 2),
      WordWithDifficulty('BMX', difficulty: 3),

      // SPORTS D'HIVER - Moyen
      WordWithDifficulty('Snowboard', difficulty: 2),
      WordWithDifficulty('Ski de fond', difficulty: 3),
      WordWithDifficulty('Luge', difficulty: 2),

      // SPORTS D'HIVER - Difficile
      WordWithDifficulty('Biathlon', difficulty: 2),
      WordWithDifficulty('Patinage artistique', difficulty: 2),
      WordWithDifficulty('Curling', difficulty: 2),
      WordWithDifficulty('Bobsleigh', difficulty: 3),
      WordWithDifficulty('Skeleton', difficulty: 3),
      WordWithDifficulty('Ski acrobatique', difficulty: 3),

      // SPORTS EXTRÊMES - Difficile
      WordWithDifficulty('Parachutisme', difficulty: 2),
      WordWithDifficulty('Saut à l\'élastique', difficulty: 3),
      WordWithDifficulty('Deltaplane', difficulty: 3),
      WordWithDifficulty('Parapente', difficulty: 3),
      WordWithDifficulty('Base jump', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // CÉLÉBRITÉS
  // ==========================================================================
  'celebrites': WordCategory(
    id: 'celebrites',
    name: 'Célébrités',
    icon: '⭐',
    words: const [
      // SPORTIFS FOOTBALL - Facile
      WordWithDifficulty('Messi', difficulty: 1),
      WordWithDifficulty('Ronaldo', difficulty: 1),
      WordWithDifficulty('Mbappé', difficulty: 1),
      WordWithDifficulty('Neymar', difficulty: 1),
      WordWithDifficulty('Griezmann', difficulty: 1),

      // SPORTIFS FOOTBALL - Moyen
      WordWithDifficulty('Zinedine Zidane', difficulty: 1),
      WordWithDifficulty('Pelé', difficulty: 3),
      WordWithDifficulty('Maradona', difficulty: 2),
      WordWithDifficulty('Thierry Henry', difficulty: 2),
      WordWithDifficulty('Benzema', difficulty: 1),
      WordWithDifficulty('Giroud', difficulty: 2),
      WordWithDifficulty('Pogba', difficulty: 2),
      WordWithDifficulty('Kanté', difficulty: 2),

      // SPORTIFS FOOTBALL - Difficile
      WordWithDifficulty('Platini', difficulty: 3),
      WordWithDifficulty('Beckham', difficulty: 1),
      WordWithDifficulty('Iniesta', difficulty: 3),
      WordWithDifficulty('Xavi', difficulty: 3),

      // SPORTIFS AUTRES - Facile
      WordWithDifficulty('Nadal', difficulty: 1),
      WordWithDifficulty('Federer', difficulty: 1),
      WordWithDifficulty('Michael Jordan', difficulty: 1),
      WordWithDifficulty('Usain Bolt', difficulty: 1),

      // SPORTIFS AUTRES - Moyen
      WordWithDifficulty('Djokovic', difficulty: 1),
      WordWithDifficulty('Serena Williams', difficulty: 1),
      WordWithDifficulty('Tiger Woods', difficulty: 1),
      WordWithDifficulty('LeBron James', difficulty: 2),
      WordWithDifficulty('Muhammad Ali', difficulty: 2),
      WordWithDifficulty('Michael Phelps', difficulty: 2),
      WordWithDifficulty('Tony Parker', difficulty: 2),

      // SPORTIFS AUTRES - Difficile
      WordWithDifficulty('Kobe Bryant', difficulty: 3),
      WordWithDifficulty('Mike Tyson', difficulty: 2),
      WordWithDifficulty('Simone Biles', difficulty: 2),
      WordWithDifficulty('Lewis Hamilton', difficulty: 3),
      WordWithDifficulty('Michael Schumacher', difficulty: 2),
      WordWithDifficulty('Ayrton Senna', difficulty: 3),

      // CHANTEURS INTERNATIONAUX - Facile
      WordWithDifficulty('Beyoncé', difficulty: 1),
      WordWithDifficulty('Rihanna', difficulty: 1),
      WordWithDifficulty('Taylor Swift', difficulty: 1),
      WordWithDifficulty('Ed Sheeran', difficulty: 2),
      WordWithDifficulty('Adele', difficulty: 1),
      WordWithDifficulty('Justin Bieber', difficulty: 1),
      WordWithDifficulty('Shakira', difficulty: 1),

      // CHANTEURS INTERNATIONAUX - Moyen
      WordWithDifficulty('Elvis Presley', difficulty: 2),
      WordWithDifficulty('Michael Jackson', difficulty: 2),
      WordWithDifficulty('Madonna', difficulty: 2),
      WordWithDifficulty('Prince', difficulty: 3),
      WordWithDifficulty('David Bowie', difficulty: 3),
      WordWithDifficulty('Freddie Mercury', difficulty: 2),
      WordWithDifficulty('Bob Marley', difficulty: 2),
      WordWithDifficulty('Lady Gaga', difficulty: 2),
      WordWithDifficulty('Ariana Grande', difficulty: 2),
      WordWithDifficulty('Eminem', difficulty: 4),
      WordWithDifficulty('Drake', difficulty: 2),
      WordWithDifficulty('The Weeknd', difficulty: 2),
      WordWithDifficulty('Bruno Mars', difficulty: 2),
      WordWithDifficulty('Katy Perry', difficulty: 2),

      // CHANTEURS INTERNATIONAUX - Difficile
      WordWithDifficulty('John Lennon', difficulty: 3),
      WordWithDifficulty('Kanye West', difficulty: 3),
      WordWithDifficulty('Amy Winehouse', difficulty: 2),
      WordWithDifficulty('Whitney Houston', difficulty: 3),
      WordWithDifficulty('Frank Sinatra', difficulty: 3),

      // CHANTEURS FRANÇAIS - Facile
      WordWithDifficulty('Céline Dion', difficulty: 1),
      WordWithDifficulty('Johnny Hallyday', difficulty: 1),
      WordWithDifficulty('Stromae', difficulty: 2),

      // CHANTEURS FRANÇAIS - Moyen
      WordWithDifficulty('Renaud', difficulty: 2),
      WordWithDifficulty('Jacques Brel', difficulty: 3),
      WordWithDifficulty('Serge Gainsbourg', difficulty: 3),
      WordWithDifficulty('Charles Aznavour', difficulty: 2),
      WordWithDifficulty('Claude François', difficulty: 2),
      WordWithDifficulty('Michel Sardou', difficulty: 2),
      WordWithDifficulty('Jean-Jacques Goldman', difficulty: 2),

      // CHANTEURS FRANÇAIS - Difficile
      WordWithDifficulty('Édith Piaf', difficulty: 2),
      WordWithDifficulty('Daft Punk', difficulty: 2),
      WordWithDifficulty('Georges Brassens', difficulty: 3),
      WordWithDifficulty('Léo Ferré', difficulty: 3),
      WordWithDifficulty('Barbara', difficulty: 3),

      // ACTEURS HOLLYWOOD - Facile
      WordWithDifficulty('Leonardo DiCaprio', difficulty: 1),
      WordWithDifficulty('Brad Pitt', difficulty: 1),
      WordWithDifficulty('Tom Cruise', difficulty: 1),
      WordWithDifficulty('Will Smith', difficulty: 1),
      WordWithDifficulty('Johnny Depp', difficulty: 1),
      WordWithDifficulty('Dwayne Johnson', difficulty: 3),

      // ACTEURS HOLLYWOOD - Moyen
      WordWithDifficulty('Marilyn Monroe', difficulty: 2),
      WordWithDifficulty('Charlie Chaplin', difficulty: 2),
      WordWithDifficulty('Tom Hanks', difficulty: 2),
      WordWithDifficulty('Robert De Niro', difficulty: 2),
      WordWithDifficulty('Al Pacino', difficulty: 3),
      WordWithDifficulty('Morgan Freeman', difficulty: 2),
      WordWithDifficulty('Denzel Washington', difficulty: 2),
      WordWithDifficulty('Meryl Streep', difficulty: 2),
      WordWithDifficulty('Scarlett Johansson', difficulty: 2),
      WordWithDifficulty('Jennifer Lawrence', difficulty: 2),
      WordWithDifficulty('Angelina Jolie', difficulty: 2),
      WordWithDifficulty('Emma Watson', difficulty: 2),
      WordWithDifficulty('George Clooney', difficulty: 2),
      WordWithDifficulty('Matt Damon', difficulty: 2),

      // ACTEURS HOLLYWOOD - Difficile
      WordWithDifficulty('Audrey Hepburn', difficulty: 3),
      WordWithDifficulty('James Dean', difficulty: 3),
      WordWithDifficulty('Marlon Brando', difficulty: 3),
      WordWithDifficulty('Ryan Gosling', difficulty: 3),
      WordWithDifficulty('Cate Blanchett', difficulty: 3),
      WordWithDifficulty('Kate Winslet', difficulty: 3),
      WordWithDifficulty('Margot Robbie', difficulty: 3),

      // ACTEURS FRANÇAIS - Moyen
      WordWithDifficulty('Jean Dujardin', difficulty: 2),
      WordWithDifficulty('Omar Sy', difficulty: 2),
      WordWithDifficulty('Marion Cotillard', difficulty: 2),
      WordWithDifficulty('Louis de Funès', difficulty: 2),
      WordWithDifficulty('Fernandel', difficulty: 3),
      WordWithDifficulty('Sophie Marceau', difficulty: 2),

      // ACTEURS FRANÇAIS - Difficile
      WordWithDifficulty('Alain Delon', difficulty: 3),
      WordWithDifficulty('Jean-Paul Belmondo', difficulty: 3),
      WordWithDifficulty('Brigitte Bardot', difficulty: 3),
      WordWithDifficulty('Catherine Deneuve', difficulty: 3),
      WordWithDifficulty('Isabelle Adjani', difficulty: 3),

      // TÉLÉ-RÉALITÉ / INFLUENCEURS - Facile
      WordWithDifficulty('Kim Kardashian', difficulty: 1),
      WordWithDifficulty('Kylie Jenner', difficulty: 2),

      // TÉLÉ-RÉALITÉ / INFLUENCEURS - Moyen
      WordWithDifficulty('Nabilla', difficulty: 2),
      WordWithDifficulty('Les Marseillais', difficulty: 2),
      WordWithDifficulty('Kev Adams', difficulty: 2),
      WordWithDifficulty('Norman', difficulty: 2),
      WordWithDifficulty('Cyprien', difficulty: 2),

      // TÉLÉ-RÉALITÉ / INFLUENCEURS - Difficile
      WordWithDifficulty('Squeezie', difficulty: 3),
      WordWithDifficulty('McFly et Carlito', difficulty: 3),
      WordWithDifficulty('Inès Reg', difficulty: 3),

      // HUMORISTES - Facile
      WordWithDifficulty('Gad Elmaleh', difficulty: 1),
      WordWithDifficulty('Jamel Debbouze', difficulty: 1),

      // HUMORISTES - Moyen
      WordWithDifficulty('Florence Foresti', difficulty: 2),
      WordWithDifficulty('Laurent Gerra', difficulty: 2),
      WordWithDifficulty('Anne Roumanoff', difficulty: 2),
      WordWithDifficulty('Franck Dubosc', difficulty: 2),

      // HUMORISTES - Difficile
      WordWithDifficulty('Coluche', difficulty: 3),
      WordWithDifficulty('Roman Frayssinet', difficulty: 3),
      WordWithDifficulty('Raymond Devos', difficulty: 3),

      // ÉCRIVAINS - Facile
      WordWithDifficulty('Victor Hugo', difficulty: 1),
      WordWithDifficulty('Jules Verne', difficulty: 2),
      WordWithDifficulty('J.K. Rowling', difficulty: 2),

      // ÉCRIVAINS - Moyen
      WordWithDifficulty('Molière', difficulty: 2),
      WordWithDifficulty('Alexandre Dumas', difficulty: 2),
      WordWithDifficulty('Émile Zola', difficulty: 2),
      WordWithDifficulty('Gustave Flaubert', difficulty: 3),
      WordWithDifficulty('Guy de Maupassant', difficulty: 3),
      WordWithDifficulty('Albert Camus', difficulty: 3),
      WordWithDifficulty('Shakespeare', difficulty: 2),
      WordWithDifficulty('Tolkien', difficulty: 3),

      // ÉCRIVAINS - Difficile
      WordWithDifficulty('Honoré de Balzac', difficulty: 3),
      WordWithDifficulty('Marcel Proust', difficulty: 3),
      WordWithDifficulty('Jean-Paul Sartre', difficulty: 3),
      WordWithDifficulty('Simone de Beauvoir', difficulty: 3),
      WordWithDifficulty('Baudelaire', difficulty: 3),
      WordWithDifficulty('Rimbaud', difficulty: 3),
      WordWithDifficulty('Voltaire', difficulty: 3),
      WordWithDifficulty('Rousseau', difficulty: 3),
      WordWithDifficulty('Montesquieu', difficulty: 3),
      WordWithDifficulty('Hemingway', difficulty: 3),

      // PHILOSOPHES - Difficile
      WordWithDifficulty('Platon', difficulty: 3),
      WordWithDifficulty('Aristote', difficulty: 3),
      WordWithDifficulty('Socrate', difficulty: 3),
      WordWithDifficulty('Descartes', difficulty: 3),
      WordWithDifficulty('Nietzsche', difficulty: 3),

      // PERSONNAGES HISTORIQUES - Facile
      WordWithDifficulty('Napoléon', difficulty: 1),
      WordWithDifficulty('Jeanne d\'Arc', difficulty: 1),
      WordWithDifficulty('Louis XIV', difficulty: 1),

      // PERSONNAGES HISTORIQUES - Moyen
      WordWithDifficulty('Charlemagne', difficulty: 2),
      WordWithDifficulty('Vercingétorix', difficulty: 2),
      WordWithDifficulty('Louis XVI', difficulty: 2),
      WordWithDifficulty('Marie-Antoinette', difficulty: 2),
      WordWithDifficulty('Christophe Colomb', difficulty: 2),

      // PERSONNAGES HISTORIQUES - Difficile
      WordWithDifficulty('Jules César', difficulty: 3),
      WordWithDifficulty('Cléopâtre', difficulty: 3),
      WordWithDifficulty('Attila', difficulty: 3),
      WordWithDifficulty('François 1er', difficulty: 3),
      WordWithDifficulty('Henri IV', difficulty: 3),
      WordWithDifficulty('Robespierre', difficulty: 3),
      WordWithDifficulty('De Gaulle', difficulty: 3),
      WordWithDifficulty('Churchill', difficulty: 3),

      // LEADERS MONDIAUX - Moyen
      WordWithDifficulty('Gandhi', difficulty: 2),
      WordWithDifficulty('Nelson Mandela', difficulty: 2),
      WordWithDifficulty('Martin Luther King', difficulty: 2),

      // LEADERS MONDIAUX - Difficile
      WordWithDifficulty('Abraham Lincoln', difficulty: 3),
      WordWithDifficulty('John F. Kennedy', difficulty: 3),
      WordWithDifficulty('Mère Teresa', difficulty: 3),
      WordWithDifficulty('Dalai Lama', difficulty: 3),

      // POLITIQUES FRANÇAIS - Moyen
      WordWithDifficulty('Emmanuel Macron', difficulty: 1),
      WordWithDifficulty('François Hollande', difficulty: 1),

      // POLITIQUES FRANÇAIS - Difficile
      WordWithDifficulty('Jacques Chirac', difficulty: 3),
      WordWithDifficulty('François Mitterrand', difficulty: 3),
      WordWithDifficulty('Georges Pompidou', difficulty: 3),
      WordWithDifficulty('Valéry Giscard d\'Estaing', difficulty: 3),

      // SCIENTIFIQUES - Facile
      WordWithDifficulty('Einstein', difficulty: 1),
      WordWithDifficulty('Marie Curie', difficulty: 1),

      // SCIENTIFIQUES - Moyen
      WordWithDifficulty('Pasteur', difficulty: 2),
      WordWithDifficulty('Darwin', difficulty: 3),
      WordWithDifficulty('Newton', difficulty: 2),

      // SCIENTIFIQUES - Difficile
      WordWithDifficulty('Galilée', difficulty: 3),
      WordWithDifficulty('Tesla', difficulty: 3),
      WordWithDifficulty('Pythagore', difficulty: 3),
      WordWithDifficulty('Archimède', difficulty: 3),
      WordWithDifficulty('Léonard de Vinci', difficulty: 3),

      // TECH/BUSINESS - Facile
      WordWithDifficulty('Steve Jobs', difficulty: 1),
      WordWithDifficulty('Bill Gates', difficulty: 1),

      // TECH/BUSINESS - Moyen
      WordWithDifficulty('Mark Zuckerberg', difficulty: 2),

      // TECH/BUSINESS - Difficile
      WordWithDifficulty('Jeff Bezos', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // NOMS COMMUNS (Objets, Transports, Mobilier, Inventions, Instruments)
  // ==========================================================================
  'noms_communs': WordCategory(
    id: 'noms_communs',
    name: 'Noms communs',
    icon: '🔧',
    words: const [
      // OBJETS ÉLECTRONIQUES - Facile
      WordWithDifficulty('Téléphone', difficulty: 1),
      WordWithDifficulty('Ordinateur', difficulty: 1),
      WordWithDifficulty('Télévision', difficulty: 1),
      WordWithDifficulty('Radio', difficulty: 1),
      WordWithDifficulty('Appareil photo', difficulty: 1),
      WordWithDifficulty('Console de jeux', difficulty: 1),

      // OBJETS ÉLECTRONIQUES - Moyen
      WordWithDifficulty('Tablette', difficulty: 2),
      WordWithDifficulty('Casque', difficulty: 2),
      WordWithDifficulty('Enceinte', difficulty: 2),
      WordWithDifficulty('Chargeur', difficulty: 2),
      WordWithDifficulty('Clé USB', difficulty: 2),
      WordWithDifficulty('Clavier', difficulty: 2),
      WordWithDifficulty('Souris', difficulty: 2),
      WordWithDifficulty('Imprimante', difficulty: 2),
      WordWithDifficulty('Scanner', difficulty: 2),

      // OBJETS ÉLECTRONIQUES - Difficile
      WordWithDifficulty('Webcam', difficulty: 3),
      WordWithDifficulty('Drone', difficulty: 3),
      WordWithDifficulty('Projecteur', difficulty: 3),
      WordWithDifficulty('Disque dur', difficulty: 3),
      WordWithDifficulty('Carte mémoire', difficulty: 3),

      // OBJETS QUOTIDIEN - Facile
      WordWithDifficulty('Stylo', difficulty: 1),
      WordWithDifficulty('Crayon', difficulty: 1),
      WordWithDifficulty('Cahier', difficulty: 1),
      WordWithDifficulty('Livre', difficulty: 1),
      WordWithDifficulty('Parapluie', difficulty: 1),
      WordWithDifficulty('Sac', difficulty: 1),
      WordWithDifficulty('Valise', difficulty: 1),
      WordWithDifficulty('Montre', difficulty: 1),
      WordWithDifficulty('Lunettes', difficulty: 1),
      WordWithDifficulty('Clés', difficulty: 1),
      WordWithDifficulty('Sac à dos', difficulty: 1),

      // OBJETS QUOTIDIEN - Moyen
      WordWithDifficulty('Lampe', difficulty: 2),
      WordWithDifficulty('Horloge', difficulty: 2),
      WordWithDifficulty('Réveil', difficulty: 2),
      WordWithDifficulty('Bougie', difficulty: 2),
      WordWithDifficulty('Vase', difficulty: 2),
      WordWithDifficulty('Cadre photo', difficulty: 2),
      WordWithDifficulty('Panier', difficulty: 2),
      WordWithDifficulty('Ciseaux', difficulty: 2),
      WordWithDifficulty('Règle', difficulty: 2),

      // OBJETS QUOTIDIEN - Difficile
      WordWithDifficulty('Portefeuille', difficulty: 3),
      WordWithDifficulty('Briquet', difficulty: 3),
      WordWithDifficulty('Boussole', difficulty: 3),
      WordWithDifficulty('Loupe', difficulty: 3),
      WordWithDifficulty('Jumelles', difficulty: 3),
      WordWithDifficulty('Théière', difficulty: 3),

      // MOBILIER - Facile
      WordWithDifficulty('Chaise', difficulty: 1),
      WordWithDifficulty('Table', difficulty: 1),
      WordWithDifficulty('Lit', difficulty: 1),
      WordWithDifficulty('Canapé', difficulty: 1),
      WordWithDifficulty('Armoire', difficulty: 1),
      WordWithDifficulty('Placard', difficulty: 1),

      // MOBILIER - Moyen
      WordWithDifficulty('Bureau', difficulty: 2),
      WordWithDifficulty('Fauteuil', difficulty: 2),
      WordWithDifficulty('Étagère', difficulty: 2),
      WordWithDifficulty('Commode', difficulty: 2),
      WordWithDifficulty('Bibliothèque', difficulty: 2),
      WordWithDifficulty('Tabouret', difficulty: 2),
      WordWithDifficulty('Tapis', difficulty: 2),
      WordWithDifficulty('Rideau', difficulty: 2),
      WordWithDifficulty('Miroir', difficulty: 2),
      WordWithDifficulty('Lampadaire', difficulty: 2),
      WordWithDifficulty('Table de chevet', difficulty: 3),

      // MOBILIER - Difficile
      WordWithDifficulty('Banc', difficulty: 2),
      WordWithDifficulty('Pouf', difficulty: 3),
      WordWithDifficulty('Matelas', difficulty: 3),
      WordWithDifficulty('Oreiller', difficulty: 3),
      WordWithDifficulty('Couverture', difficulty: 2),
      WordWithDifficulty('Lustre', difficulty: 3),
      WordWithDifficulty('Buffet', difficulty: 2),
      WordWithDifficulty('Console', difficulty: 2),

      // USTENSILES CUISINE - Facile
      WordWithDifficulty('Couteau', difficulty: 1),
      WordWithDifficulty('Fourchette', difficulty: 1),
      WordWithDifficulty('Cuillère', difficulty: 1),
      WordWithDifficulty('Assiette', difficulty: 1),
      WordWithDifficulty('Verre', difficulty: 1),
      WordWithDifficulty('Tasse', difficulty: 1),

      // USTENSILES CUISINE - Moyen
      WordWithDifficulty('Casserole', difficulty: 2),
      WordWithDifficulty('Poêle', difficulty: 2),
      WordWithDifficulty('Passoire', difficulty: 2),
      WordWithDifficulty('Fouet', difficulty: 2),
      WordWithDifficulty('Spatule', difficulty: 2),
      WordWithDifficulty('Louche', difficulty: 2),
      WordWithDifficulty('Saladier', difficulty: 2),

      // USTENSILES CUISINE - Difficile
      WordWithDifficulty('Écumoire', difficulty: 3),
      WordWithDifficulty('Chinois', difficulty: 3),
      WordWithDifficulty('Mandoline', difficulty: 3),
      WordWithDifficulty('Presse-agrumes', difficulty: 3),

      // OUTILS - Facile
      WordWithDifficulty('Marteau', difficulty: 1),
      WordWithDifficulty('Tournevis', difficulty: 1),
      WordWithDifficulty('Scie', difficulty: 1),

      // OUTILS - Moyen
      WordWithDifficulty('Perceuse', difficulty: 2),
      WordWithDifficulty('Pince', difficulty: 2),
      WordWithDifficulty('Clé', difficulty: 2),
      WordWithDifficulty('Niveau', difficulty: 2),
      WordWithDifficulty('Mètre', difficulty: 2),

      // OUTILS - Difficile
      WordWithDifficulty('Rabot', difficulty: 3),
      WordWithDifficulty('Étau', difficulty: 3),
      WordWithDifficulty('Serre-joint', difficulty: 3),
      WordWithDifficulty('Lime', difficulty: 3),

      // MOYENS DE TRANSPORT - Facile
      WordWithDifficulty('Voiture', difficulty: 1),
      WordWithDifficulty('Avion', difficulty: 1),
      WordWithDifficulty('Train', difficulty: 1),
      WordWithDifficulty('Bateau', difficulty: 1),
      WordWithDifficulty('Vélo', difficulty: 1),
      WordWithDifficulty('Bus', difficulty: 1),
      WordWithDifficulty('Métro', difficulty: 1),
      WordWithDifficulty('Scooter', difficulty: 1),

      // MOYENS DE TRANSPORT - Moyen
      WordWithDifficulty('Moto', difficulty: 2),
      WordWithDifficulty('Camion', difficulty: 2),
      WordWithDifficulty('Tramway', difficulty: 2),
      WordWithDifficulty('Taxi', difficulty: 2),
      WordWithDifficulty('Hélicoptère', difficulty: 2),
      WordWithDifficulty('Voilier', difficulty: 2),
      WordWithDifficulty('Péniche', difficulty: 2),
      WordWithDifficulty('Ferry', difficulty: 2),

      // MOYENS DE TRANSPORT - Difficile
      WordWithDifficulty('Fusée', difficulty: 3),
      WordWithDifficulty('Sous-marin', difficulty: 3),
      WordWithDifficulty('Montgolfière', difficulty: 3),
      WordWithDifficulty('Parachute', difficulty: 2),
      WordWithDifficulty('Ascenseur', difficulty: 2),
      WordWithDifficulty('Escalator', difficulty: 2),
      WordWithDifficulty('Trottinette', difficulty: 2),
      WordWithDifficulty('Skateboard', difficulty: 2),
      WordWithDifficulty('Téléphérique', difficulty: 3),

      // VÊTEMENTS - Facile
      WordWithDifficulty('T-shirt', difficulty: 1),
      WordWithDifficulty('Pantalon', difficulty: 1),
      WordWithDifficulty('Robe', difficulty: 1),
      WordWithDifficulty('Jupe', difficulty: 1),
      WordWithDifficulty('Chaussures', difficulty: 1),
      WordWithDifficulty('Chaussettes', difficulty: 1),
      WordWithDifficulty('Manteau', difficulty: 1),

      // VÊTEMENTS - Moyen
      WordWithDifficulty('Pull', difficulty: 2),
      WordWithDifficulty('Chemise', difficulty: 2),
      WordWithDifficulty('Veste', difficulty: 2),
      WordWithDifficulty('Écharpe', difficulty: 2),
      WordWithDifficulty('Gants', difficulty: 2),
      WordWithDifficulty('Bonnet', difficulty: 2),
      WordWithDifficulty('Cravate', difficulty: 2),

      // VÊTEMENTS - Difficile
      WordWithDifficulty('Gilet', difficulty: 3),
      WordWithDifficulty('Cardigan', difficulty: 3),
      WordWithDifficulty('Pardessus', difficulty: 3),
      WordWithDifficulty('Chapka', difficulty: 3),

      // INSTRUMENTS À CORDES - Facile
      WordWithDifficulty('Guitare', difficulty: 1),
      WordWithDifficulty('Piano', difficulty: 1),
      WordWithDifficulty('Violon', difficulty: 1),

      // INSTRUMENTS À CORDES - Moyen
      WordWithDifficulty('Harpe', difficulty: 2),
      WordWithDifficulty('Violoncelle', difficulty: 2),
      WordWithDifficulty('Contrebasse', difficulty: 2),
      WordWithDifficulty('Ukulélé', difficulty: 2),
      WordWithDifficulty('Banjo', difficulty: 2),

      // INSTRUMENTS À CORDES - Difficile
      WordWithDifficulty('Alto', difficulty: 3),
      WordWithDifficulty('Clavecin', difficulty: 3),
      WordWithDifficulty('Mandoline', difficulty: 3),
      WordWithDifficulty('Luth', difficulty: 3),

      // INSTRUMENTS À VENT - Facile
      WordWithDifficulty('Flûte', difficulty: 1),
      WordWithDifficulty('Trompette', difficulty: 1),
      WordWithDifficulty('Saxophone', difficulty: 1),

      // INSTRUMENTS À VENT - Moyen
      WordWithDifficulty('Clarinette', difficulty: 2),
      WordWithDifficulty('Trombone', difficulty: 2),
      WordWithDifficulty('Cor', difficulty: 2),
      WordWithDifficulty('Harmonica', difficulty: 2),

      // INSTRUMENTS À VENT - Difficile
      WordWithDifficulty('Hautbois', difficulty: 3),
      WordWithDifficulty('Basson', difficulty: 3),
      WordWithDifficulty('Tuba', difficulty: 3),
      WordWithDifficulty('Cornemuse', difficulty: 3),
      WordWithDifficulty('Ocarina', difficulty: 3),

      // INSTRUMENTS À PERCUSSION - Facile
      WordWithDifficulty('Batterie', difficulty: 1),
      WordWithDifficulty('Tambour', difficulty: 1),
      WordWithDifficulty('Xylophone', difficulty: 1),

      // INSTRUMENTS À PERCUSSION - Moyen
      WordWithDifficulty('Cymbales', difficulty: 3),
      WordWithDifficulty('Maracas', difficulty: 2),
      WordWithDifficulty('Djembé', difficulty: 2),
      WordWithDifficulty('Gong', difficulty: 3),

      // INSTRUMENTS À PERCUSSION - Difficile
      WordWithDifficulty('Timbales', difficulty: 3),
      WordWithDifficulty('Triangle', difficulty: 2),

      // INVENTIONS - Facile
      WordWithDifficulty('Roue', difficulty: 1),
      WordWithDifficulty('Ampoule', difficulty: 1),
      WordWithDifficulty('Internet', difficulty: 1),
      WordWithDifficulty('Téléphone', difficulty: 1),

      // INVENTIONS - Moyen
      WordWithDifficulty('Imprimerie', difficulty: 2),
      WordWithDifficulty('Télégraphe', difficulty: 2),
      WordWithDifficulty('Microscope', difficulty: 2),
      WordWithDifficulty('Vaccin', difficulty: 2),
      WordWithDifficulty('Moteur à explosion', difficulty: 3),
      WordWithDifficulty('Locomotive', difficulty: 2),

      // INVENTIONS - Difficile
      WordWithDifficulty('Pénicilline', difficulty: 3),
      WordWithDifficulty('Anesthésie', difficulty: 2),
      WordWithDifficulty('Radiographie', difficulty: 3),
      WordWithDifficulty('Microprocesseur', difficulty: 3),
      WordWithDifficulty('GPS', difficulty: 3),
      WordWithDifficulty('Wi-Fi', difficulty: 3),
      WordWithDifficulty('Bluetooth', difficulty: 3),
      WordWithDifficulty('Code-barres', difficulty: 3),
      WordWithDifficulty('Fermeture éclair', difficulty: 3),
      WordWithDifficulty('Velcro', difficulty: 3),
      WordWithDifficulty('Post-it', difficulty: 3),
      WordWithDifficulty('Laser', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // UNIVERS ARCADE (Pokémon, Clash Royale, Jeux vidéo, Jeux de société)
  // ==========================================================================
  'univers_arcade': WordCategory(
    id: 'univers_arcade',
    name: 'Univers Arcade',
    icon: '🎮',
    words: const [
      // POKÉMON GÉNÉRATION 1 - Facile
      WordWithDifficulty('Pikachu', difficulty: 1),
      WordWithDifficulty('Dracaufeu', difficulty: 1),
      WordWithDifficulty('Bulbizarre', difficulty: 1),
      WordWithDifficulty('Salamèche', difficulty: 1),
      WordWithDifficulty('Carapuce', difficulty: 1),
      WordWithDifficulty('Ronflex', difficulty: 3),
      WordWithDifficulty('Évoli', difficulty: 3),
      WordWithDifficulty('Mewtwo', difficulty: 3),
      WordWithDifficulty('Mew', difficulty: 3),
      WordWithDifficulty('Rattata', difficulty: 3),
      WordWithDifficulty('Roucool', difficulty: 3),
      WordWithDifficulty('Chenipan', difficulty: 3),

      // POKÉMON GÉNÉRATION 1 - Moyen
      WordWithDifficulty('Florizarre', difficulty: 3),
      WordWithDifficulty('Tortank', difficulty: 3),
      WordWithDifficulty('Raichu', difficulty: 3),
      WordWithDifficulty('Aquali', difficulty: 3),
      WordWithDifficulty('Voltali', difficulty: 3),
      WordWithDifficulty('Pyroli', difficulty: 3),
      WordWithDifficulty('Rondoudou', difficulty: 2),
      WordWithDifficulty('Mélofée', difficulty: 3),
      WordWithDifficulty('Psykokwak', difficulty: 3),
      WordWithDifficulty('Magicarpe', difficulty: 3),
      WordWithDifficulty('Léviator', difficulty: 3),
      WordWithDifficulty('Dracolosse', difficulty: 3),
      WordWithDifficulty('Piafabec', difficulty: 3),
      WordWithDifficulty('Sabelette', difficulty: 3),
      WordWithDifficulty('Goupix', difficulty: 3),
      WordWithDifficulty('Ramoloss', difficulty: 3),
      WordWithDifficulty('Soporifik', difficulty: 3),

      // POKÉMON LÉGENDAIRES ET GÉNÉRATIONS SUIVANTES - Moyen
      WordWithDifficulty('Lugia', difficulty: 3),
      WordWithDifficulty('Ho-Oh', difficulty: 3),
      WordWithDifficulty('Rayquaza', difficulty: 3),
      WordWithDifficulty('Kyogre', difficulty: 3),
      WordWithDifficulty('Groudon', difficulty: 3),
      WordWithDifficulty('Dialga', difficulty: 3),
      WordWithDifficulty('Palkia', difficulty: 3),
      WordWithDifficulty('Giratina', difficulty: 3),

      // POKÉMON LÉGENDAIRES - Difficile
      WordWithDifficulty('Artikodin', difficulty: 3),
      WordWithDifficulty('Électhor', difficulty: 3),
      WordWithDifficulty('Sulfura', difficulty: 3),
      WordWithDifficulty('Celebi', difficulty: 3),
      WordWithDifficulty('Suicune', difficulty: 3),
      WordWithDifficulty('Entei', difficulty: 3),

      // CLASH ROYALE TROUPES - Facile
      WordWithDifficulty('Chevalier', difficulty: 2),
      WordWithDifficulty('Archers', difficulty: 3),
      WordWithDifficulty('Géant', difficulty: 2),
      WordWithDifficulty('P.E.K.K.A', difficulty: 3),
      WordWithDifficulty('Dragon', difficulty: 2),
      WordWithDifficulty('Sorcier', difficulty: 2),
      WordWithDifficulty('Squelettes', difficulty: 2),
      WordWithDifficulty('Gobelins', difficulty: 3),

      // CLASH ROYALE TROUPES - Moyen
      WordWithDifficulty('Prince', difficulty: 2),
      WordWithDifficulty('Princesse', difficulty: 2),
      WordWithDifficulty('Valkyrie', difficulty: 3),
      WordWithDifficulty('Golem', difficulty: 3),
      WordWithDifficulty('Ballon', difficulty: 2),
      WordWithDifficulty('Méga chevalier', difficulty: 3),
      WordWithDifficulty('Bûcheron', difficulty: 2),
      WordWithDifficulty('Sorcière', difficulty: 2),
      WordWithDifficulty('Barbare', difficulty: 2),
      WordWithDifficulty('Mini P.E.K.K.A', difficulty: 3),
      WordWithDifficulty('Mousquetaire', difficulty: 2),

      // CLASH ROYALE TROUPES - Difficile
      WordWithDifficulty('Électro-géant', difficulty: 3),
      WordWithDifficulty('Archer magique', difficulty: 3),
      WordWithDifficulty('Mineur', difficulty: 3),
      WordWithDifficulty('Bandit', difficulty: 3),
      WordWithDifficulty('Fantôme royal', difficulty: 3),
      WordWithDifficulty('Golem de glace', difficulty: 3),
      WordWithDifficulty('Lavahound', difficulty: 3),
      WordWithDifficulty('Boulet de canon', difficulty: 3),
      WordWithDifficulty('Garde royale', difficulty: 3),

      // CLASH ROYALE SORTS - Moyen
      WordWithDifficulty('Boule de feu', difficulty: 3),
      WordWithDifficulty('Flèches', difficulty: 2),
      WordWithDifficulty('Zap', difficulty: 3),
      WordWithDifficulty('Foudre', difficulty: 2),
      WordWithDifficulty('Rage', difficulty: 2),
      WordWithDifficulty('Gel', difficulty: 2),

      // CLASH ROYALE SORTS - Difficile
      WordWithDifficulty('Tornade', difficulty: 2),
      WordWithDifficulty('Clone', difficulty: 3),
      WordWithDifficulty('Guérison', difficulty: 2),
      WordWithDifficulty('Poison', difficulty: 2),
      WordWithDifficulty('Boule de neige', difficulty: 3),

      // JEUX VIDÉO CLASSIQUES - Facile
      WordWithDifficulty('Mario', difficulty: 1),
      WordWithDifficulty('Zelda', difficulty: 1),
      WordWithDifficulty('Minecraft', difficulty: 1),
      WordWithDifficulty('Fortnite', difficulty: 2),
      WordWithDifficulty('Sonic', difficulty: 2),
      WordWithDifficulty('Pac-Man', difficulty: 2),
      WordWithDifficulty('Tetris', difficulty: 1),
      WordWithDifficulty('Among Us', difficulty: 3),
      WordWithDifficulty('Pokémon', difficulty: 1),

      // JEUX VIDÉO POPULAIRES - Moyen
      WordWithDifficulty('GTA', difficulty: 3),
      WordWithDifficulty('Call of Duty', difficulty: 2),
      WordWithDifficulty('FIFA', difficulty: 1),
      WordWithDifficulty('Assassin\'s Creed', difficulty: 3),
      WordWithDifficulty('The Witcher', difficulty: 3),
      WordWithDifficulty('League of Legends', difficulty: 3),
      WordWithDifficulty('Animal Crossing', difficulty: 2),
      WordWithDifficulty('Super Smash Bros', difficulty: 3),
      WordWithDifficulty('Rocket League', difficulty: 3),
      WordWithDifficulty('Apex Legends', difficulty: 3),
      WordWithDifficulty('Sims', difficulty: 2),
      WordWithDifficulty('Subway Surfers', difficulty: 3),

      // JEUX VIDÉO CULTE - Difficile
      WordWithDifficulty('Donkey Kong', difficulty: 3),
      WordWithDifficulty('Final Fantasy', difficulty: 3),
      WordWithDifficulty('World of Warcraft', difficulty: 3),
      WordWithDifficulty('Dofus', difficulty: 1),
      WordWithDifficulty('Spyro', difficulty: 3),

      // JEUX DE SOCIÉTÉ CLASSIQUES - Facile
      WordWithDifficulty('Monopoly', difficulty: 1),
      WordWithDifficulty('Scrabble', difficulty: 1),
      WordWithDifficulty('Uno', difficulty: 1),
      WordWithDifficulty('Échecs', difficulty: 1),
      WordWithDifficulty('Dames', difficulty: 1),
      WordWithDifficulty('Petits chevaux', difficulty: 1),
      WordWithDifficulty('Bonne paye', difficulty: 3),

      // JEUX DE SOCIÉTÉ MODERNES - Moyen
      WordWithDifficulty('Cluedo', difficulty: 2),
      WordWithDifficulty('Risk', difficulty: 2),
      WordWithDifficulty('Trivial Pursuit', difficulty: 2),
      WordWithDifficulty('Puissance 4', difficulty: 2),
      WordWithDifficulty('Time\'s Up', difficulty: 2),
      WordWithDifficulty('Jungle Speed', difficulty: 2),
      WordWithDifficulty('Dobble', difficulty: 2),
      WordWithDifficulty('Pictionary', difficulty: 2),
      WordWithDifficulty('Taboo', difficulty: 2),
      WordWithDifficulty('Loups-garous', difficulty: 1),
      WordWithDifficulty('Mille bornes', difficulty: 3),

      // JEUX DE SOCIÉTÉ EXPERT - Difficile
      WordWithDifficulty('Catan', difficulty: 3),
      WordWithDifficulty('7 Wonders', difficulty: 3),
      WordWithDifficulty('Blanc-manger coco', difficulty: 3),
      WordWithDifficulty('Codenames', difficulty: 3),
      WordWithDifficulty('Splendor', difficulty: 3),
      WordWithDifficulty('Les aventuriers du rail', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // EXPRESSIONS FRANÇAISES
  // ==========================================================================
  'expressions': WordCategory(
    id: 'expressions',
    name: 'Expressions françaises',
    icon: '🇫🇷',
    words: const [
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
      WordWithDifficulty('Quand les poules auront des dents', difficulty: 2),
      WordWithDifficulty('Être le dindon de la farce', difficulty: 2),
      WordWithDifficulty('Avoir une mémoire d\'éléphant', difficulty: 2),
      WordWithDifficulty('Noyer le poisson', difficulty: 2),
      WordWithDifficulty('Prendre le taureau par les cornes', difficulty: 2),
      WordWithDifficulty('Être comme un coq en pâte', difficulty: 2),
      WordWithDifficulty('Faire l\'autruche', difficulty: 2),
      WordWithDifficulty('Être rusé comme un renard', difficulty: 2),
      WordWithDifficulty('Être muet comme une carpe', difficulty: 2),
      WordWithDifficulty('Avoir des fourmis dans les jambes', difficulty: 2),
      WordWithDifficulty('Monter sur ses grands chevaux', difficulty: 2),
      WordWithDifficulty('Avoir des papillons dans le ventre', difficulty: 2),
      WordWithDifficulty('Rire comme une baleine', difficulty: 2),
      WordWithDifficulty('Être fort comme un bœuf', difficulty: 2),
      WordWithDifficulty('Souffler comme un bœuf', difficulty: 3),

      // EXPRESSIONS AVEC ANIMAUX - Difficile
      WordWithDifficulty('Avoir d\'autres chats à fouetter', difficulty: 3),
      WordWithDifficulty('Être une poule mouillée', difficulty: 3),
      WordWithDifficulty('Chercher la petite bête', difficulty: 3),
      WordWithDifficulty('Avoir le bourdon', difficulty: 3),
      WordWithDifficulty('Être une tête de mule', difficulty: 3),
      WordWithDifficulty('Ménager la chèvre et le chou', difficulty: 3),
      WordWithDifficulty('Être le bouc émissaire', difficulty: 3),
      WordWithDifficulty('Être serrés comme des sardines', difficulty: 3),

      // EXPRESSIONS AVEC LE CORPS - Facile
      WordWithDifficulty('Avoir le cœur sur la main', difficulty: 1),
      WordWithDifficulty('Coûter les yeux de la tête', difficulty: 1),
      WordWithDifficulty('Mettre les pieds dans le plat', difficulty: 1),
      WordWithDifficulty('Prendre ses jambes à son cou', difficulty: 1),
      WordWithDifficulty('Avoir les yeux plus gros que le ventre', difficulty: 1),
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
      WordWithDifficulty('Avoir l\'œil américain', difficulty: 2),
      WordWithDifficulty('Lever le coude', difficulty: 2),
      WordWithDifficulty('Rire du bout des lèvres', difficulty: 2),
      WordWithDifficulty('Se mordre les doigts', difficulty: 2),
      WordWithDifficulty('En avoir plein le dos', difficulty: 2),
      WordWithDifficulty('Se tourner les pouces', difficulty: 2),
      WordWithDifficulty('Avoir les dents qui rayent le parquet', difficulty: 2),

      // EXPRESSIONS AVEC LE CORPS - Difficile
      WordWithDifficulty('Avoir l\'estomac dans les talons', difficulty: 3),
      WordWithDifficulty('Se mettre le doigt dans l\'œil', difficulty: 3),
      WordWithDifficulty('Avoir les dents longues', difficulty: 3),
      WordWithDifficulty('Avoir du nez', difficulty: 3),
      WordWithDifficulty('Manger sur le pouce', difficulty: 3),
      WordWithDifficulty('Ne pas avoir la langue dans sa poche', difficulty: 3),
      WordWithDifficulty('Avoir l\'estomac accroché', difficulty: 3),
      WordWithDifficulty('Se faire des cheveux blancs', difficulty: 3),
      WordWithDifficulty('Avoir le compas dans l\'œil', difficulty: 3),
      WordWithDifficulty('Mettre les bouchées doubles', difficulty: 3),

      // EXPRESSIONS CULINAIRES - Facile
      WordWithDifficulty('Tomber dans les pommes', difficulty: 1),
      WordWithDifficulty('Avoir la patate', difficulty: 1),
      WordWithDifficulty('C\'est la cerise sur le gâteau', difficulty: 1),
      WordWithDifficulty('Être une grosse légume', difficulty: 1),
      WordWithDifficulty('Casser du sucre sur le dos', difficulty: 1),
      WordWithDifficulty('Mettre son grain de sel', difficulty: 1),

      // EXPRESSIONS CULINAIRES - Moyen
      WordWithDifficulty('Mettre du beurre dans les épinards', difficulty: 2),
      WordWithDifficulty('Raconter des salades', difficulty: 2),
      WordWithDifficulty('Être dans les choux', difficulty: 2),
      WordWithDifficulty('Ramener sa fraise', difficulty: 2),
      WordWithDifficulty('Couper la poire en deux', difficulty: 2),
      WordWithDifficulty('Mettre de l\'eau dans son vin', difficulty: 2),
      WordWithDifficulty('Avoir du pain sur la planche', difficulty: 2),
      WordWithDifficulty('Être bon comme du bon pain', difficulty: 2),
      WordWithDifficulty('Gagner son pain', difficulty: 2),
      WordWithDifficulty('Avoir la banane', difficulty: 2),
      WordWithDifficulty('Presser quelqu\'un comme un citron', difficulty: 2),
      WordWithDifficulty('Tourner en eau de boudin', difficulty: 2),

      // EXPRESSIONS CULINAIRES - Difficile
      WordWithDifficulty('Mi-figue mi-raisin', difficulty: 3),
      WordWithDifficulty('Ne pas être dans son assiette', difficulty: 3),
      WordWithDifficulty('En faire tout un fromage', difficulty: 3),
      WordWithDifficulty('Être haut comme trois pommes', difficulty: 3),
      WordWithDifficulty('Sucrer les fraises', difficulty: 3),
      WordWithDifficulty('Pédaler dans la semoule', difficulty: 3),
      WordWithDifficulty('Les carottes sont cuites', difficulty: 3),
      WordWithDifficulty('Compter pour des prunes', difficulty: 3),
      WordWithDifficulty('Pour des nèfles', difficulty: 3),
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
      WordWithDifficulty('Rouler quelqu\'un dans la farine', difficulty: 2),
      WordWithDifficulty('Casser les oreilles', difficulty: 2),
      WordWithDifficulty('Jeter de la poudre aux yeux', difficulty: 2),
      WordWithDifficulty('Se faire rouler dans la farine', difficulty: 2),
      WordWithDifficulty('Avoir un coup de pompe', difficulty: 2),
      WordWithDifficulty('Tailler une bavette', difficulty: 2),
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
      WordWithDifficulty('Prendre des vessies pour des lanternes', difficulty: 3),
      WordWithDifficulty('Être né de la dernière pluie', difficulty: 3),
      WordWithDifficulty('Se faire l\'avocat du diable', difficulty: 3),
      WordWithDifficulty('Découvrir le pot aux roses', difficulty: 3),

      // EXPRESSIONS MÉTÉO ET NATURE - Moyen
      WordWithDifficulty('Faire la pluie et le beau temps', difficulty: 2),
      WordWithDifficulty('Après la pluie le beau temps', difficulty: 2),
      WordWithDifficulty('Être dans le vent', difficulty: 2),
      WordWithDifficulty('Vent debout contre', difficulty: 2),
      WordWithDifficulty('Souffler le chaud et le froid', difficulty: 2),

      // EXPRESSIONS MÉTÉO ET NATURE - Difficile
      WordWithDifficulty('Avoir un vent de panique', difficulty: 3),
      WordWithDifficulty('Jeter un froid', difficulty: 3),
      WordWithDifficulty('Briser la glace', difficulty: 3),
      WordWithDifficulty('Être dans le brouillard', difficulty: 3),
      WordWithDifficulty('Essuyer les plâtres', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // DICTIONNAIRE (Émotions, Adjectifs, Adverbes, Verbes, Actions)
  // ==========================================================================
  'dictionnaire': WordCategory(
    id: 'dictionnaire',
    name: 'Dictionnaire',
    icon: '📖',
    words: const [
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
      WordWithDifficulty('Gentil', difficulty: 2),

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
      WordWithDifficulty('Méticuleeux', difficulty: 3),
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
      WordWithDifficulty('Ramper', difficulty: 3),
      WordWithDifficulty('Jongler', difficulty: 3),
      WordWithDifficulty('Escalader', difficulty: 3),
      WordWithDifficulty('Méditer', difficulty: 3),
      WordWithDifficulty('Scruter', difficulty: 3),
      WordWithDifficulty('Persévérer', difficulty: 3),
      WordWithDifficulty('Contempler', difficulty: 3),
      WordWithDifficulty('Sillonner', difficulty: 3),
      WordWithDifficulty('Vagabonder', difficulty: 3),
      WordWithDifficulty('Déambuler', difficulty: 3),
      WordWithDifficulty('Procrastiner', difficulty: 3),
      WordWithDifficulty('Divaguer', difficulty: 3),

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
      WordWithDifficulty('Synthétiser', difficulty: 3),
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
    ],
  ),

  // ==========================================================================
  // MUSIQUE (Chansons et Genres musicaux)
  // ==========================================================================
  'musique': WordCategory(
    id: 'musique',
    name: 'Musique',
    icon: '🎵',
    words: const [
      // CHANSONS FRANÇAISES CLASSIQUES - Facile
      WordWithDifficulty('La vie en rose', difficulty: 1),
      WordWithDifficulty('Non, je ne regrette rien', difficulty: 1),
      WordWithDifficulty('Aux Champs-Élysées', difficulty: 1),
      WordWithDifficulty('Dernière danse', difficulty: 1),
      WordWithDifficulty('Andalouse', difficulty: 1),
      WordWithDifficulty('Tout oublier', difficulty: 1),
      WordWithDifficulty('Balance ton quoi', difficulty: 1),

      // CHANSONS FRANÇAISES - Moyen
      WordWithDifficulty('La bohème', difficulty: 2),
      WordWithDifficulty('Comme d\'habitude', difficulty: 2),
      WordWithDifficulty('Ne me quitte pas', difficulty: 2),
      WordWithDifficulty('L\'aventurier', difficulty: 2),
      WordWithDifficulty('Foule sentimentale', difficulty: 2),
      WordWithDifficulty('Savoir aimer', difficulty: 2),
      WordWithDifficulty('Je veux', difficulty: 2),
      WordWithDifficulty('Papaoutai', difficulty: 2),
      WordWithDifficulty('Formidable', difficulty: 2),
      WordWithDifficulty('Tous les mêmes', difficulty: 2),
      WordWithDifficulty('Carmen', difficulty: 2),
      WordWithDifficulty('Djadja', difficulty: 2),
      WordWithDifficulty('Bande organisée', difficulty: 2),
      WordWithDifficulty('La grenade', difficulty: 2),

      // CHANSONS FRANÇAISES - Difficile
      WordWithDifficulty('Amsterdam', difficulty: 3),
      WordWithDifficulty('Les copains d\'abord', difficulty: 3),
      WordWithDifficulty('Le déserteur', difficulty: 3),
      WordWithDifficulty('Syracuse', difficulty: 3),
      WordWithDifficulty('L\'hymne à l\'amour', difficulty: 3),
      WordWithDifficulty('Les Champs-Élysées', difficulty: 3),
      WordWithDifficulty('Que je t\'aime', difficulty: 3),
      WordWithDifficulty('Maintenant', difficulty: 3),
      WordWithDifficulty('La même', difficulty: 3),
      WordWithDifficulty('Bé cool', difficulty: 3),

      // CHANSONS INTERNATIONALES - Facile
      WordWithDifficulty('Shape of You', difficulty: 1),
      WordWithDifficulty('Despacito', difficulty: 1),
      WordWithDifficulty('Uptown Funk', difficulty: 1),
      WordWithDifficulty('Happy', difficulty: 1),
      WordWithDifficulty('Hello', difficulty: 1),
      WordWithDifficulty('Rolling in the Deep', difficulty: 1),
      WordWithDifficulty('Someone Like You', difficulty: 1),
      WordWithDifficulty('Blinding Lights', difficulty: 1),
      WordWithDifficulty('Levitating', difficulty: 1),
      WordWithDifficulty('Bad Guy', difficulty: 1),

      // CHANSONS INTERNATIONALES - Moyen
      WordWithDifficulty('Bohemian Rhapsody', difficulty: 2),
      WordWithDifficulty('Imagine', difficulty: 2),
      WordWithDifficulty('Let It Be', difficulty: 2),
      WordWithDifficulty('Stairway to Heaven', difficulty: 2),
      WordWithDifficulty('Hotel California', difficulty: 2),
      WordWithDifficulty('Smells Like Teen Spirit', difficulty: 2),
      WordWithDifficulty('Billie Jean', difficulty: 2),
      WordWithDifficulty('Thriller', difficulty: 2),
      WordWithDifficulty('Beat It', difficulty: 2),
      WordWithDifficulty('Purple Rain', difficulty: 2),
      WordWithDifficulty('Sweet Child O\' Mine', difficulty: 2),
      WordWithDifficulty('Wonderwall', difficulty: 2),
      WordWithDifficulty('Lose Yourself', difficulty: 2),
      WordWithDifficulty('In Da Club', difficulty: 2),
      WordWithDifficulty('Old Town Road', difficulty: 2),

      // CHANSONS INTERNATIONALES - Difficile
      WordWithDifficulty('A Day in the Life', difficulty: 3),
      WordWithDifficulty('Good Vibrations', difficulty: 3),
      WordWithDifficulty('What\'s Going On', difficulty: 3),
      WordWithDifficulty('Superstition', difficulty: 3),
      WordWithDifficulty('Like a Rolling Stone', difficulty: 3),
      WordWithDifficulty('I Want to Hold Your Hand', difficulty: 3),
      WordWithDifficulty('God Save the Queen', difficulty: 3),
      WordWithDifficulty('London Calling', difficulty: 3),
      WordWithDifficulty('Born to Run', difficulty: 3),
      WordWithDifficulty('No Woman, No Cry', difficulty: 3),

      // GENRES MUSICAUX - Facile
      WordWithDifficulty('Pop', difficulty: 1),
      WordWithDifficulty('Rock', difficulty: 1),
      WordWithDifficulty('Rap', difficulty: 1),
      WordWithDifficulty('Jazz', difficulty: 1),
      WordWithDifficulty('Classique', difficulty: 1),
      WordWithDifficulty('Électro', difficulty: 1),
      WordWithDifficulty('Reggae', difficulty: 1),
      WordWithDifficulty('Country', difficulty: 1),

      // GENRES MUSICAUX - Moyen
      WordWithDifficulty('Hip-hop', difficulty: 2),
      WordWithDifficulty('Blues', difficulty: 2),
      WordWithDifficulty('Soul', difficulty: 2),
      WordWithDifficulty('Funk', difficulty: 2),
      WordWithDifficulty('R&B', difficulty: 2),
      WordWithDifficulty('Metal', difficulty: 2),
      WordWithDifficulty('Punk', difficulty: 2),
      WordWithDifficulty('Disco', difficulty: 2),
      WordWithDifficulty('Folk', difficulty: 2),
      WordWithDifficulty('House', difficulty: 2),
      WordWithDifficulty('Techno', difficulty: 2),
      WordWithDifficulty('Trap', difficulty: 2),
      WordWithDifficulty('Zouk', difficulty: 2),
      WordWithDifficulty('Salsa', difficulty: 2),

      // GENRES MUSICAUX - Difficile
      WordWithDifficulty('Dubstep', difficulty: 3),
      WordWithDifficulty('Drum and Bass', difficulty: 3),
      WordWithDifficulty('Hardstyle', difficulty: 3),
      WordWithDifficulty('Trance', difficulty: 3),
      WordWithDifficulty('Grunge', difficulty: 3),
      WordWithDifficulty('Hardcore', difficulty: 3),
      WordWithDifficulty('Ska', difficulty: 3),
      WordWithDifficulty('Bossa Nova', difficulty: 3),
      WordWithDifficulty('Flamenco', difficulty: 3),
      WordWithDifficulty('Gospel', difficulty: 3),
      WordWithDifficulty('Indie Rock', difficulty: 3),
      WordWithDifficulty('Afrobeat', difficulty: 3),
      WordWithDifficulty('K-pop', difficulty: 3),
      WordWithDifficulty('Drill', difficulty: 3),

      // ARTISTES ET GROUPES - Facile
      WordWithDifficulty('Beatles', difficulty: 1),
      WordWithDifficulty('Queen', difficulty: 1),
      WordWithDifficulty('Michael Jackson', difficulty: 1),
      WordWithDifficulty('Madonna', difficulty: 1),
      WordWithDifficulty('Elvis Presley', difficulty: 1),
      WordWithDifficulty('Adele', difficulty: 1),
      WordWithDifficulty('Rihanna', difficulty: 1),
      WordWithDifficulty('Beyoncé', difficulty: 1),

      // ARTISTES ET GROUPES - Moyen
      WordWithDifficulty('Pink Floyd', difficulty: 2),
      WordWithDifficulty('Led Zeppelin', difficulty: 2),
      WordWithDifficulty('Rolling Stones', difficulty: 2),
      WordWithDifficulty('Nirvana', difficulty: 2),
      WordWithDifficulty('Radiohead', difficulty: 2),
      WordWithDifficulty('Coldplay', difficulty: 2),
      WordWithDifficulty('U2', difficulty: 2),
      WordWithDifficulty('Bob Marley', difficulty: 2),
      WordWithDifficulty('David Bowie', difficulty: 2),
      WordWithDifficulty('Prince', difficulty: 2),

      // ARTISTES ET GROUPES - Difficile
      WordWithDifficulty('Velvet Underground', difficulty: 3),
      WordWithDifficulty('The Smiths', difficulty: 3),
      WordWithDifficulty('Joy Division', difficulty: 3),
      WordWithDifficulty('Sonic Youth', difficulty: 3),
      WordWithDifficulty('My Bloody Valentine', difficulty: 3),
      WordWithDifficulty('Talking Heads', difficulty: 3),

      // INSTRUMENTS DIVERS - Moyen
      WordWithDifficulty('Accordéon', difficulty: 2),
      WordWithDifficulty('Orgue', difficulty: 2),
      WordWithDifficulty('Synthétiseur', difficulty: 2),
      WordWithDifficulty('Platines', difficulty: 2),
      WordWithDifficulty('Boîte à rythmes', difficulty: 2),

      // TERMES MUSICAUX - Difficile
      WordWithDifficulty('Crescendo', difficulty: 3),
      WordWithDifficulty('Andante', difficulty: 3),
      WordWithDifficulty('Allegro', difficulty: 3),
      WordWithDifficulty('Fortissimo', difficulty: 3),
      WordWithDifficulty('Arpège', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // MÉTRO PARISIEN
  // ==========================================================================
  'metro_parisien': WordCategory(
    id: 'metro_parisien',
    name: 'Métro Parisien',
    icon: '🚇',
    words: const [
      // STATIONS CÉLÈBRES - Facile
      WordWithDifficulty('Châtelet', difficulty: 1),
      WordWithDifficulty('Gare du Nord', difficulty: 1),
      WordWithDifficulty('Gare de Lyon', difficulty: 1),
      WordWithDifficulty('République', difficulty: 1),
      WordWithDifficulty('Bastille', difficulty: 1),
      WordWithDifficulty('Nation', difficulty: 1),
      WordWithDifficulty('Opéra', difficulty: 1),
      WordWithDifficulty('Concorde', difficulty: 1),
      WordWithDifficulty('Invalides', difficulty: 1),
      WordWithDifficulty('Étoile', difficulty: 1),
      WordWithDifficulty('Trocadéro', difficulty: 1),
      WordWithDifficulty('La Défense', difficulty: 1),

      // STATIONS CENTRALES - Moyen
      WordWithDifficulty('Saint-Lazare', difficulty: 2),
      WordWithDifficulty('Montparnasse', difficulty: 2),
      WordWithDifficulty('Denfert-Rochereau', difficulty: 2),
      WordWithDifficulty('Hôtel de Ville', difficulty: 2),
      WordWithDifficulty('Réaumur-Sébastopol', difficulty: 2),
      WordWithDifficulty('Strasbourg-Saint-Denis', difficulty: 2),
      WordWithDifficulty('Barbès-Rochechouart', difficulty: 2),
      WordWithDifficulty('Belleville', difficulty: 2),
      WordWithDifficulty('Pigalle', difficulty: 2),
      WordWithDifficulty('Champs-Élysées', difficulty: 2),
      WordWithDifficulty('Franklin D. Roosevelt', difficulty: 2),
      WordWithDifficulty('Saint-Michel', difficulty: 2),
      WordWithDifficulty('Odéon', difficulty: 2),
      WordWithDifficulty('Luxembourg', difficulty: 2),
      WordWithDifficulty('Palais Royal', difficulty: 2),
      WordWithDifficulty('Louvre-Rivoli', difficulty: 2),
      WordWithDifficulty('Pyramides', difficulty: 2),
      WordWithDifficulty('Madeleine', difficulty: 2),

      // STATIONS LIGNE 1 - Moyen
      WordWithDifficulty('Esplanade de La Défense', difficulty: 2),
      WordWithDifficulty('Pont de Neuilly', difficulty: 2),
      WordWithDifficulty('Porte Maillot', difficulty: 2),
      WordWithDifficulty('Argentine', difficulty: 2),
      WordWithDifficulty('George V', difficulty: 2),
      WordWithDifficulty('Champs-Élysées-Clemenceau', difficulty: 2),
      WordWithDifficulty('Tuileries', difficulty: 2),
      WordWithDifficulty('Châtelet-Les Halles', difficulty: 2),
      WordWithDifficulty('Hôtel de Ville', difficulty: 2),
      WordWithDifficulty('Saint-Paul', difficulty: 2),
      WordWithDifficulty('Château de Vincennes', difficulty: 2),

      // STATIONS PÉRIPHÉRIQUES - Moyen
      WordWithDifficulty('Porte de Clignancourt', difficulty: 2),
      WordWithDifficulty('Porte de Versailles', difficulty: 2),
      WordWithDifficulty('Porte d\'Orléans', difficulty: 2),
      WordWithDifficulty('Porte de Bagnolet', difficulty: 2),
      WordWithDifficulty('Porte de Vincennes', difficulty: 2),
      WordWithDifficulty('Porte de Pantin', difficulty: 2),
      WordWithDifficulty('Porte de Champerret', difficulty: 2),
      WordWithDifficulty('Porte Dauphine', difficulty: 2),

      // STATIONS PITTORESQUES - Difficile
      WordWithDifficulty('Abbesses', difficulty: 3),
      WordWithDifficulty('Anvers', difficulty: 3),
      WordWithDifficulty('Blanche', difficulty: 3),
      WordWithDifficulty('Cluny-La Sorbonne', difficulty: 3),
      WordWithDifficulty('Maubert-Mutualité', difficulty: 3),
      WordWithDifficulty('Cardinal Lemoine', difficulty: 3),
      WordWithDifficulty('Jussieu', difficulty: 3),
      WordWithDifficulty('Sully-Morland', difficulty: 3),
      WordWithDifficulty('Quai de la Rapée', difficulty: 3),
      WordWithDifficulty('Bir-Hakeim', difficulty: 3),
      WordWithDifficulty('Passy', difficulty: 3),
      WordWithDifficulty('La Muette', difficulty: 3),
      WordWithDifficulty('Jasmin', difficulty: 3),
      WordWithDifficulty('Ranelagh', difficulty: 3),
      WordWithDifficulty('Michel-Ange Auteuil', difficulty: 3),
      WordWithDifficulty('Boulogne-Jean Jaurès', difficulty: 3),

      // STATIONS BANLIEUE - Difficile
      WordWithDifficulty('Créteil-Préfecture', difficulty: 3),
      WordWithDifficulty('Mairie de Montreuil', difficulty: 3),
      WordWithDifficulty('Bobigny-Pablo Picasso', difficulty: 3),
      WordWithDifficulty('Villejuif-Louis Aragon', difficulty: 3),
      WordWithDifficulty('Mairie d\'Issy', difficulty: 3),
      WordWithDifficulty('Mairie de Saint-Ouen', difficulty: 3),
      WordWithDifficulty('Gallieni', difficulty: 3),
      WordWithDifficulty('Boulogne-Pont de Saint-Cloud', difficulty: 3),

      // STATIONS CULTURELLES - Difficile
      WordWithDifficulty('Arts et Métiers', difficulty: 3),
      WordWithDifficulty('Parmentier', difficulty: 3),
      WordWithDifficulty('Voltaire', difficulty: 3),
      WordWithDifficulty('Charonne', difficulty: 3),
      WordWithDifficulty('Alexandre Dumas', difficulty: 3),
      WordWithDifficulty('Avron', difficulty: 3),
      WordWithDifficulty('Buzenval', difficulty: 3),
      WordWithDifficulty('Maraîchers', difficulty: 3),
      WordWithDifficulty('Faidherbe-Chaligny', difficulty: 3),
      WordWithDifficulty('Ledru-Rollin', difficulty: 3),
      WordWithDifficulty('Bréguet-Sabin', difficulty: 3),
      WordWithDifficulty('Chemin Vert', difficulty: 3),
      WordWithDifficulty('Saint-Sébastien-Froissart', difficulty: 3),
      WordWithDifficulty('Filles du Calvaire', difficulty: 3),
      WordWithDifficulty('Oberkampf', difficulty: 3),
      WordWithDifficulty('Temple', difficulty: 3),
      WordWithDifficulty('Rambuteau', difficulty: 3),
      WordWithDifficulty('Étienne Marcel', difficulty: 3),
      WordWithDifficulty('Sentier', difficulty: 3),
      WordWithDifficulty('Bonne Nouvelle', difficulty: 3),
      WordWithDifficulty('Poissonnière', difficulty: 3),
      WordWithDifficulty('Cadet', difficulty: 3),
      WordWithDifficulty('Le Peletier', difficulty: 3),
      WordWithDifficulty('Chaussée d\'Antin', difficulty: 3),
      WordWithDifficulty('Havre-Caumartin', difficulty: 3),
      WordWithDifficulty('Saint-Augustin', difficulty: 3),
      WordWithDifficulty('Miromesnil', difficulty: 3),
      WordWithDifficulty('Saint-Philippe du Roule', difficulty: 3),
      WordWithDifficulty('Alma-Marceau', difficulty: 3),
      WordWithDifficulty('Iéna', difficulty: 3),
      WordWithDifficulty('Boissière', difficulty: 3),
      WordWithDifficulty('Kléber', difficulty: 3),
      WordWithDifficulty('Victor Hugo', difficulty: 3),
    ],
  ),

  // ==========================================================================
  // MARQUES
  // ==========================================================================
  'marques': WordCategory(
    id: 'marques',
    name: 'Marques',
    icon: '🏷️',
    words: const [
      // MARQUES DE VÊTEMENTS - Facile
      WordWithDifficulty('Nike', difficulty: 1),
      WordWithDifficulty('Adidas', difficulty: 1),
      WordWithDifficulty('Zara', difficulty: 1),
      WordWithDifficulty('H&M', difficulty: 1),
      WordWithDifficulty('Lacoste', difficulty: 1),
      WordWithDifficulty('Puma', difficulty: 1),
      WordWithDifficulty('Converse', difficulty: 1),
      WordWithDifficulty('Vans', difficulty: 1),

      // MARQUES DE VÊTEMENTS - Moyen
      WordWithDifficulty('Ralph Lauren', difficulty: 2),
      WordWithDifficulty('Tommy Hilfiger', difficulty: 2),
      WordWithDifficulty('Calvin Klein', difficulty: 2),
      WordWithDifficulty('Levi\'s', difficulty: 2),
      WordWithDifficulty('Diesel', difficulty: 2),
      WordWithDifficulty('Gap', difficulty: 2),
      WordWithDifficulty('Uniqlo', difficulty: 2),
      WordWithDifficulty('Mango', difficulty: 2),

      // MARQUES DE LUXE - Difficile
      WordWithDifficulty('Gucci', difficulty: 3),
      WordWithDifficulty('Prada', difficulty: 3),
      WordWithDifficulty('Chanel', difficulty: 3),
      WordWithDifficulty('Louis Vuitton', difficulty: 3),
      WordWithDifficulty('Hermès', difficulty: 3),
      WordWithDifficulty('Dior', difficulty: 3),
      WordWithDifficulty('Versace', difficulty: 3),
      WordWithDifficulty('Armani', difficulty: 3),
      WordWithDifficulty('Burberry', difficulty: 3),

      // MARQUES AUTOMOBILES - Facile
      WordWithDifficulty('Renault', difficulty: 1),
      WordWithDifficulty('Peugeot', difficulty: 1),
      WordWithDifficulty('Citroën', difficulty: 1),
      WordWithDifficulty('Volkswagen', difficulty: 1),
      WordWithDifficulty('Toyota', difficulty: 1),
      WordWithDifficulty('Ford', difficulty: 1),
      WordWithDifficulty('Mercedes', difficulty: 1),
      WordWithDifficulty('BMW', difficulty: 1),

      // MARQUES AUTOMOBILES - Moyen
      WordWithDifficulty('Audi', difficulty: 2),
      WordWithDifficulty('Nissan', difficulty: 2),
      WordWithDifficulty('Honda', difficulty: 2),
      WordWithDifficulty('Mazda', difficulty: 2),
      WordWithDifficulty('Hyundai', difficulty: 2),
      WordWithDifficulty('Kia', difficulty: 2),
      WordWithDifficulty('Fiat', difficulty: 2),
      WordWithDifficulty('Seat', difficulty: 2),
      WordWithDifficulty('Skoda', difficulty: 2),
      WordWithDifficulty('Opel', difficulty: 2),

      // MARQUES AUTOMOBILES LUXE - Difficile
      WordWithDifficulty('Ferrari', difficulty: 3),
      WordWithDifficulty('Lamborghini', difficulty: 3),
      WordWithDifficulty('Porsche', difficulty: 3),
      WordWithDifficulty('Maserati', difficulty: 3),
      WordWithDifficulty('Bugatti', difficulty: 3),
      WordWithDifficulty('Bentley', difficulty: 3),
      WordWithDifficulty('Rolls-Royce', difficulty: 3),
      WordWithDifficulty('Aston Martin', difficulty: 3),

      // MARQUES TECHNOLOGIE - Facile
      WordWithDifficulty('Apple', difficulty: 1),
      WordWithDifficulty('Samsung', difficulty: 1),
      WordWithDifficulty('Microsoft', difficulty: 1),
      WordWithDifficulty('Google', difficulty: 1),
      WordWithDifficulty('Sony', difficulty: 1),
      WordWithDifficulty('LG', difficulty: 1),
      WordWithDifficulty('HP', difficulty: 1),
      WordWithDifficulty('Dell', difficulty: 1),

      // MARQUES TECHNOLOGIE - Moyen
      WordWithDifficulty('Asus', difficulty: 2),
      WordWithDifficulty('Lenovo', difficulty: 2),
      WordWithDifficulty('Acer', difficulty: 2),
      WordWithDifficulty('Philips', difficulty: 2),
      WordWithDifficulty('Panasonic', difficulty: 2),
      WordWithDifficulty('Toshiba', difficulty: 2),
      WordWithDifficulty('Huawei', difficulty: 2),
      WordWithDifficulty('Xiaomi', difficulty: 2),

      // MARQUES ALIMENTATION - Facile
      WordWithDifficulty('Coca-Cola', difficulty: 1),
      WordWithDifficulty('Pepsi', difficulty: 1),
      WordWithDifficulty('Nutella', difficulty: 1),
      WordWithDifficulty('Kinder', difficulty: 1),
      WordWithDifficulty('Haribo', difficulty: 1),
      WordWithDifficulty('Nestlé', difficulty: 1),
      WordWithDifficulty('Danone', difficulty: 1),
      WordWithDifficulty('Lu', difficulty: 1),

      // MARQUES ALIMENTATION - Moyen
      WordWithDifficulty('Mars', difficulty: 2),
      WordWithDifficulty('Snickers', difficulty: 2),
      WordWithDifficulty('Milka', difficulty: 2),
      WordWithDifficulty('Ferrero', difficulty: 2),
      WordWithDifficulty('Lindt', difficulty: 2),
      WordWithDifficulty('Pringles', difficulty: 2),
      WordWithDifficulty('Lay\'s', difficulty: 2),
      WordWithDifficulty('Oreo', difficulty: 2),
      WordWithDifficulty('KitKat', difficulty: 2),
      WordWithDifficulty('Ben & Jerry\'s', difficulty: 2),

      // MARQUES FAST-FOOD - Facile
      WordWithDifficulty('McDonald\'s', difficulty: 1),
      WordWithDifficulty('Burger King', difficulty: 1),
      WordWithDifficulty('KFC', difficulty: 1),
      WordWithDifficulty('Quick', difficulty: 1),
      WordWithDifficulty('Subway', difficulty: 1),
      WordWithDifficulty('Domino\'s', difficulty: 1),
      WordWithDifficulty('Pizza Hut', difficulty: 1),

      // MARQUES FAST-FOOD - Moyen
      WordWithDifficulty('Five Guys', difficulty: 2),
      WordWithDifficulty('Chipotle', difficulty: 2),
      WordWithDifficulty('Starbucks', difficulty: 2),
      WordWithDifficulty('Dunkin\' Donuts', difficulty: 2),

      // MAGASINS - Facile
      WordWithDifficulty('Carrefour', difficulty: 1),
      WordWithDifficulty('Auchan', difficulty: 1),
      WordWithDifficulty('Leclerc', difficulty: 1),
      WordWithDifficulty('Lidl', difficulty: 1),
      WordWithDifficulty('Ikea', difficulty: 1),
      WordWithDifficulty('Fnac', difficulty: 1),
      WordWithDifficulty('Darty', difficulty: 1),
      WordWithDifficulty('Décathlon', difficulty: 1),

      // MAGASINS - Moyen
      WordWithDifficulty('Leroy Merlin', difficulty: 2),
      WordWithDifficulty('Castorama', difficulty: 2),
      WordWithDifficulty('Boulanger', difficulty: 2),
      WordWithDifficulty('Conforama', difficulty: 2),
      WordWithDifficulty('But', difficulty: 2),
      WordWithDifficulty('Monoprix', difficulty: 2),
      WordWithDifficulty('Franprix', difficulty: 2),
      WordWithDifficulty('Intermarché', difficulty: 2),

      // MARQUES BRICOLAGE - Moyen
      WordWithDifficulty('Bosch', difficulty: 2),
      WordWithDifficulty('Makita', difficulty: 2),
      WordWithDifficulty('DeWalt', difficulty: 2),
      WordWithDifficulty('Stanley', difficulty: 2),
      WordWithDifficulty('Black & Decker', difficulty: 2),
      WordWithDifficulty('Karcher', difficulty: 2),

      // MARQUES COSMÉTIQUES - Moyen
      WordWithDifficulty('L\'Oréal', difficulty: 2),
      WordWithDifficulty('Maybelline', difficulty: 2),
      WordWithDifficulty('Nivea', difficulty: 2),
      WordWithDifficulty('Garnier', difficulty: 2),
      WordWithDifficulty('Dove', difficulty: 2),
      WordWithDifficulty('Lancôme', difficulty: 2),

      // MARQUES SPORT - Moyen
      WordWithDifficulty('Reebok', difficulty: 2),
      WordWithDifficulty('New Balance', difficulty: 2),
      WordWithDifficulty('Asics', difficulty: 2),
      WordWithDifficulty('Under Armour', difficulty: 2),
      WordWithDifficulty('The North Face', difficulty: 2),
      WordWithDifficulty('Columbia', difficulty: 2),
      WordWithDifficulty('Quiksilver', difficulty: 2),

      // MARQUES JOUETS - Moyen
      WordWithDifficulty('Lego', difficulty: 2),
      WordWithDifficulty('Playmobil', difficulty: 2),
      WordWithDifficulty('Barbie', difficulty: 2),
      WordWithDifficulty('Hot Wheels', difficulty: 2),
      WordWithDifficulty('Nerf', difficulty: 2),
      WordWithDifficulty('Fisher-Price', difficulty: 2),
    ],
  ),

  // ==========================================================================
  // MÉDECINE
  // ==========================================================================
  'medecine': WordCategory(
    id: 'medecine',
    name: 'Médecine',
    icon: '⚕️',
    words: const [
      // PARTIES DU CORPS - Facile
      WordWithDifficulty('Tête', difficulty: 1),
      WordWithDifficulty('Bras', difficulty: 1),
      WordWithDifficulty('Jambe', difficulty: 1),
      WordWithDifficulty('Main', difficulty: 1),
      WordWithDifficulty('Pied', difficulty: 1),
      WordWithDifficulty('Cœur', difficulty: 1),
      WordWithDifficulty('Poumon', difficulty: 1),
      WordWithDifficulty('Estomac', difficulty: 1),
      WordWithDifficulty('Cerveau', difficulty: 1),
      WordWithDifficulty('Œil', difficulty: 1),
      WordWithDifficulty('Oreille', difficulty: 1),
      WordWithDifficulty('Nez', difficulty: 1),
      WordWithDifficulty('Bouche', difficulty: 1),
      WordWithDifficulty('Dent', difficulty: 1),

      // PARTIES DU CORPS - Moyen
      WordWithDifficulty('Foie', difficulty: 2),
      WordWithDifficulty('Rein', difficulty: 2),
      WordWithDifficulty('Intestin', difficulty: 2),
      WordWithDifficulty('Pancréas', difficulty: 2),
      WordWithDifficulty('Rate', difficulty: 2),
      WordWithDifficulty('Vésicule', difficulty: 2),
      WordWithDifficulty('Œsophage', difficulty: 2),
      WordWithDifficulty('Trachée', difficulty: 2),
      WordWithDifficulty('Larynx', difficulty: 2),
      WordWithDifficulty('Pharynx', difficulty: 2),
      WordWithDifficulty('Colonne vertébrale', difficulty: 2),
      WordWithDifficulty('Côte', difficulty: 2),
      WordWithDifficulty('Crâne', difficulty: 2),
      WordWithDifficulty('Fémur', difficulty: 2),
      WordWithDifficulty('Tibia', difficulty: 2),
      WordWithDifficulty('Rotule', difficulty: 2),

      // PARTIES DU CORPS - Difficile
      WordWithDifficulty('Péritoine', difficulty: 3),
      WordWithDifficulty('Diaphragme', difficulty: 3),
      WordWithDifficulty('Thyroïde', difficulty: 3),
      WordWithDifficulty('Hypophyse', difficulty: 3),
      WordWithDifficulty('Hypothalamus', difficulty: 3),
      WordWithDifficulty('Thymus', difficulty: 3),
      WordWithDifficulty('Surrénale', difficulty: 3),
      WordWithDifficulty('Duodénum', difficulty: 3),
      WordWithDifficulty('Péroné', difficulty: 3),
      WordWithDifficulty('Humérus', difficulty: 3),
      WordWithDifficulty('Radius', difficulty: 3),
      WordWithDifficulty('Cubitus', difficulty: 3),
      WordWithDifficulty('Sternum', difficulty: 3),
      WordWithDifficulty('Omoplate', difficulty: 3),
      WordWithDifficulty('Clavicule', difficulty: 3),

      // MALADIES COURANTES - Facile
      WordWithDifficulty('Rhume', difficulty: 1),
      WordWithDifficulty('Grippe', difficulty: 1),
      WordWithDifficulty('Fièvre', difficulty: 1),
      WordWithDifficulty('Toux', difficulty: 1),
      WordWithDifficulty('Migraine', difficulty: 1),
      WordWithDifficulty('Angine', difficulty: 1),
      WordWithDifficulty('Gastro', difficulty: 1),
      WordWithDifficulty('Allergie', difficulty: 1),

      // MALADIES - Moyen
      WordWithDifficulty('Bronchite', difficulty: 2),
      WordWithDifficulty('Pneumonie', difficulty: 2),
      WordWithDifficulty('Asthme', difficulty: 2),
      WordWithDifficulty('Diabète', difficulty: 2),
      WordWithDifficulty('Hypertension', difficulty: 2),
      WordWithDifficulty('Arthrite', difficulty: 2),
      WordWithDifficulty('Arthrose', difficulty: 2),
      WordWithDifficulty('Appendicite', difficulty: 2),
      WordWithDifficulty('Otite', difficulty: 2),
      WordWithDifficulty('Sinusite', difficulty: 2),
      WordWithDifficulty('Conjonctivite', difficulty: 2),
      WordWithDifficulty('Gastrite', difficulty: 2),
      WordWithDifficulty('Colite', difficulty: 2),
      WordWithDifficulty('Anémie', difficulty: 2),

      // MALADIES - Difficile
      WordWithDifficulty('Méningite', difficulty: 3),
      WordWithDifficulty('Encéphalite', difficulty: 3),
      WordWithDifficulty('Pancréatite', difficulty: 3),
      WordWithDifficulty('Cirrhose', difficulty: 3),
      WordWithDifficulty('Hépatite', difficulty: 3),
      WordWithDifficulty('Néphrite', difficulty: 3),
      WordWithDifficulty('Péritonite', difficulty: 3),
      WordWithDifficulty('Myocardite', difficulty: 3),
      WordWithDifficulty('Péricardite', difficulty: 3),
      WordWithDifficulty('Thrombose', difficulty: 3),
      WordWithDifficulty('Embolie', difficulty: 3),
      WordWithDifficulty('AVC', difficulty: 3),
      WordWithDifficulty('Infarctus', difficulty: 3),
      WordWithDifficulty('Tuberculose', difficulty: 3),
      WordWithDifficulty('Sclérose en plaques', difficulty: 3),
      WordWithDifficulty('Parkinson', difficulty: 3),
      WordWithDifficulty('Alzheimer', difficulty: 3),

      // SYMPTÔMES - Facile
      WordWithDifficulty('Douleur', difficulty: 1),
      WordWithDifficulty('Fatigue', difficulty: 1),
      WordWithDifficulty('Nausée', difficulty: 1),
      WordWithDifficulty('Vertige', difficulty: 1),
      WordWithDifficulty('Éternuement', difficulty: 1),

      // SYMPTÔMES - Moyen
      WordWithDifficulty('Vomissement', difficulty: 2),
      WordWithDifficulty('Diarrhée', difficulty: 2),
      WordWithDifficulty('Constipation', difficulty: 2),
      WordWithDifficulty('Éruption', difficulty: 2),
      WordWithDifficulty('Démangeaison', difficulty: 2),
      WordWithDifficulty('Frissons', difficulty: 2),
      WordWithDifficulty('Transpiration', difficulty: 2),
      WordWithDifficulty('Essoufflement', difficulty: 2),
      WordWithDifficulty('Palpitations', difficulty: 2),

      // TRAITEMENTS ET ACTES - Moyen
      WordWithDifficulty('Piqûre', difficulty: 2),
      WordWithDifficulty('Perfusion', difficulty: 2),
      WordWithDifficulty('Injection', difficulty: 2),
      WordWithDifficulty('Pansement', difficulty: 2),
      WordWithDifficulty('Plâtre', difficulty: 2),
      WordWithDifficulty('Attelle', difficulty: 2),
      WordWithDifficulty('Radiographie', difficulty: 2),
      WordWithDifficulty('Échographie', difficulty: 2),
      WordWithDifficulty('Scanner', difficulty: 2),
      WordWithDifficulty('IRM', difficulty: 2),
      WordWithDifficulty('Prise de sang', difficulty: 2),
      WordWithDifficulty('Vaccination', difficulty: 2),

      // TRAITEMENTS - Difficile
      WordWithDifficulty('Chimiothérapie', difficulty: 3),
      WordWithDifficulty('Radiothérapie', difficulty: 3),
      WordWithDifficulty('Dialyse', difficulty: 3),
      WordWithDifficulty('Transfusion', difficulty: 3),
      WordWithDifficulty('Greffe', difficulty: 3),
      WordWithDifficulty('Transplantation', difficulty: 3),
      WordWithDifficulty('Anesthésie', difficulty: 3),
      WordWithDifficulty('Réanimation', difficulty: 3),

      // SPÉCIALITÉS MÉDICALES - Moyen
      WordWithDifficulty('Cardiologue', difficulty: 2),
      WordWithDifficulty('Dermatologue', difficulty: 2),
      WordWithDifficulty('Pneumologue', difficulty: 2),
      WordWithDifficulty('Neurologue', difficulty: 2),
      WordWithDifficulty('Pédiatre', difficulty: 2),
      WordWithDifficulty('Gynécologue', difficulty: 2),
      WordWithDifficulty('Ophtalmologue', difficulty: 2),
      WordWithDifficulty('ORL', difficulty: 2),
      WordWithDifficulty('Dentiste', difficulty: 2),
      WordWithDifficulty('Kinésithérapeute', difficulty: 2),

      // SPÉCIALITÉS MÉDICALES - Difficile
      WordWithDifficulty('Radiologue', difficulty: 3),
      WordWithDifficulty('Anesthésiste', difficulty: 3),
      WordWithDifficulty('Chirurgien', difficulty: 3),
      WordWithDifficulty('Urologue', difficulty: 3),
      WordWithDifficulty('Rhumatologue', difficulty: 3),
      WordWithDifficulty('Endocrinologue', difficulty: 3),
      WordWithDifficulty('Gastro-entérologue', difficulty: 3),
      WordWithDifficulty('Néphrologue', difficulty: 3),
      WordWithDifficulty('Hématologue', difficulty: 3),
      WordWithDifficulty('Oncologue', difficulty: 3),

      // MÉDICAMENTS - Facile
      WordWithDifficulty('Aspirine', difficulty: 1),
      WordWithDifficulty('Paracétamol', difficulty: 1),
      WordWithDifficulty('Sirop', difficulty: 1),
      WordWithDifficulty('Pommade', difficulty: 1),

      // MÉDICAMENTS - Moyen
      WordWithDifficulty('Antibiotique', difficulty: 2),
      WordWithDifficulty('Anti-inflammatoire', difficulty: 2),
      WordWithDifficulty('Antidouleur', difficulty: 2),
      WordWithDifficulty('Antitussif', difficulty: 2),
      WordWithDifficulty('Antipyrétique', difficulty: 2),
      WordWithDifficulty('Antihistaminique', difficulty: 2),

      // ÉQUIPEMENTS - Moyen
      WordWithDifficulty('Stéthoscope', difficulty: 2),
      WordWithDifficulty('Thermomètre', difficulty: 2),
      WordWithDifficulty('Tensiomètre', difficulty: 2),
      WordWithDifficulty('Scalpel', difficulty: 2),
      WordWithDifficulty('Seringue', difficulty: 2),
      WordWithDifficulty('Forceps', difficulty: 2),
      WordWithDifficulty('Bistouri', difficulty: 2),
      WordWithDifficulty('Défibrillateur', difficulty: 2),
    ],
  ),
};

// ============================================================================
// FONCTIONS UTILITAIRES
// ============================================================================

List<WordCategory> getCategoryList() {
  return wordCategories.values.toList();
}

List<String> generateWordsFromCategories(
  List<String> selectedCategories,
  int count, {
  List<int>? difficultyLevels,
}) {
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : wordCategories.keys.toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3];

  final List<String> combinedWords = [];
  for (final categoryId in categoriesToUse) {
    final category = wordCategories[categoryId];
    if (category != null) {
      combinedWords.addAll(
        category.words
            .where((w) => allowedLevels.contains(w.difficulty))
            .map((w) => w.word),
      );
    }
  }

  final random = Random();
  combinedWords.shuffle(random);

  final uniqueWords = combinedWords.toSet().toList();

  return uniqueWords.take(count).toList();
}

int getTotalWordsCount(List<String> selectedCategories, {List<int>? difficultyLevels}) {
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : wordCategories.keys.toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3];

  final Set<String> combinedWords = {};
  for (final categoryId in categoriesToUse) {
    final category = wordCategories[categoryId];
    if (category != null) {
      combinedWords.addAll(
        category.words
            .where((w) => allowedLevels.contains(w.difficulty))
            .map((w) => w.word),
      );
    }
  }

  return combinedWords.length;
}
