import 'dart:math';

class WordCategory {
  final String id;
  final String name;
  final String icon;
  final List<String> words;

  const WordCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.words,
  });
}

const Map<String, WordCategory> wordCategories = {
  'films': WordCategory(
    id: 'films',
    name: 'Films',
    icon: '🎬',
    words: [
      'Titanic', 'Avatar', 'Le Parrain', 'Star Wars', 'Jurassic Park',
      'Matrix', 'Forrest Gump', 'Pulp Fiction', 'Inception', 'Gladiator',
      'Le Seigneur des Anneaux', 'Harry Potter', 'Retour vers le futur',
      'Indiana Jones', 'Pirates des Caraïbes', 'Terminator', 'Alien',
      'Rocky', 'Le Roi Lion', 'Toy Story', 'Shrek', 'La La Land',
      'Interstellar', 'Le Silence des Agneaux', 'Les Évadés', 'Scarface',
      'Breaking Bad', 'Game of Thrones', 'Friends', 'The Office',
      'Stranger Things', 'La Casa de Papel', 'Narcos', 'Peaky Blinders',
      'E.T.', 'Jaws', 'Casablanca', 'Citizen Kane',
      'Psycho', 'Vertigo', 'Apocalypse Now', "2001 Odyssée de l'espace",
      'Blade Runner', 'Mad Max', 'Die Hard', 'Predator', 'Rambo',
      'Top Gun', 'Fast and Furious', 'Mission Impossible', 'James Bond',
      'Batman', 'Superman', 'Spider-Man', 'Iron Man', 'Avengers',
      'Black Panther', 'Joker', 'Deadpool', 'Guardians of the Galaxy',
      'Thor', 'Doctor Strange', 'Captain America', 'Ant-Man', 'Hulk',
    ],
  ),
  'pays': WordCategory(
    id: 'pays',
    name: 'Pays',
    icon: '🌍',
    words: [
      'France', 'Japon', 'Brésil', 'Australie', 'Canada',
      'Italie', 'Espagne', 'Mexique', 'Égypte', 'Inde',
      'Chine', 'États-Unis', 'Allemagne', 'Royaume-Uni', 'Russie',
      'Argentine', 'Pérou', 'Colombie', 'Chili', 'Venezuela',
      'Grèce', 'Portugal', 'Pays-Bas', 'Belgique', 'Suisse',
      'Autriche', 'Pologne', 'Roumanie', 'Hongrie', 'Tchéquie',
      'Suède', 'Norvège', 'Finlande', 'Danemark', 'Islande',
      'Irlande', 'Écosse', 'Pays de Galles', 'Turquie', 'Israël',
      'Arabie Saoudite', 'Iran', 'Irak', 'Jordanie', 'Liban',
      'Maroc', 'Algérie', 'Tunisie', 'Libye', 'Afrique du Sud',
      'Kenya', 'Éthiopie', 'Nigeria', 'Ghana', 'Sénégal',
      'Thaïlande', 'Vietnam', 'Indonésie', 'Philippines', 'Malaisie',
      'Singapour', 'Corée du Sud', 'Corée du Nord', 'Mongolie', 'Kazakhstan',
      'Nouvelle-Zélande', 'Fidji', 'Cuba', 'Jamaïque', 'Haïti',
    ],
  ),
  'animaux': WordCategory(
    id: 'animaux',
    name: 'Animaux',
    icon: '🦁',
    words: [
      'Éléphant', 'Tigre', 'Lion', 'Dauphin', 'Aigle',
      'Girafe', 'Panda', 'Kangourou', 'Pingouin', 'Renard',
      'Koala', 'Ours', 'Loup', 'Serpent', 'Crocodile',
      'Requin', 'Baleine', 'Tortue', 'Papillon', 'Abeille',
      'Coccinelle', 'Fourmi', 'Araignée', 'Scorpion', 'Sauterelle',
      'Cheval', 'Zèbre', 'Rhinocéros', 'Hippopotame', 'Guépard',
      'Léopard', 'Panthère', 'Jaguar', 'Hyène', 'Chacal',
      'Singe', 'Gorille', 'Chimpanzé', 'Orang-outan', 'Babouin',
      'Chameau', 'Dromadaire', 'Lama', 'Alpaga', 'Bison',
      'Buffle', 'Antilope', 'Gazelle', 'Cerf', 'Renne',
      'Écureuil', 'Lapin', 'Hérisson', 'Castor', 'Loutre',
      'Phoque', 'Morse', 'Otarie', 'Lion de mer', 'Manchot',
      'Flamant rose', 'Perroquet', 'Hibou', 'Faucon', 'Vautour',
      'Colibri', 'Pigeon', 'Corbeau', 'Pie', 'Mouette',
    ],
  ),
  'objets': WordCategory(
    id: 'objets',
    name: 'Objets du quotidien',
    icon: '🔧',
    words: [
      'Téléphone', 'Ordinateur', 'Chaise', 'Table', 'Stylo',
      'Lampe', 'Miroir', 'Couteau', 'Fourchette', 'Cuillère',
      'Clavier', 'Souris', 'Écran', 'Casque', 'Enceinte',
      'Canapé', 'Lit', 'Oreiller', 'Couverture', 'Matelas',
      'Armoire', 'Étagère', 'Bureau', 'Fauteuil', 'Tabouret',
      'Télévision', 'Radio', 'Horloge', 'Réveil', 'Montre',
      'Brosse à dents', 'Dentifrice', 'Savon', 'Shampoing', 'Serviette',
      'Peigne', 'Rasoir', 'Sèche-cheveux', 'Maquillage', 'Parfum',
      'Vêtements', 'Pantalon', 'T-shirt', 'Pull', 'Veste',
      'Chaussures', 'Baskets', 'Bottes', 'Sandales', 'Chaussettes',
      'Lunettes', 'Chapeau', 'Casquette', 'Écharpe', 'Gants',
      'Sac', 'Valise', 'Portefeuille', 'Clés', 'Parapluie',
      'Livre', 'Cahier', 'Crayon', 'Gomme', 'Règle',
      'Assiette', 'Verre', 'Tasse', 'Bol', 'Marmite',
    ],
  ),
  'metiers': WordCategory(
    id: 'metiers',
    name: 'Métiers',
    icon: '💼',
    words: [
      'Médecin', 'Infirmier', 'Chirurgien', 'Dentiste', 'Pharmacien',
      'Professeur', 'Instituteur', 'Directeur', 'Psychologue', 'Éducateur',
      'Pompier', 'Policier', 'Gendarme', 'Militaire', 'Garde du corps',
      'Boulanger', 'Pâtissier', 'Boucher', 'Poissonnier', 'Épicier',
      'Architecte', 'Ingénieur', 'Scientifique', 'Chercheur', 'Biologiste',
      'Plombier', 'Électricien', 'Menuisier', 'Peintre', 'Maçon',
      'Avocat', 'Juge', 'Notaire', 'Greffier', 'Huissier',
      'Journaliste', 'Reporter', 'Présentateur', 'Écrivain', 'Auteur',
      'Chef', 'Cuisinier', 'Serveur', 'Sommelier', 'Barman',
      'Acteur', 'Chanteur', 'Musicien', 'Danseur', 'Artiste',
      'Photographe', 'Vidéaste', 'Graphiste', 'Designer', 'Illustrateur',
      'Développeur', 'Programmeur', 'Informaticien', 'Webmaster', 'Hacker',
      'Comptable', 'Banquier', 'Trader', 'Économiste', 'Financier',
      "Pilote", "Hôtesse de l'air", 'Capitaine', 'Marin', 'Chauffeur',
    ],
  ),
  'sports': WordCategory(
    id: 'sports',
    name: 'Sports',
    icon: '⚽',
    words: [
      'Football', 'Tennis', 'Basketball', 'Volleyball', 'Handball',
      'Natation', 'Plongée', 'Water-polo', 'Surf', 'Voile',
      'Cyclisme', 'VTT', 'BMX', 'Motocross', 'Formule 1',
      'Boxe', 'Karaté', 'Judo', 'Taekwondo', 'Kung-fu',
      'Ski', 'Snowboard', 'Ski de fond', 'Biathlon', 'Luge',
      'Golf', 'Baseball', 'Cricket', 'Rugby', 'Football américain',
      'Escalade', 'Alpinisme', 'Randonnée', 'Trail', 'Marathon',
      'Gymnastique', 'Athlétisme', 'Saut en hauteur', 'Saut en longueur', 'Sprint',
      'Haltérophilie', 'Musculation', 'Crossfit', 'Yoga', 'Pilates',
      'Équitation', 'Polo', 'Course de chevaux', 'Dressage', "Saut d'obstacles",
      "Escrime", "Tir à l'arc", 'Tir sportif', 'Pentathlon',
      'Hockey sur glace', 'Patinage artistique', 'Curling', 'Bobsleigh', 'Skeleton',
      'Aviron', 'Canoë', 'Kayak', 'Stand-up paddle', 'Kitesurf',
      'Badminton', 'Tennis de table', 'Squash', 'Padel', 'Racquetball',
    ],
  ),
  'celebrites': WordCategory(
    id: 'celebrites',
    name: 'Célébrités',
    icon: '⭐',
    words: [
      'Einstein', 'Mozart', 'Picasso', 'Shakespeare', 'Elvis Presley',
      'Michael Jackson', 'Madonna', 'Beatles', 'Marilyn Monroe', 'Charlie Chaplin',
      'Napoléon', 'Jules César', 'Cléopâtre', 'Gandhi', 'Nelson Mandela',
      'Martin Luther King', 'Newton', 'Darwin', 'Marie Curie',
      'Leonardo da Vinci', 'Michel-Ange', 'Van Gogh', 'Monet', 'Dali',
      'Pelé', 'Maradona', 'Messi', 'Ronaldo', 'Zinedine Zidane',
      'Michael Jordan', 'Kobe Bryant', 'LeBron James', 'Tiger Woods', 'Roger Federer',
      'Muhammad Ali', 'Mike Tyson', 'Floyd Mayweather', 'Usain Bolt', 'Simone Biles',
      'Steve Jobs', 'Bill Gates', 'Elon Musk', 'Mark Zuckerberg', 'Jeff Bezos',
      'Barack Obama', 'Donald Trump', 'Joe Biden', 'Vladimir Poutine', 'Xi Jinping',
      'Queen Elizabeth', 'Lady Diana', 'Prince William', 'Kate Middleton', 'Meghan Markle',
      'Beyoncé', 'Rihanna', 'Taylor Swift', 'Lady Gaga', 'Ariana Grande',
      'Brad Pitt', 'Leonardo DiCaprio', 'Tom Cruise', 'Will Smith', 'Johnny Depp',
      'Meryl Streep', 'Scarlett Johansson', 'Jennifer Lawrence', 'Emma Watson', 'Angelina Jolie',
    ],
  ),
  'musiques': WordCategory(
    id: 'musiques',
    name: 'Noms de musiques',
    icon: '🎵',
    words: [
      'Bohemian Rhapsody', 'Imagine', 'Billie Jean', 'Smells Like Teen Spirit', 'Hey Jude',
      'Hotel California', 'Stairway to Heaven', 'Sweet Child O Mine', 'Wonderwall', 'Thriller',
      'Like a Rolling Stone', 'Let It Be', 'Yesterday', 'Come Together', 'Here Comes the Sun',
      'What a Wonderful World', 'Hallelujah', 'Bridge Over Troubled Water', 'Sound of Silence', 'Creep',
      'Karma Police', 'No Surprises', 'Fake Plastic Trees', 'High and Dry', 'Street Spirit',
      'One', 'Enter Sandman', 'Master of Puppets', 'Nothing Else Matters', 'The Unforgiven',
      "November Rain", "Don't Cry", 'Patience', "Knockin' on Heaven's Door", 'Welcome to the Jungle',
      'Purple Haze', 'All Along the Watchtower', 'Voodoo Child', 'Hey Joe', 'Little Wing',
      'Born to Run', 'Thunder Road', 'Dancing in the Dark', 'The River', 'Streets of Philadelphia',
      'Lose Yourself', 'Stan', 'Without Me', 'The Real Slim Shady', 'Not Afraid',
      'Blinding Lights', 'Starboy', 'The Hills', "Can't Feel My Face", 'Earned It',
      'Shape of You', 'Perfect', 'Thinking Out Loud', 'Photograph', 'Castle on the Hill',
      'Uptown Funk', 'Happy', 'Get Lucky', 'One More Time', 'Harder Better Faster Stronger',
      'Despacito', 'Bailando', 'La Bicicleta', 'Vivir Mi Vida', 'Danza Kuduro',
    ],
  ),
  'pokemon': WordCategory(
    id: 'pokemon',
    name: 'Pokémon',
    icon: '⚡',
    words: [
      'Pikachu', 'Raichu', 'Évoli', 'Aquali', 'Voltali',
      'Pyroli', 'Mentali', 'Noctali', 'Phyllali', 'Givrali',
      'Salamèche', 'Reptincel', 'Dracaufeu', 'Bulbizarre', 'Herbizarre',
      'Florizarre', 'Carapuce', 'Carabaffe', 'Tortank', 'Chenipan',
      'Chrysacier', 'Papilusion', 'Roucool', 'Roucoups', 'Roucarnage',
      'Rattata', 'Rattatac', 'Piafabec', 'Rapasdepic', 'Abo',
      'Arbok', 'Mélofée', 'Mélodelfe', 'Goupix',
      'Feunard', 'Rondoudou', 'Grodoudou', 'Nosferapti', 'Nosferalto',
      'Mystherbe', 'Ortide', 'Rafflesia', 'Paras', 'Parasect',
      'Mimitoss', 'Aéromite', 'Taupiqueur', 'Triopikeur', 'Miaouss',
      'Persian', 'Psykokwak', 'Akwakwak', 'Férosinge', 'Colossinge',
      'Caninos', 'Arcanin', 'Ptitard', 'Têtarte', 'Tartard',
      'Abra', 'Kadabra', 'Alakazam', 'Machoc', 'Machopeur',
      'Mackogneur', 'Chétiflor', 'Boustiflor', 'Empiflor', 'Tentacool',
      'Tentacruel', 'Racaillou', 'Gravalanch', 'Grolem', 'Ponyta',
      'Galopa', 'Ramoloss', 'Flagadoss', 'Magnéti', 'Magnéton',
      'Lugia', 'Ho-Oh', 'Celebi', 'Suicune', 'Entei',
      'Raikou', 'Kyogre', 'Groudon', 'Rayquaza', 'Latias',
      'Latios', 'Dialga', 'Palkia', 'Giratina', 'Arceus',
      'Mewtwo', 'Mew', 'Lucario', 'Gardevoir', 'Darkrai',
    ],
  ),
  'clashRoyale': WordCategory(
    id: 'clashRoyale',
    name: 'Cartes Clash Royale',
    icon: '👑',
    words: [
      'Chevalier', 'Archers', 'Goblins', 'Géant', 'P.E.K.K.A',
      'Mini P.E.K.K.A', 'Valkyrie', 'Squelettes', 'Armée de squelettes', 'Gobelins à sarbacane',
      'Chevaucheur de cochon', 'Barbares', "Barbare d'élite", 'Mousquetaire', 'Géant royal',
      'Gardes', 'Princesse', 'Prince', 'Prince noir', 'Sorcière',
      'Sorcier', 'Bébé dragon', 'Ballon', 'Gargouilles', 'Golem',
      'Géant squelette', 'Lave-hound', 'Dragon infernal', 'Tour inferno', 'Fournaise',
      'Bûcheron', 'Bandit', 'Électrocuteur', 'Bourreau', 'Méga chevalier',
      'Chasseuse', 'Maman sorcière', 'Mineur', 'Fossoyeur', 'Chevaucheur de bélier',
      'Gobelin géant', 'Sparky', 'Archer magique', 'Bombe géante', 'Canonnier',
      'Garde royale', 'Recrue royale', 'Hog rider', 'Dragons',
      'Flèches', 'Boule de feu', 'Zap', 'Foudre', 'Fusée',
      'Gel', 'Rage', 'Miroir', 'Clone', 'Poison',
      'Tremblement de terre', 'Grêle', 'Tornade', 'Guérison',
      'Canon', 'Tesla', "Tour de l'enfer", 'Cabane de gobelins', 'Tombeau',
      "Collecteur d'élixir", 'Cabane de barbare', 'Four', "Foreuse de gobelins",
      'Chevalier doré', "Princesse d'or", 'Archer reine', 'Roi squelette', 'Pêcheur',
      'Electro dragon', 'Bombardier', 'Mega Knight', 'Électro-géant', 'Golem de glace',
    ],
  ),
};

List<WordCategory> getCategoryList() {
  return wordCategories.values.toList();
}

List<String> generateWordsFromCategories(List<String> selectedCategories, int count) {
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : wordCategories.keys.toList();

  final List<String> combinedWords = [];
  for (final categoryId in categoriesToUse) {
    final category = wordCategories[categoryId];
    if (category != null) {
      combinedWords.addAll(category.words);
    }
  }

  final random = Random();
  combinedWords.shuffle(random);

  final uniqueWords = combinedWords.toSet().toList();

  return uniqueWords.take(count).toList();
}

int getTotalWordsCount(List<String> selectedCategories) {
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : wordCategories.keys.toList();

  final Set<String> combinedWords = {};
  for (final categoryId in categoriesToUse) {
    final category = wordCategories[categoryId];
    if (category != null) {
      combinedWords.addAll(category.words);
    }
  }

  return combinedWords.length;
}
