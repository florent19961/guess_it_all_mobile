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
    name: 'Films & Séries',
    icon: '🎬',
    words: [
      // Classiques
      'Titanic', 'Avatar', 'Le Parrain', 'Star Wars', 'Jurassic Park',
      'Matrix', 'Forrest Gump', 'Pulp Fiction', 'Inception', 'Gladiator',
      'Le Seigneur des Anneaux', 'Harry Potter', 'Retour vers le futur',
      'Indiana Jones', 'Pirates des Caraïbes', 'Terminator', 'Alien',
      'Rocky', 'Le Roi Lion', 'Toy Story', 'Shrek', 'La La Land',
      'Interstellar', 'Le Silence des Agneaux', 'Les Évadés', 'Scarface',
      'E.T.', 'Jaws', 'Casablanca', 'Citizen Kane',
      'Psycho', 'Vertigo', 'Apocalypse Now', "2001 Odyssée de l'espace",
      'Blade Runner', 'Mad Max', 'Die Hard', 'Predator', 'Rambo',
      'Top Gun', 'Fast and Furious', 'Mission Impossible', 'James Bond',
      // Super-héros
      'Batman', 'Superman', 'Spider-Man', 'Iron Man', 'Avengers',
      'Black Panther', 'Joker', 'Deadpool', 'Guardians of the Galaxy',
      'Thor', 'Doctor Strange', 'Captain America', 'Ant-Man', 'Hulk',
      'Wonder Woman', 'Aquaman', 'The Flash', 'Suicide Squad', 'Venom',
      // Animation
      'Ratatouille', 'Nemo', 'Vice-Versa', 'Coco', 'Monstres et Cie',
      'Wall-E', 'Les Indestructibles', 'Rebelle', 'Vaiana', 'Encanto',
      'La Reine des Neiges', 'Zootopie', 'Dragons', 'Kung Fu Panda', 'Madagascar',
      'Moi Moche et Méchant', 'Les Minions', 'Lego Movie', 'Soul', 'Là-haut',
      // Séries
      'Breaking Bad', 'Game of Thrones', 'Friends', 'The Office',
      'Stranger Things', 'La Casa de Papel', 'Narcos', 'Peaky Blinders',
      'The Walking Dead', 'Lost', 'Prison Break', 'Dexter', 'House',
      'Grey\'s Anatomy', 'How I Met Your Mother', 'The Big Bang Theory',
      'Black Mirror', 'Sherlock', 'Vikings', 'The Crown', 'Squid Game',
      'Wednesday', 'The Witcher', 'Lupin', 'Emily in Paris', 'Ozark',
      'Better Call Saul', 'The Mandalorian', 'Succession', 'The Boys',
      // Autres films
      'Fight Club', 'Seven', 'Gone Girl', 'Shutter Island', 'Memento',
      'The Departed', 'Goodfellas', 'Casino', 'Heat', 'The Godfather',
      'Schindler\'s List', 'Braveheart', 'Saving Private Ryan', 'Dunkirk',
      'The Dark Knight', 'Logan', 'John Wick', 'Kill Bill', 'Django',
    ],
  ),
  'pays': WordCategory(
    id: 'pays',
    name: 'Pays & Villes',
    icon: '🌍',
    words: [
      // Europe
      'France', 'Allemagne', 'Italie', 'Espagne', 'Portugal',
      'Royaume-Uni', 'Irlande', 'Belgique', 'Pays-Bas', 'Suisse',
      'Autriche', 'Pologne', 'Roumanie', 'Hongrie', 'Tchéquie',
      'Suède', 'Norvège', 'Finlande', 'Danemark', 'Islande',
      'Grèce', 'Croatie', 'Slovénie', 'Slovaquie', 'Bulgarie',
      'Serbie', 'Ukraine', 'Russie', 'Biélorussie', 'Moldavie',
      'Estonie', 'Lettonie', 'Lituanie', 'Luxembourg', 'Monaco',
      'Malte', 'Chypre', 'Albanie', 'Monténégro', 'Macédoine',
      // Amériques
      'États-Unis', 'Canada', 'Mexique', 'Brésil', 'Argentine',
      'Chili', 'Pérou', 'Colombie', 'Venezuela', 'Équateur',
      'Bolivie', 'Paraguay', 'Uruguay', 'Cuba', 'Jamaïque',
      'Haïti', 'République Dominicaine', 'Panama', 'Costa Rica', 'Guatemala',
      // Asie
      'Chine', 'Japon', 'Corée du Sud', 'Corée du Nord', 'Inde',
      'Thaïlande', 'Vietnam', 'Indonésie', 'Philippines', 'Malaisie',
      'Singapour', 'Mongolie', 'Kazakhstan', 'Pakistan', 'Bangladesh',
      'Sri Lanka', 'Népal', 'Birmanie', 'Cambodge', 'Laos',
      'Taiwan', 'Hong Kong', 'Macao', 'Ouzbékistan', 'Turkménistan',
      // Moyen-Orient
      'Turquie', 'Israël', 'Arabie Saoudite', 'Iran', 'Irak',
      'Jordanie', 'Liban', 'Syrie', 'Yémen', 'Oman',
      'Émirats arabes unis', 'Qatar', 'Koweït', 'Bahreïn', 'Afghanistan',
      // Afrique
      'Maroc', 'Algérie', 'Tunisie', 'Libye', 'Égypte',
      'Afrique du Sud', 'Kenya', 'Éthiopie', 'Nigeria', 'Ghana',
      'Sénégal', 'Côte d\'Ivoire', 'Cameroun', 'Congo', 'Angola',
      'Mozambique', 'Madagascar', 'Zimbabwe', 'Tanzanie', 'Ouganda',
      // Océanie
      'Australie', 'Nouvelle-Zélande', 'Fidji', 'Papouasie', 'Samoa',
      // Grandes villes
      'Paris', 'Londres', 'New York', 'Tokyo', 'Pékin',
      'Moscou', 'Berlin', 'Rome', 'Madrid', 'Amsterdam',
    ],
  ),
  'animaux': WordCategory(
    id: 'animaux',
    name: 'Animaux',
    icon: '🦁',
    words: [
      // Félins
      'Lion', 'Tigre', 'Léopard', 'Panthère', 'Jaguar',
      'Guépard', 'Lynx', 'Puma', 'Ocelot', 'Chat sauvage',
      // Canidés
      'Loup', 'Renard', 'Chacal', 'Coyote', 'Hyène',
      'Chien', 'Fennec', 'Dingo', 'Lycaon', 'Chien de prairie',
      // Grands mammifères
      'Éléphant', 'Girafe', 'Rhinocéros', 'Hippopotame', 'Zèbre',
      'Chameau', 'Dromadaire', 'Bison', 'Buffle', 'Yak',
      'Cerf', 'Renne', 'Élan', 'Antilope', 'Gazelle',
      // Primates
      'Gorille', 'Chimpanzé', 'Orang-outan', 'Babouin', 'Macaque',
      'Gibbon', 'Mandrill', 'Ouistiti', 'Capucin', 'Lémurien',
      // Ours
      'Ours brun', 'Ours polaire', 'Panda', 'Koala', 'Grizzly',
      // Marins
      'Dauphin', 'Baleine', 'Orque', 'Requin', 'Otarie',
      'Phoque', 'Morse', 'Lamantin', 'Narval', 'Béluga',
      'Raie', 'Méduse', 'Pieuvre', 'Calmar', 'Hippocampe',
      // Reptiles
      'Crocodile', 'Alligator', 'Tortue', 'Serpent', 'Lézard',
      'Caméléon', 'Iguane', 'Cobra', 'Python', 'Anaconda',
      'Varan', 'Gecko', 'Salamandre', 'Triton', 'Axolotl',
      // Oiseaux
      'Aigle', 'Faucon', 'Hibou', 'Chouette', 'Vautour',
      'Perroquet', 'Toucan', 'Flamant rose', 'Pélican', 'Pingouin',
      'Manchot', 'Autruche', 'Émeu', 'Paon', 'Colibri',
      'Corbeau', 'Pie', 'Mouette', 'Albatros', 'Condor',
      // Petits mammifères
      'Lapin', 'Écureuil', 'Hérisson', 'Castor', 'Loutre',
      'Raton laveur', 'Blaireau', 'Furet', 'Belette', 'Hermine',
      'Taupe', 'Chauve-souris', 'Hamster', 'Gerbille', 'Chinchilla',
      // Australiens
      'Kangourou', 'Wallaby', 'Wombat', 'Ornithorynque', 'Échidné',
      'Diable de Tasmanie', 'Kiwi', 'Casoar', 'Quokka', 'Numbat',
      // Insectes
      'Papillon', 'Abeille', 'Fourmi', 'Coccinelle', 'Libellule',
      'Scarabée', 'Mante religieuse', 'Sauterelle', 'Criquet', 'Cigale',
    ],
  ),
  'objets': WordCategory(
    id: 'objets',
    name: 'Objets du quotidien',
    icon: '🔧',
    words: [
      // Électronique
      'Téléphone', 'Ordinateur', 'Tablette', 'Télévision', 'Radio',
      'Clavier', 'Souris', 'Écran', 'Casque', 'Enceinte',
      'Chargeur', 'Câble USB', 'Disque dur', 'Clé USB', 'Webcam',
      'Console', 'Manette', 'Télécommande', 'Drone', 'Appareil photo',
      // Mobilier
      'Chaise', 'Table', 'Bureau', 'Canapé', 'Fauteuil',
      'Lit', 'Armoire', 'Étagère', 'Commode', 'Bibliothèque',
      'Tabouret', 'Banc', 'Pouf', 'Matelas', 'Oreiller',
      'Couverture', 'Drap', 'Tapis', 'Rideau', 'Miroir',
      // Cuisine
      'Couteau', 'Fourchette', 'Cuillère', 'Assiette', 'Verre',
      'Tasse', 'Bol', 'Marmite', 'Poêle', 'Casserole',
      'Four', 'Micro-ondes', 'Réfrigérateur', 'Grille-pain', 'Mixeur',
      'Bouilloire', 'Cafetière', 'Passoire', 'Louche', 'Spatule',
      'Planche à découper', 'Économe', 'Ouvre-boîte', 'Tire-bouchon', 'Fouet',
      // Salle de bain
      'Brosse à dents', 'Dentifrice', 'Savon', 'Shampoing', 'Serviette',
      'Peigne', 'Brosse', 'Rasoir', 'Sèche-cheveux', 'Miroir',
      'Baignoire', 'Douche', 'Lavabo', 'Toilettes', 'Bidet',
      // Vêtements
      'Pantalon', 'Jean', 'T-shirt', 'Chemise', 'Pull',
      'Veste', 'Manteau', 'Robe', 'Jupe', 'Short',
      'Chaussures', 'Baskets', 'Bottes', 'Sandales', 'Chaussettes',
      'Cravate', 'Ceinture', 'Chapeau', 'Casquette', 'Écharpe',
      'Gants', 'Bonnet', 'Lunettes', 'Montre', 'Bijoux',
      // Bureau
      'Stylo', 'Crayon', 'Gomme', 'Règle', 'Cahier',
      'Classeur', 'Agrafeuse', 'Trombones', 'Ciseaux', 'Scotch',
      'Enveloppe', 'Timbre', 'Calendrier', 'Post-it', 'Surligneur',
      // Autres
      'Parapluie', 'Sac', 'Valise', 'Portefeuille', 'Clés',
      'Lampe', 'Horloge', 'Réveil', 'Bougie', 'Vase',
    ],
  ),
  'metiers': WordCategory(
    id: 'metiers',
    name: 'Métiers',
    icon: '💼',
    words: [
      // Santé
      'Médecin', 'Infirmier', 'Chirurgien', 'Dentiste', 'Pharmacien',
      'Vétérinaire', 'Kinésithérapeute', 'Ostéopathe', 'Psychologue', 'Psychiatre',
      'Sage-femme', 'Aide-soignant', 'Ambulancier', 'Radiologue', 'Cardiologue',
      'Dermatologue', 'Ophtalmologue', 'Pédiatre', 'Gynécologue', 'Anesthésiste',
      // Éducation
      'Professeur', 'Instituteur', 'Directeur', 'Proviseur', 'Surveillant',
      'Éducateur', 'Formateur', 'Moniteur', 'Animateur', 'Bibliothécaire',
      // Sécurité
      'Pompier', 'Policier', 'Gendarme', 'Militaire', 'Garde du corps',
      'Agent de sécurité', 'Douanier', 'Gardien de prison', 'Maître-nageur', 'Secouriste',
      // Alimentation
      'Boulanger', 'Pâtissier', 'Boucher', 'Poissonnier', 'Fromager',
      'Chef cuisinier', 'Serveur', 'Barman', 'Sommelier', 'Traiteur',
      'Chocolatier', 'Glacier', 'Caviste', 'Épicier', 'Primeur',
      // Construction
      'Architecte', 'Maçon', 'Plombier', 'Électricien', 'Menuisier',
      'Peintre', 'Carreleur', 'Couvreur', 'Charpentier', 'Serrurier',
      'Vitrier', 'Plâtrier', 'Chauffagiste', 'Soudeur', 'Grutier',
      // Juridique
      'Avocat', 'Juge', 'Notaire', 'Greffier', 'Huissier',
      'Magistrat', 'Procureur', 'Clerc', 'Juriste', 'Médiateur',
      // Arts et médias
      'Acteur', 'Chanteur', 'Musicien', 'Danseur', 'Réalisateur',
      'Producteur', 'Scénariste', 'Cadreur', 'Monteur', 'Ingénieur du son',
      'Journaliste', 'Présentateur', 'Photographe', 'Graphiste', 'Designer',
      'Illustrateur', 'Sculpteur', 'Peintre', 'Écrivain', 'Poète',
      // Tech
      'Développeur', 'Programmeur', 'Informaticien', 'Data scientist', 'DevOps',
      'Chef de projet', 'Product manager', 'UX designer', 'Administrateur réseau', 'Technicien',
      // Finance
      'Comptable', 'Banquier', 'Trader', 'Économiste', 'Analyste',
      'Assureur', 'Courtier', 'Audit', 'Contrôleur de gestion', 'Fiscaliste',
      // Transport
      'Pilote', 'Hôtesse de l\'air', 'Steward', 'Chauffeur', 'Conducteur',
      'Capitaine', 'Marin', 'Mécanicien', 'Garagiste', 'Taxi',
    ],
  ),
  'sports': WordCategory(
    id: 'sports',
    name: 'Sports',
    icon: '⚽',
    words: [
      // Sports collectifs
      'Football', 'Basketball', 'Volleyball', 'Handball', 'Rugby',
      'Football américain', 'Hockey sur glace', 'Hockey sur gazon', 'Water-polo', 'Polo',
      'Baseball', 'Softball', 'Cricket', 'Lacrosse', 'Ultimate frisbee',
      // Raquettes
      'Tennis', 'Badminton', 'Tennis de table', 'Squash', 'Padel',
      'Racquetball', 'Pelote basque', 'Pickleball', 'Beach tennis', 'Speedminton',
      // Sports nautiques
      'Natation', 'Plongée', 'Surf', 'Voile', 'Aviron',
      'Canoë', 'Kayak', 'Stand-up paddle', 'Kitesurf', 'Wakeboard',
      'Ski nautique', 'Planche à voile', 'Jet ski', 'Rafting', 'Apnée',
      // Sports d\'hiver
      'Ski alpin', 'Snowboard', 'Ski de fond', 'Biathlon', 'Luge',
      'Bobsleigh', 'Skeleton', 'Patinage artistique', 'Patinage de vitesse', 'Curling',
      'Hockey sur glace', 'Saut à ski', 'Combiné nordique', 'Freestyle', 'Freeride',
      // Arts martiaux
      'Boxe', 'Karaté', 'Judo', 'Taekwondo', 'Kung-fu',
      'MMA', 'Kickboxing', 'Muay-thaï', 'Aïkido', 'Jiu-jitsu',
      'Lutte', 'Sumo', 'Capoeira', 'Krav-maga', 'Sambo',
      // Athlétisme
      'Sprint', 'Marathon', 'Saut en hauteur', 'Saut en longueur', 'Triple saut',
      'Saut à la perche', 'Lancer de poids', 'Lancer de disque', 'Lancer de javelot', 'Lancer de marteau',
      'Décathlon', 'Heptathlon', 'Course de haies', 'Relais', 'Marche athlétique',
      // Cyclisme
      'Cyclisme sur route', 'VTT', 'BMX', 'Cyclisme sur piste', 'Cyclo-cross',
      // Motorisés
      'Formule 1', 'MotoGP', 'Rallye', 'Motocross', 'Karting',
      'Endurance', 'Nascar', 'IndyCar', 'Superbike', 'Trial',
      // Autres
      'Golf', 'Escalade', 'Alpinisme', 'Gymnastique', 'Trampoline',
      'Haltérophilie', 'Musculation', 'Crossfit', 'Yoga', 'Pilates',
      'Équitation', 'Escrime', 'Tir à l\'arc', 'Tir sportif', 'Pentathlon',
      'Triathlon', 'Parkour', 'Skateboard', 'Roller', 'Parachutisme',
    ],
  ),
  'celebrites': WordCategory(
    id: 'celebrites',
    name: 'Célébrités',
    icon: '⭐',
    words: [
      // Scientifiques
      'Einstein', 'Newton', 'Darwin', 'Marie Curie', 'Galilée',
      'Pasteur', 'Tesla', 'Hawking', 'Copernic', 'Archimède',
      // Artistes historiques
      'Mozart', 'Beethoven', 'Bach', 'Chopin', 'Vivaldi',
      'Picasso', 'Van Gogh', 'Monet', 'Da Vinci', 'Michel-Ange',
      'Dali', 'Rembrandt', 'Renoir', 'Vermeer', 'Cézanne',
      // Écrivains
      'Shakespeare', 'Victor Hugo', 'Molière', 'Voltaire', 'Balzac',
      'Hemingway', 'Tolkien', 'Agatha Christie', 'Stephen King', 'J.K. Rowling',
      // Politiques historiques
      'Napoléon', 'Jules César', 'Cléopâtre', 'Alexandre le Grand', 'Louis XIV',
      'Gandhi', 'Nelson Mandela', 'Martin Luther King', 'Abraham Lincoln', 'Winston Churchill',
      'Charles de Gaulle', 'Jeanne d\'Arc', 'Che Guevara', 'Kennedy', 'Roosevelt',
      // Chanteurs
      'Elvis Presley', 'Michael Jackson', 'Madonna', 'Prince', 'David Bowie',
      'Freddie Mercury', 'John Lennon', 'Bob Marley', 'Whitney Houston', 'Aretha Franklin',
      'Beyoncé', 'Rihanna', 'Taylor Swift', 'Lady Gaga', 'Ariana Grande',
      'Eminem', 'Drake', 'Kanye West', 'Ed Sheeran', 'Adele',
      'Céline Dion', 'Édith Piaf', 'Johnny Hallyday', 'Stromae', 'Daft Punk',
      // Acteurs
      'Marilyn Monroe', 'Charlie Chaplin', 'Audrey Hepburn', 'James Dean', 'Marlon Brando',
      'Brad Pitt', 'Leonardo DiCaprio', 'Tom Cruise', 'Will Smith', 'Johnny Depp',
      'Tom Hanks', 'Robert De Niro', 'Al Pacino', 'Morgan Freeman', 'Denzel Washington',
      'Meryl Streep', 'Scarlett Johansson', 'Jennifer Lawrence', 'Angelina Jolie', 'Emma Watson',
      'Jean Dujardin', 'Omar Sy', 'Marion Cotillard', 'Gérard Depardieu', 'Alain Delon',
      // Sportifs
      'Pelé', 'Maradona', 'Messi', 'Ronaldo', 'Zinedine Zidane',
      'Mbappé', 'Neymar', 'Benzema', 'Thierry Henry', 'Platini',
      'Michael Jordan', 'Kobe Bryant', 'LeBron James', 'Shaquille O\'Neal', 'Magic Johnson',
      'Roger Federer', 'Nadal', 'Djokovic', 'Serena Williams', 'Tiger Woods',
      'Muhammad Ali', 'Mike Tyson', 'Usain Bolt', 'Michael Phelps', 'Simone Biles',
      // Tech
      'Steve Jobs', 'Bill Gates', 'Elon Musk', 'Mark Zuckerberg', 'Jeff Bezos',
    ],
  ),
  'musiques': WordCategory(
    id: 'musiques',
    name: 'Titres de musiques',
    icon: '🎵',
    words: [
      // Rock classique
      'Bohemian Rhapsody', 'Stairway to Heaven', 'Hotel California', 'Smoke on the Water', 'Back in Black',
      'Sweet Child O Mine', 'November Rain', 'Comfortably Numb', 'Free Bird', 'Dream On',
      'Livin\' on a Prayer', 'Enter Sandman', 'Nothing Else Matters', 'One', 'Master of Puppets',
      'Highway to Hell', 'Thunderstruck', 'You Shook Me All Night Long', 'T.N.T.', 'Whole Lotta Rosie',
      // Pop
      'Billie Jean', 'Thriller', 'Beat It', 'Smooth Criminal', 'Bad',
      'Like a Virgin', 'Material Girl', 'Vogue', 'Hung Up', 'Like a Prayer',
      'Shape of You', 'Perfect', 'Thinking Out Loud', 'Photograph', 'Castle on the Hill',
      'Blinding Lights', 'Starboy', 'The Hills', 'Can\'t Feel My Face', 'Save Your Tears',
      'Bad Guy', 'Lovely', 'Ocean Eyes', 'Everything I Wanted', 'Happier Than Ever',
      // Beatles
      'Hey Jude', 'Let It Be', 'Yesterday', 'Come Together', 'Here Comes the Sun',
      'Help!', 'A Hard Day\'s Night', 'Twist and Shout', 'All You Need Is Love', 'Yellow Submarine',
      // Hip-hop/Rap
      'Lose Yourself', 'Stan', 'Without Me', 'The Real Slim Shady', 'Not Afraid',
      'Hotline Bling', 'God\'s Plan', 'In My Feelings', 'One Dance', 'Started From the Bottom',
      'Humble', 'DNA', 'Alright', 'Swimming Pools', 'Money Trees',
      // Dance/Électro
      'Get Lucky', 'One More Time', 'Around the World', 'Harder Better Faster Stronger', 'Da Funk',
      'Titanium', 'Levels', 'Wake Me Up', 'Don\'t You Worry Child', 'Clarity',
      // Français
      'La Vie en Rose', 'Non, je ne regrette rien', 'Comme d\'habitude', 'Ne me quitte pas', 'Je t\'aime',
      'Papaoutai', 'Formidable', 'Alors on danse', 'Tous les mêmes', 'Sommeil',
      'Je veux', 'La Bohème', 'Les Champs-Élysées', 'Comme toi', 'L\'Aziza',
      // Latino
      'Despacito', 'La Bamba', 'Macarena', 'Bailando', 'Danza Kuduro',
      'Waka Waka', 'Hips Don\'t Lie', 'Whenever Wherever', 'La Tortura', 'Chantaje',
      // Autres classiques
      'Imagine', 'What a Wonderful World', 'Hallelujah', 'Sound of Silence', 'Bridge Over Troubled Water',
      'Wonderwall', 'Creep', 'Smells Like Teen Spirit', 'Come As You Are', 'Heart-Shaped Box',
      'Purple Rain', 'Kiss', 'When Doves Cry', 'Little Red Corvette', '1999',
      'Africa', 'Take on Me', 'Sweet Dreams', 'Don\'t Stop Believin\'', 'Eye of the Tiger',
    ],
  ),
  'pokemon': WordCategory(
    id: 'pokemon',
    name: 'Pokémon',
    icon: '⚡',
    words: [
      // Starters et évolutions Gen 1
      'Bulbizarre', 'Herbizarre', 'Florizarre', 'Salamèche', 'Reptincel',
      'Dracaufeu', 'Carapuce', 'Carabaffe', 'Tortank', 'Pikachu',
      'Raichu', 'Évoli', 'Aquali', 'Voltali', 'Pyroli',
      // Évolutions Évoli
      'Mentali', 'Noctali', 'Phyllali', 'Givrali', 'Nymphali',
      // Gen 1 populaires
      'Rondoudou', 'Grodoudou', 'Mélofée', 'Mélodelfe', 'Miaouss',
      'Persian', 'Psykokwak', 'Akwakwak', 'Machoc', 'Machopeur',
      'Mackogneur', 'Abra', 'Kadabra', 'Alakazam', 'Fantominus',
      'Spectrum', 'Ectoplasma', 'Onix', 'Steelix', 'Ronflex',
      'Magicarpe', 'Léviator', 'Lokhlass', 'Métamorph', 'Dracolosse',
      'Artikodin', 'Électhor', 'Sulfura', 'Mewtwo', 'Mew',
      // Gen 2
      'Germignon', 'Macronium', 'Méganium', 'Héricendre', 'Feurisson',
      'Typhlosion', 'Kaiminus', 'Crocodil', 'Aligatueur', 'Pichu',
      'Togepi', 'Togetic', 'Marill', 'Azumarill', 'Capumain',
      'Tournegrin', 'Héliatronc', 'Queulorior', 'Scarhino', 'Teddiursa',
      'Ursaring', 'Porygon2', 'Cerfrousse', 'Élekid', 'Magby',
      'Lugia', 'Ho-Oh', 'Celebi', 'Suicune', 'Entei', 'Raikou',
      // Gen 3
      'Arcko', 'Massko', 'Jungko', 'Poussifeu', 'Galifeu',
      'Braségali', 'Gobou', 'Flobio', 'Laggron', 'Tarsal',
      'Kirlia', 'Gardevoir', 'Gallame', 'Ténéfix', 'Mysdibule',
      'Absol', 'Kyogre', 'Groudon', 'Rayquaza', 'Latias', 'Latios',
      // Gen 4
      'Tortipouss', 'Boskara', 'Torterra', 'Ouisticram', 'Chimpenfeu',
      'Simiabraz', 'Tiplouf', 'Prinplouf', 'Pingoléon', 'Lucario',
      'Carchacrok', 'Dialga', 'Palkia', 'Giratina', 'Arceus', 'Darkrai',
      // Gen 5+
      'Victini', 'Zoroark', 'Reshiram', 'Zekrom', 'Kyurem',
      'Genesect', 'Xerneas', 'Yveltal', 'Zygarde', 'Solgaleo',
      'Lunala', 'Necrozma', 'Zeraora', 'Zacian', 'Zamazenta',
      'Éternatus', 'Sylveroy', 'Miraidon', 'Koraidon', 'Gholdengo',
    ],
  ),
  'clashRoyale': WordCategory(
    id: 'clashRoyale',
    name: 'Clash Royale',
    icon: '👑',
    words: [
      // Troupes communes
      'Chevalier', 'Archers', 'Goblins', 'Géant', 'Mousquetaire',
      'Mini P.E.K.K.A', 'Valkyrie', 'Squelettes', 'Armée de squelettes', 'Barbares',
      'Gobelins à sarbacane', 'Bombardier', 'Lèche-bottes', 'Servantes', 'Mégaservante',
      'Gobelin d\'élite', 'Barbare d\'élite', 'Recrue royale', 'Garde royale', 'Canon à squelettes',
      // Troupes rares
      'Chevaucheur de cochon', 'Sorcier', 'Bébé dragon', 'Golem', 'Prince',
      'Géant squelette', 'Ballon', 'Gargouilles', 'Sorcière', 'Méga gargouille',
      'Dragons de feu', 'Cochons royaux', 'Voleur', 'Électrocuteur', 'Boulet de canon',
      'Géant royal', 'Éléments de guérison', 'Trois mousquetaires', 'Machine volante', 'Foreuse de goblins',
      // Troupes épiques
      'P.E.K.K.A', 'Prince noir', 'Ballon squelette', 'Golem de glace', 'Chasseuse',
      'Bourreau', 'Dragon infernal', 'Lave-hound', 'Électro-dragon', 'Méga chevalier',
      'Chevaucheur de bélier', 'Fossoyeur', 'Canon à canon', 'Gobelin géant', 'Maman sorcière',
      // Troupes légendaires
      'Princesse', 'Bûcheron', 'Bandit', 'Mineur', 'Fantôme royal',
      'Électro-géant', 'Sparky', 'Archer magique', 'Roi squelette', 'Pêcheur',
      'Ram rider', 'Méga chevalier', 'Moine', 'Phénix', 'Mighty miner',
      // Champions
      'Archer reine', 'Chevalier doré', 'Princesse squelette', 'Super mineur', 'Petit prince',
      // Sorts
      'Flèches', 'Boule de feu', 'Zap', 'Foudre', 'Fusée',
      'Gel', 'Rage', 'Poison', 'Tremblement de terre', 'Tornade',
      'Clone', 'Miroir', 'Grêle', 'Tempête de neige', 'Guérison royale',
      'Livraison royale', 'Gobelin en baril', 'Tronc', 'Esprit de feu', 'Esprit de glace',
      'Esprit électrique', 'Chauve-souris', 'Guérison', 'Boule de neige géante', 'Tremblement royal',
      // Bâtiments
      'Canon', 'Tesla', 'Tour de l\'enfer', 'Tour de bombes', 'Mortier',
      'Cabane de gobelins', 'Tombeau', 'Cabane de barbares', 'Fournaise', 'Four à gobelins',
      'Collecteur d\'élixir', 'Tour à arc', 'Gobelin drilling', 'Cage de gobelins', 'Princess tower',
    ],
  ),
  'nourriture': WordCategory(
    id: 'nourriture',
    name: 'Nourriture',
    icon: '🍕',
    words: [
      // Fruits
      'Pomme', 'Banane', 'Orange', 'Fraise', 'Cerise',
      'Raisin', 'Pêche', 'Abricot', 'Poire', 'Kiwi',
      'Mangue', 'Ananas', 'Pastèque', 'Melon', 'Citron',
      'Pamplemousse', 'Framboise', 'Myrtille', 'Mûre', 'Grenade',
      // Légumes
      'Carotte', 'Tomate', 'Salade', 'Concombre', 'Courgette',
      'Aubergine', 'Poivron', 'Oignon', 'Ail', 'Pomme de terre',
      'Haricot', 'Petit pois', 'Brocoli', 'Chou-fleur', 'Épinard',
      'Champignon', 'Asperge', 'Artichaut', 'Betterave', 'Navet',
      // Viandes
      'Bœuf', 'Poulet', 'Porc', 'Agneau', 'Canard',
      'Dinde', 'Lapin', 'Veau', 'Saucisse', 'Jambon',
      'Bacon', 'Steak', 'Côtelette', 'Escalope', 'Rôti',
      // Poissons et fruits de mer
      'Saumon', 'Thon', 'Cabillaud', 'Sardine', 'Maquereau',
      'Crevette', 'Homard', 'Crabe', 'Moule', 'Huître',
      'Calamars', 'Poulpe', 'Saint-Jacques', 'Truite', 'Bar',
      // Plats
      'Pizza', 'Burger', 'Pâtes', 'Risotto', 'Paella',
      'Sushi', 'Ramen', 'Curry', 'Tacos', 'Kebab',
      'Couscous', 'Tajine', 'Raclette', 'Fondue', 'Tartiflette',
      'Quiche', 'Gratin', 'Lasagnes', 'Crêpe', 'Gaufre',
      // Desserts
      'Gâteau', 'Tarte', 'Mousse au chocolat', 'Crème brûlée', 'Tiramisu',
      'Macaron', 'Éclair', 'Mille-feuille', 'Profiterole', 'Brownie',
      'Cookie', 'Cheesecake', 'Pancake', 'Glace', 'Sorbet',
      // Fromages
      'Camembert', 'Brie', 'Roquefort', 'Comté', 'Gruyère',
      'Mozzarella', 'Parmesan', 'Cheddar', 'Feta', 'Chèvre',
      // Boissons
      'Café', 'Thé', 'Chocolat chaud', 'Jus d\'orange', 'Smoothie',
      'Limonade', 'Coca-Cola', 'Bière', 'Vin', 'Champagne',
    ],
  ),
  'marques': WordCategory(
    id: 'marques',
    name: 'Marques',
    icon: '🏷️',
    words: [
      // Tech
      'Apple', 'Samsung', 'Google', 'Microsoft', 'Amazon',
      'Sony', 'Nintendo', 'PlayStation', 'Xbox', 'Tesla',
      'Intel', 'AMD', 'Nvidia', 'HP', 'Dell',
      'Lenovo', 'Asus', 'LG', 'Huawei', 'Xiaomi',
      // Automobile
      'Ferrari', 'Lamborghini', 'Porsche', 'Mercedes', 'BMW',
      'Audi', 'Volkswagen', 'Toyota', 'Honda', 'Ford',
      'Renault', 'Peugeot', 'Citroën', 'Fiat', 'Jeep',
      'Maserati', 'Bugatti', 'Bentley', 'Rolls-Royce', 'Aston Martin',
      // Mode
      'Nike', 'Adidas', 'Puma', 'Reebok', 'New Balance',
      'Louis Vuitton', 'Gucci', 'Chanel', 'Dior', 'Hermès',
      'Prada', 'Versace', 'Armani', 'Balenciaga', 'Burberry',
      'Zara', 'H&M', 'Uniqlo', 'Gap', 'Levi\'s',
      // Alimentaire
      'Coca-Cola', 'Pepsi', 'McDonald\'s', 'Burger King', 'KFC',
      'Starbucks', 'Nutella', 'Danone', 'Nestlé', 'Kellogg\'s',
      'Heinz', 'Oreo', 'M&M\'s', 'Haribo', 'Red Bull',
      // Cosmétiques
      'L\'Oréal', 'Nivea', 'Maybelline', 'MAC', 'Sephora',
      'Lancôme', 'Estée Lauder', 'Clinique', 'Dove', 'Garnier',
      // Luxe et bijoux
      'Rolex', 'Cartier', 'Tiffany', 'Swarovski', 'Pandora',
      'Omega', 'Tag Heuer', 'Patek Philippe', 'Bulgari', 'Chopard',
      // Autres
      'IKEA', 'Lego', 'Disney', 'Netflix', 'Spotify',
      'Instagram', 'TikTok', 'YouTube', 'Twitter', 'Facebook',
      'Uber', 'Airbnb', 'PayPal', 'Visa', 'Mastercard',
    ],
  ),
  'jeux_video': WordCategory(
    id: 'jeux_video',
    name: 'Jeux vidéo',
    icon: '🎮',
    words: [
      // Franchises Nintendo
      'Mario', 'Zelda', 'Pokémon', 'Metroid', 'Kirby',
      'Donkey Kong', 'Animal Crossing', 'Splatoon', 'Fire Emblem', 'Super Smash Bros',
      'Mario Kart', 'Luigi\'s Mansion', 'Star Fox', 'F-Zero', 'Pikmin',
      // PlayStation
      'God of War', 'The Last of Us', 'Uncharted', 'Spider-Man', 'Horizon',
      'Ghost of Tsushima', 'Gran Turismo', 'Ratchet & Clank', 'LittleBigPlanet', 'Infamous',
      // Xbox
      'Halo', 'Gears of War', 'Forza', 'Fable', 'Sea of Thieves',
      // Multi-plateformes AAA
      'GTA', 'Red Dead Redemption', 'Call of Duty', 'Battlefield', 'FIFA',
      'Assassin\'s Creed', 'Far Cry', 'Watch Dogs', 'The Witcher', 'Cyberpunk',
      'Dark Souls', 'Elden Ring', 'Sekiro', 'Bloodborne', 'Demon\'s Souls',
      'Final Fantasy', 'Kingdom Hearts', 'Monster Hunter', 'Resident Evil', 'Devil May Cry',
      'Metal Gear Solid', 'Silent Hill', 'Tomb Raider', 'Hitman', 'Splinter Cell',
      // Indépendants
      'Minecraft', 'Terraria', 'Stardew Valley', 'Hollow Knight', 'Celeste',
      'Undertale', 'Cuphead', 'Hades', 'Dead Cells', 'Shovel Knight',
      'Among Us', 'Fall Guys', 'Rocket League', 'Overcooked', 'It Takes Two',
      // Battle Royale / Multijoueur
      'Fortnite', 'PUBG', 'Apex Legends', 'Warzone', 'Valorant',
      'League of Legends', 'Dota 2', 'Counter-Strike', 'Overwatch', 'Rainbow Six',
      'World of Warcraft', 'Destiny', 'The Division', 'Diablo', 'Path of Exile',
      // Classiques
      'Tetris', 'Pac-Man', 'Space Invaders', 'Sonic', 'Street Fighter',
      'Mortal Kombat', 'Tekken', 'Crash Bandicoot', 'Spyro', 'Rayman',
      // Autres
      'Portal', 'Half-Life', 'Bioshock', 'Mass Effect', 'Dragon Age',
      'The Elder Scrolls', 'Fallout', 'Borderlands', 'Dead Space', 'Amnesia',
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
