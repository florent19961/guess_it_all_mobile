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
      'Interstellar', 'Le Silence des Agneaux', 'Les Évadés',
      'Top Gun', 'Fast and Furious', 'Mission Impossible', 'James Bond',
      // Super-héros
      'Batman', 'Superman', 'Spider-Man', 'Iron Man', 'Avengers',
      'Black Panther', 'Joker',
      'Thor', 'Doctor Strange', 'Captain America', 'Hulk',
      // Animation 
      'Ratatouille', 'Nemo', 'Vice-Versa', 'Coco', 'Monstres et Cie',
      'Wall-E', 'Les Indestructibles', 'Rebelle', 'Vaiana', 'Encanto',
      'La Reine des Neiges', 'Zootopie', 'Dragons', 'Kung Fu Panda', 'Madagascar',
      'Moi Moche et Méchant', 'Les Minions', 'Lego Movie', 'Soul', 'Là-haut',
      'Mulan',"Le Roi Lion","Vaiana","Raiponce",
      "Le Roi Lion", "La Reine des Neiges", "Vaiana", "Raiponce", 
      "Aladdin", "Le Monde de Nemo", "Cendrillon", "Toy Story", "Mulan", "Vice-Versa", 
      "Zootopie", "Là-haut", "La Princesse et la Grenouille", "Rebelle", "Encanto", 
      "Hercule", "Pinocchio", "Tarzan", "Atlantide", "Monstres & Cie", "Cars", "Ratatouille", 
      "WALL-E", "Coco"
       // Séries
      'Breaking Bad', 'Game of Thrones', 'Friends', 'The Office',
      'Stranger Things', 'La Casa de Papel', 'Narcos', 'Peaky Blinders',
      'The Walking Dead', 'Lost', 'Prison Break', 'Dexter', 'House',
      'Grey\'s Anatomy', 'How I Met Your Mother', 'The Big Bang Theory',
      'Black Mirror', 'Sherlock', 'Vikings', 'Adolescence', 'Squid Game',
      'Wednesday', 'The Witcher', 'Lupin', 'Emily in Paris', 'Ozark',
      'Better Call Saul'
      // Autres films
      'Fight Club', 'Seven', 'Gone Girl', 'Shutter Island', 
      'Casino', 'Heat', 'Le parrain',
      'La liste de Schindler', 'Il faut sauver le soldat Ryan', 
      'Batman : The Dark Knight', 'Kill Bill', 'Django',
      // Films supplémentaires
      'Amélie Poulain', 'Intouchables', 'La Haine', 'Les Choristes', 'Le Dîner de Cons',
      'Bienvenue chez les Ch\'tis', 'Les Visiteurs', 'Le Grand Bleu', 'Léon', 'Nikita',
      'The Truman Show', 'Eternal Sunshine', 'Her', 'Whiplash', 'La La Land',
      'The Shining', 'Le loup de Wall Street'
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
      'Baseball', 'Softball', 'Cricket', 'Ultimate (freesbee)',
      // Raquettes
      'Tennis', 'Badminton', 'Tennis de table', 'Squash', 'Padel',
      'Pelote basque', 'Pickleball', 'Beach tennis', 
      // Sports nautiques
      'Natation', 'Plongée', 'Surf', 'Voile', 'Aviron',
      'Canoë', 'Kayak', 'Stand-up paddle', 'Kitesurf', 'Wakeboard',
      'Ski nautique', 'Planche à voile', 'Jet ski', 'Rafting', 'Apnée',
      // Sports d\'hiver
      'Ski alpin', 'Snowboard', 'Ski de fond', 'Biathlon', 'Luge',
      'Bobsleigh', 'Skeleton', 'Patinage artistique', 'Patinage de vitesse', 'Curling',
      'Hockey sur glace', 'Saut à ski', 'Combiné nordique',
      // Arts martiaux
      'Boxe', 'Karaté', 'Judo', 'Taekwondo', 'Kung-fu',
      'MMA', 'Kickboxing','Jiu-jitsu',
      'Lutte', 'Sumo', 'Capoeira', 'Krav-maga', 
      // Athlétisme
      'Sprint', 'Marathon', 'Saut en hauteur', 'Saut en longueur', 'Triple saut',
      'Saut à la perche', 'Lancer de poids', 'Lancer de disque', 'Lancer de javelot', 'Lancer de marteau',
      'Décathlon', 'Heptathlon', 'Course de haies', 'Relais',
      // Cyclisme
      'Cyclisme', 'VTT', 'BMX', 
      // Motorisés
      'Formule 1', 'MotoGP', 'Rallye', 'Motocross', 'Karting',
      // Autres
      'Golf', 'Escalade', 'Alpinisme', 'Gymnastique', 'Trampoline',
      'Haltérophilie', 'Musculation', 'Crossfit', 'Yoga', 'Pilates',
      'Équitation', 'Escrime', 'Tir à l\'arc', 'Pentathlon',
      'Triathlon', 'Parkour', 'Skateboard', 'Roller', 'Parachutisme',
      // Sports supplémentaires
      'Danse sportive', 'Danse classique', 'Hip-hop', 'Breakdance', 'Salsa',
      'Tango', 'Flamenco', 'Ballet', 'Cheerleading', 'Majorette',
      'Plongée sous-marine', 'Spéléologie', 'Canyoning', 'Via ferrata', 
      'Base jump', 'Wingsuit', 'Speed riding', 'Parapente', 'Deltaplane',
      'Bobsleigh', 'Skeleton',
      'Dressage', 'Saut d\'obstacles',  'Polo',
      'Pétanque', 'Boules', 'Bowling', 'Billard', 'Fléchettes',
      'Échecs', 'Go', 'Bridge', 'Coinche',
      'Course d\'orientation',  'Beach volley',
    ],
  ),
  'celebrites': WordCategory(
    id: 'celebrites',
    name: 'Célébrités',
    icon: '⭐',
    words: [
      // Scientifiques
      'Einstein', 'Newton', 'Darwin', 'Marie Curie', 'Galilée',
      'Pasteur', 'Tesla', 'Hawking', 'Archimède',
      // Artistes historiques
      'Mozart', 'Beethoven', 'Bach', 'Chopin', 'Vivaldi',
      'Picasso', 'Van Gogh', 'Monet', 'Da Vinci', 'Michel-Ange',
      'Dali', 'Rembrandt', 'Renoir', 'Vermeer',
      // Écrivains
      'Shakespeare', 'Victor Hugo', 'Molière', 'Voltaire', 'Balzac',
      'Tolkien', 'Agatha Christie', 'Stephen King', 'J.K. Rowling',
      // Politiques historiques
      'Napoléon', 'Jules César', 'Cléopâtre', 'Alexandre le Grand', 'Louis XIV',
      'Gandhi', 'Nelson Mandela', 'Martin Luther King', 'Abraham Lincoln', 'Winston Churchill',
      'Charles de Gaulle', 'Jeanne d\'Arc', 'Che Guevara', 'Kennedy', 'Roosevelt',
      // Chanteurs
      'Elvis Presley', 'Michael Jackson', 'Madonna', 'Prince', 'David Bowie',
      'Freddie Mercury', 'John Lennon', 'Bob Marley', 
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
      'Michael Jordan', 'Kobe Bryant', 'LeBron James', 
      'Roger Federer', 'Nadal', 'Djokovic', 'Serena Williams', 'Tiger Woods',
      'Muhammad Ali', 'Mike Tyson', 'Usain Bolt', 'Michael Phelps', 'Simone Biles',
      // Tech
      'Steve Jobs', 'Bill Gates', 'Mark Zuckerberg', 'Jeff Bezos',
      // Célébrités supplémentaires
      'Ryan Gosling', 'Ryan Reynolds',
      'Natalie Portman', 'Anne Hathaway', 'Julia Roberts', 'Sandra Bullock', 'Nicole Kidman',
      'Cate Blanchett', 'Kate Winslet', 'Charlize Theron', 'Margot Robbie', 'Gal Gadot',
      'Antoine Griezmann', 'Paul Pogba', 'N\'Golo Kanté', 'Hugo Lloris', 'Karim Benzema',
      'Lewis Hamilton', 'Max Verstappen', 'Sebastian Vettel', 'Michael Schumacher', 'Ayrton Senna',
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
      'La Vie en Rose', 'Non, je ne regrette rien', 'Comme d\'habitude', 'Ne me quitte pas',
      'Papaoutai', 'Formidable', 'Alors on danse', 
      'Je veux', 'La Bohème', 'Les Champs-Élysées', 'Comme toi', 'L\'Aziza',
      // Latino
      'Despacito', 'La Bamba', 'Macarena', 'Bailando', 'Danza Kuduro',
      'Waka Waka', 'Hips Don\'t Lie', 'Whenever Wherever', 'La Tortura', 'Chantaje',
      // Autres classiques
      'Imagine', 'What a Wonderful World', 'Hallelujah', 
      'Wonderwall', 'Creep', 
      'Africa', 'Take on Me', 'Sweet Dreams', 'Eye of the Tiger',
      // Musiques supplémentaires
      'I Will Always Love You', 'My Heart Will Go On', 'Hello', 'Someone Like You', 'Rolling in the Deep',
      'Uptown Funk', 'Happy', 'Crazy in Love', 'Single Ladies', 'Halo',
      'Poker Face', 'Born This Way', 'Shallow', 'Just Dance', 'Telephone',
      'Umbrella', 'We Found Love', 'Diamonds', 'Work', 'Stay',
      'Chandelier', 'Cheap Thrills', 'Elastic Heart', 'Unstoppable', 'Breathe Me',
      'Viva la Vida',
      'We Will Rock You', 'We Are the Champions', 
      'Wrecking Ball', 'Flowers', 'Party in the USA', 'We Can\'t Stop', 'Malibu',
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
    ],
  ),
  'clashRoyale': WordCategory(
    id: 'clashRoyale',
    name: 'Clash Royale',
    icon: '👑',
    words: [
      // Troupes communes
      'Chevalier', 'Archers', 'Gobelins', 'Géant', 'Mousquetaire',
      'Mini P.E.K.K.A', 'Valkyrie', 'Squelettes', 'Armée de squelettes', 'Barbares',
      'Gobelins à sarbacane', 'Bombardier', 
      'Gobelin d\'élite', 'Barbare d\'élite', 'Recrue royale', 'Garde royale', 'Fût à squelettes',
      // Troupes rares
      'Chevaucheur de cochon', 'Sorcier', 'Bébé dragon', 'Golem', 'Prince',
      'Géant squelette', 'Ballon', 'Gargouilles', 'Sorcière', 'Méga gargouille',
      'Dragons de feu', 'Cochons royaux', 'Voleur', 'Électrocuteur', 'Boulet de canon',
      'Géant royal', 'Esprit de guérison', 'Trois mousquetaires', 'Machine volante', 'Foreuse de goblins',
      // Troupes épiques
      'P.E.K.K.A', 'Prince noir', 'Ballon squelette', 'Golem de glace', 'Chasseuse',
      'Bourreau', 'Dragon infernal', 'Lave-hound', 'Électro-dragon', 'Méga chevalier',
      'Chevaucheur de bélier', 'Fossoyeur', 'Canon à canon', 'Gobelin géant', 'Maman sorcière',
      // Troupes légendaires
      'Princesse', 'Bûcheron', 'Bandit', 'Mineur', 'Fantôme royal',
      'Électro-géant', 'Sparky', 'Archer magique', 'Roi squelette', 'Pêcheur',
      'Méga chevalier', 'Moine', 'Phénix', 'Mineur',
      // Champions
      'Archer reine', 'Chevalier doré', 'Princesse squelette', 'Super mineur', 'Petit prince',
      // Sorts
      'Flèches', 'Boule de feu', 'Zap', 'Foudre', 'Rocket',
      'Gel', 'Rage', 'Poison', 'Tremblement de terre', 'Tornade',
      'Clone', 'Miroir', 
      'Livraison royale', 'Fût à gobelins', 'Buche', 'Esprit de feu', 'Esprit de glace',
      'Chauve-souris', 'Guérison'
      // Bâtiments
      'Canon', 'Tesla', 'Tour de l\'enfer', 'Tour de bombes', 'Mortier',
      'Cabane de gobelins', 'Tombeau à squelettes', 'Cabane de barbares', 'Fournaise', 
      'Extracteur d\'élixir', 'Cage de gobelins',
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
      'Lancôme',  'Clinique', 'Dove', 'Garnier',
      // Luxe et bijoux
      'Rolex', 'Cartier', 'Tiffany&Co', 'Swarovski', 'Pandora',
      'Omega', 'Tag Heuer', 'Céline',
      // Autres
      'IKEA', 'Lego', 'Disney', 'Netflix', 'Spotify',
      'Instagram', 'TikTok', 'YouTube', 'Twitter', 'Facebook',
      'Uber', 'Airbnb', 'Visa', 'Mastercard',
      // Marques supplémentaires
      'Decathlon', 'Lacoste', 'Ralph Lauren', 
      'Converse', 'Vans', 'Crocs',
      'Ray-Ban', 'Oakley', 'Polaroid', 'Canon', 'Nikon',
      'Bose', 'JBL', 
      'Dyson', 'Philips', 'Bosch', 'Siemens', 'Whirlpool',
      'Carrefour', 'Leclerc', 'Auchan', 'Lidl', 'Aldi',
    ],
  ),
  'jeux_video': WordCategory(
    id: 'jeux_video',
    name: 'Jeux vidéo',
    icon: '🎮',
    words: [
      // Franchises Nintendo
      'Mario', 'Zelda', 'Pokémon', 
      'Donkey Kong', 'Animal Crossing', 'Super Smash Bros',
      'Mario Kart', 
      // Multi-plateformes AAA
      'GTA', 'Call of Duty', 'Battlefield', 'FIFA',
      'Assassin\'s Creed', 
      'Final Fantasy', 
      // Indépendants
      'Minecraft', 
      // Battle Royale / Multijoueur
      'Fortnite', 
      'League of Legends (lol)', 
      'World of Warcraft (wow)', 
      // Classiques
      'Tetris', 'Pac-Man', 'Sonic', 'Spyro','Dofus'
    ],
  ),
  'expressions': WordCategory(
    id: 'expressions',
    name: 'Expressions françaises',
    icon: '🇫🇷',
    words: [
      // Expressions avec animaux
      'Avoir le cafard', 'Poser un lapin', 'Avoir la chair de poule', 'Être une poule mouillée', 'Donner sa langue au chat',
      'Avoir d\'autres chats à fouetter', 'Quand les poules auront des dents', 'Être le dindon de la farce', 'Avoir une faim de loup',
      'Avoir une mémoire d\'éléphant', 'Noyer le poisson', 'Prendre le taureau par les cornes',
      'Chercher la petite bête', 'Être comme un coq en pâte', 'Faire l\'autruche', 'Avoir le bourdon', 'Être une tête de mule',
      // Expressions avec le corps
      'Avoir le cœur sur la main', 'Coûter les yeux de la tête', 'Avoir la tête dans les nuages', 
      'Se creuser la tête', 'Avoir un poil dans la main',
      'Mettre les pieds dans le plat', 'Prendre ses jambes à son cou', 'Avoir le bras long', 
      'Garder la tête froide',
      'Avoir l\'estomac dans les talons', 'Se mettre le doigt dans l\'œil', 'Avoir les dents longues', 
      'Casser les pieds', 'Faire la sourde oreille',
      'Avoir du nez', 'Manger sur le pouce', 'Ne pas avoir la langue dans sa poche',
      'Se casser la tête',
      // Expressions culinaires
      'Mettre du beurre dans les épinards', 'Tomber dans les pommes', 'Raconter des salades', 
      'Avoir la patate', 'Être dans les choux',
      'Ramener sa fraise', 'Couper la poire en deux', 'Mettre de l\'eau dans son vin', 
      'C\'est la cerise sur le gâteau', 'Mi-figue mi-raisin',
      'Avoir du pain sur la planche', 'Ne pas être dans son assiette', 'En faire tout un fromage', 
      'Être haut comme trois pommes', 'Sucrer les fraises',
      'Pédaler dans la semoule', 'Les carottes sont cuites', 'Avoir la banane', 'Tomber dans le panneau', 
      'Cracher dans la soupe',
      // Expressions météo
      'Être dans le brouillard', 'Avoir un coup de foudre', 'Être sous l\'eau', 
      'Après la pluie le beau temps', 'Il pleut des cordes',
      'Faire la pluie et le beau temps', 'Un froid de canard', 'Jeter un froid', 
      'Tomber des nues',
      // Expressions diverses
      'Avoir le melon', 'Casser sa pipe', 'Tourner autour du pot', 'Mettre les voiles', 'Jeter l\'éponge',
      'Tirer les vers du nez', 'Mettre la puce à l\'oreille', 'Avoir le feu sacré', 
      'Brûler les étapes', 'Faire chou blanc',
      'Être à côté de la plaque', 'Tomber à pic', 'Rouler quelqu\'un dans la farine',
      'Être au bout du rouleau', 'Perdre la boule',
      'Avoir du bol', 'Se prendre un râteau', 'Passer du coq à l\'âne', 
      'Faire d\'une pierre deux coups', 'Se mettre sur son trente-et-un',
      'Être dans de beaux draps', 'Payer les pots cassés', 'Tirer son épingle du jeu', 
      'Mettre son grain de sel', 'Avoir un verre dans le nez',
      'Être à l\'ouest', 'Faire la grasse matinée', 'Avoir le blues', 
      'Mettre les bouchées doubles', 'Avoir carte blanche',
      'Prendre la mouche', 'Être au taquet', 'Casser trois pattes à un canard', 
      'Avoir la dalle', 'Se faire poser un lapin',
      'Être sur son petit nuage', 'Faire long feu', 'Être aux anges', 'Avoir la pêche', 'Mettre la main à la pâte',
      // Expressions supplémentaires
      'Se tenir à carreau', 'Monter sur ses grands chevaux', 'Avoir une araignée au plafond', 'Tomber de haut', 'Voir la vie en rose',
      'Avoir le vent en poupe', 'Être dans ses petits souliers', 'Mettre les points sur les i', 'Courir sur le haricot', 'Être au pied du mur',
      'Avoir la grosse tête', 'Se mordre les doigts', 'Tenir la chandelle', 'Avoir le moral dans les chaussettes', 'En avoir ras le bol',
      'Casser du sucre sur le dos', 'Avoir les yeux plus gros que le ventre', 'Être à cheval sur les principes', 'Peigner la girafe', 'Se lever du pied gauche',
      'Remettre les pendules à l\'heure', 'Avoir la main verte', 'Être dans la lune', 'Marcher sur des œufs', 'Avoir une case en moins',
      'Faire la tête', 'Avoir la langue bien pendue', 'Dormir sur ses deux oreilles', 'Mettre de l\'huile sur le feu', 'Avoir la moutarde qui monte au nez',
      'Se jeter dans la gueule du loup', 'Être comme un poisson dans l\'eau', 'Avoir un coup de pompe', 'Rester les bras croisés', 'Avoir le beurre et l\'argent du beurre',
      'Ne pas y aller avec le dos de la cuillère', 'Prendre le taureau par les cornes', 'Être au bout du tunnel', 'Avoir le dernier mot', 'Mettre cartes sur table',
    ],
  ),
  'dessins_animes': WordCategory(
    id: 'dessins_animes',
    name: 'Dessins animés',
    icon: '📺',
    words: [
      // Anime japonais
      'Naruto', 'Dragon Ball', 'One Piece', 'L\'Attaque des Titans', 'Death Note',
      'Demon Slayer', 'Hunter x Hunter', 'Jujutsu Kaisen', 'Yu-Gi-Oh', 
      'Detective Conan', 
      // Dessins animés occidentaux
      'Bob l\'éponge', 'Les Simpson', 'South Park', 'Rick et Morty', 'Ben 10', 'Totally Spies',
      'Code Lyoko', 'Martin Mystère', 'Les Razmoket', 'Hey Arnold', 'Dora l\'exploratrice',
      'Bob le bricoleur', 
      // Classiques français
      'Astérix', 'Lucky Luke', 'Tintin', 'Les Schtroumpfs', 'Spirou',
      'Il était une fois la vie', 'Il était une fois l\'homme', 'Inspecteur Gadget', 
      // Disney/Pixar séries
      'Mickey Mouse', 'Donald Duck', 'La Bande à Picsou', 'Tic et Tac', 'Kim Possible',
      'Phineas et Ferb', 'La Fée Clochette', 
      // Cartoon Network / Nickelodeon
      'Les Super Nanas', 'Le laboratoire de Dexter', 'Oggy et les cafards', 'Les Dalton',
      'Scooby-Doo', 'Tom et Jerry', 'Bugs Bunny', 'Titi et Grosminet', 'Bip Bip et Coyote',
    ],
  ),
  'personnages_fictifs': WordCategory(
    id: 'personnages_fictifs',
    name: 'Personnages fictifs',
    icon: '🦸',
    words: [
      // Super-héros
      'Batman', 'Superman', 'Spider-Man', 'Wonder Woman', 'Iron Man',
      'Captain America', 'Thor', 'Hulk', 'Black Widow', 'Wolverine',
      'Deadpool', 'Flash', 'Aquaman', 'Green Lantern', 'Catwoman',
      // Méchants célèbres
      'Joker', 'Thanos', 'Dark Vador', 'Voldemort', 'Sauron',
      'Magneto', 'Loki', 'Hannibal Lecter', 'Pennywise', 'Freddy Krueger',
      // Littérature
      'Sherlock Holmes', 'Harry Potter', 'Hermione Granger', 'Gandalf', 'Frodon',
      'James Bond', 'Indiana Jones', 'Dracula', 'Frankenstein', 'Docteur Jekyll',
      'Don Quichotte', 'D\'Artagnan', 'Jean Valjean', 'Edmond Dantès', 'Cyrano de Bergerac',
      'Arsène Lupin', 'Fantômas', 'Hercule Poirot', 'Miss Marple', 'Maigret',
      // BD franco-belge
      'Astérix', 'Obélix', 'Tintin', 'Milou', 'Capitaine Haddock',
      'Lucky Luke', 'Les Dalton', 'Gaston Lagaffe', 'Spirou', 'Fantasio',
      'Les Schtroumpfs', 'Gargamel', 'Iznogoud', 'Achille Talon', 'Boule et Bill',
      // Disney
      'Mickey Mouse', 'Donald Duck', 'Dingo', 'Pluto', 'Minnie',
      'Blanche-Neige', 'Cendrillon', 'Belle', 'Ariel', 'Elsa',
      'Simba', 'Mufasa', 'Scar', 'Timon', 'Pumbaa',
      'Woody', 'Buzz l\'Éclair', 'Nemo', 'Dory', 'Ratatouille',
      // Science-fiction
      'Dark Vador', 'Luke Skywalker', 'Han Solo', 'Princesse Leia', 'Yoda',
      'Spock', 'Neo', 'Morpheus', 'Terminator', 'Robocop',
      'E.T.', 'Predator', 'Alien', 'Wall-E', 'R2-D2',
    ],
  ),
  'lieux_celebres': WordCategory(
    id: 'lieux_celebres',
    name: 'Lieux célèbres',
    icon: '🗼',
    words: [
      // France
      'Tour Eiffel', 'Arc de Triomphe', 'Notre-Dame de Paris', 'Château de Versailles', 'Mont Saint-Michel',
      'Louvre', 'Sacré-Cœur', 'Pont du Gard', 'Cité de Carcassonne', 'Château de Chambord',
      // Europe
      'Colisée', 'Tour de Pise', 'Sagrada Familia', 'Big Ben', 'Stonehenge',
      'Acropole', 'Parthénon', 'Tour de Londres', 'Buckingham Palace', 'Alhambra',
      'Place Saint-Marc', 'Fontaine de Trevi', 'Vatican', 'Chapelle Sixtine', 'Pompéi',
      // Amériques
      'Statue de la Liberté', 'Grand Canyon', 'Machu Picchu', 'Chutes du Niagara', 'Central Park',
      'Golden Gate Bridge', 'Times Square', 'Empire State Building', 
      'Christ Rédempteur', 
      // Asie
      'Grande Muraille de Chine', 'Taj Mahal', 
      // Afrique et Océanie
      'Pyramides de Gizeh', 'Sphinx', 
      'Opéra de Sydney', 'Uluru', 'Grande Barrière de Corail', 'Île de Pâques',
      // Merveilles naturelles
      'Amazonie', 'Sahara', 'Himalaya', 'Antarctique', 'Galápagos',
      'Yellowstone', 'Everest', 'Kilimanjaro', 'Aurores boréales', 
    ],
  ),
  'inventions': WordCategory(
    id: 'inventions',
    name: 'Inventions',
    icon: '💡',
    words: [
      // Communication
      'Téléphone', 'Télégraphe', 'Radio', 'Télévision', 'Internet',
      'Smartphone', 'Email', 'SMS', 'Fax', 'Imprimerie',
      // Transport
      'Roue', 'Voiture', 'Avion', 'Train', 'Bateau à vapeur',
      'Vélo', 'Moto', 'Métro', 'Fusée', 'Hélicoptère',
      'Sous-marin', 'Montgolfière', 'Parachute', 'Ascenseur', 'Escalator',
      // Électricité et énergie
      'Ampoule électrique', 'Batterie', 'Panneau solaire', 'Éolienne', 'Moteur électrique',
      'Générateur', 'Transformateur', 'Pile', 'Centrale nucléaire', 'Barrage hydroélectrique',
      // Médecine
      'Vaccin', 'Antibiotique', 'Pénicilline', 'Anesthésie', 'Radiographie',
      'Scanner', 'IRM', 'Pacemaker', 'Prothèse', 'Stéthoscope',
      'Microscope', 'Thermomètre', 'Seringue', 'Lunettes', 'Lentilles de contact',
      // Informatique
      'Ordinateur', 'Microprocesseur', 'Disque dur', 'Clé USB', 'CD-ROM',
      'Souris', 'Clavier', 'Écran tactile', 'GPS', 'Wi-Fi',
      'Bluetooth', 'QR Code', 'Intelligence artificielle', 'Robot', 'Drone',
      // Quotidien
      'Machine à laver', 'Réfrigérateur', 'Micro-ondes', 'Aspirateur', 'Climatisation',
      'Fermeture éclair', 'Velcro', 'Post-it', 'Scotch', 'Stylo à bille',
      'Allumette', 'Briquet', 'Boussole', 'Horloge', 'Calendrier',
      // Divers
      'Dynamite', 'Béton armé', 'Plastique', 'Verre', 'Papier',
      'Poudre à canon', 'Boîte de conserve', 'Code-barres', 'Carte de crédit', 'Distributeur automatique',
    ],
  ),
  
  'emotions': WordCategory(
    id: 'emotions',
    name: 'Émotions',
    icon: '😊',
    words: [
      // Émotions positives
      'Joie', 'Bonheur', 'Euphorie', 'Excitation', 'Enthousiasme',
      'Amour', 'Tendresse', 'Affection', 'Passion', 'Désir',
      'Fierté', 'Satisfaction', 'Gratitude', 'Espoir', 'Optimisme',
      'Sérénité', 'Calme', 'Paix', 'Plénitude', 'Émerveillement',
      'Amusement', 'Hilarité', 'Malice', 'Complicité', 'Confiance',
      // Émotions négatives
      'Tristesse', 'Mélancolie', 'Chagrin', 'Déprime', 'Désespoir',
      'Colère', 'Rage', 'Fureur', 'Irritation', 'Agacement',
      'Peur', 'Terreur', 'Angoisse', 'Anxiété', 'Panique',
      'Jalousie', 'Envie', 'Dégoût', 'Mépris', 'Haine',
      'Honte', 'Culpabilité', 'Embarras', 'Gêne', 'Humiliation',
      'Ennui', 'Lassitude', 'Frustration', 'Déception', 'Regret',
      // États d\'esprit
      'Stress', 'Tension', 'Nervosité', 'Impatience', 'Agitation',
      'Fatigue', 'Épuisement', 'Confusion', 'Perplexité', 'Doute',
      'Nostalgie', 'Solitude', 'Isolement', 'Abandon', 'Rejet',
      'Surprise', 'Stupéfaction', 'Choc', 'Incrédulité', 'Admiration',
      'Curiosité', 'Intérêt', 'Fascination', 'Concentration', 'Détermination',
      'Courage', 'Audace', 'Timidité', 'Pudeur', 'Vulnérabilité',
      'Soulagement', 'Apaisement', 'Réconfort', 'Sécurité', 'Liberté',
    ],
  ),
  'actions': WordCategory(
    id: 'actions',
    name: 'Actions',
    icon: '🏃',
    words: [
      // Mouvements de base
      'Marcher', 'Courir', 'Sauter', 'Ramper', 'Grimper',
      'Nager', 'Voler', 'Tomber', 'Glisser', 'Rouler',
      'Se lever', 'S\'asseoir', 'S\'allonger', 'Se pencher', 'Se retourner',
      // Sports et exercices
      'Danser', 'Boxer', 'Skier', 'Surfer', 'Pédaler',
      'Plonger', 'Ramer', 'Escalader', 'Jongler', 'Faire du yoga',
      'Faire des pompes', 'Faire des abdos', 'Soulever', 'Lancer', 'Attraper',
      // Actions quotidiennes
      'Manger', 'Boire', 'Dormir', 'Se réveiller', 'Se doucher',
      'Se brosser les dents', 'Se coiffer', 'S\'habiller', 'Se maquiller', 'Se raser',
      'Cuisiner', 'Nettoyer', 'Repasser', 'Coudre', 'Tricoter',
      'Conduire', 'Téléphoner', 'Écrire', 'Lire', 'Dessiner',
      // Actions expressives
      'Rire', 'Pleurer', 'Crier', 'Chuchoter', 'Chanter',
      'Siffler', 'Applaudir', 'Saluer', 'Embrasser', 'Câliner',
      'Bâiller', 'Éternuer', 'Tousser', 'Hocher la tête', 'Hausser les épaules',
      // Actions avec objets
      'Ouvrir', 'Fermer', 'Pousser', 'Tirer', 'Tourner',
      'Couper', 'Coller', 'Plier', 'Déchirer', 'Casser',
      'Verser', 'Mélanger', 'Secouer', 'Frotter', 'Essuyer',
      // Actions sociales
      'Parler', 'Écouter', 'Regarder', 'Montrer', 'Expliquer',
      'Demander', 'Répondre', 'Discuter', 'Négocier', 'Convaincre',
      'Aider', 'Partager', 'Donner', 'Recevoir', 'Remercier',
    ],
  ),
  'instruments': WordCategory(
    id: 'instruments',
    name: 'Instruments de musique',
    icon: '🎸',
    words: [
      // Cordes frottées
      'Violon', 'Alto', 'Violoncelle', 'Contrebasse', 
      // Cordes pincées
      'Guitare', 'Guitare électrique', 'Basse', 'Banjo', 'Mandoline',
      'Ukulélé', 'Harpe', 'Luth', 
      // Claviers
      'Piano', 'Piano à queue', 'Orgue', 'Clavecin', 'Accordéon',
      // Vents bois
      'Flûte traversière', 'Flûte à bec', 'Clarinette', 'Hautbois', 'Basson',
      'Saxophone', 'Cornemuse',
      // Vents cuivres
      'Trompette', 'Trombone', 'Cor d\'harmonie', 'Tuba', 'Clairon', 'Didgeridoo',
      // Percussions
      'Batterie', 'Caisse claire', 'Grosse caisse', 'Tom', 'Cymbales',
      'Tambour', 'Tambourin', 'Bongo', 'Conga', 'Djembé',
      'Xylophone', 'Marimba', 'Vibraphone', 'Glockenspiel', 'Steel drum',
      'Triangle', 'Castagnettes', 'Maracas', 'Claves', 'Gong',
      'Timbales', 
      // Autres
      'Harmonica', 
    ],
  ),
  'contes': WordCategory(
    id: 'contes',
    name: 'Contes et légendes',
    icon: '📖',
    words: [
      // Personnages de contes
      'Cendrillon', 'Blanche-Neige', 'La Belle au bois dormant', 'Le Petit Chaperon rouge', 'Hansel et Gretel',
      'Le Petit Poucet', 'Le Chat botté', 'Pinocchio', 'Peter Pan', 'Fée Clochette',
      'Alice au pays des merveilles', 'Le Lapin Blanc', 'La Reine de Cœur', 'Aladin', 
      'Ali Baba', 'Shéhérazade', 'La Petite Sirène', 'La Belle et la Bête', 'Raiponce',
       'Les Trois Petits Cochons', 'Le Grand Méchant Loup', 'Boucle d\'or', 'Les Trois Ours',
      // Méchants de contes
      'Sorcière', 'Marâtre', 'Ogre', 'Dragon', 'Troll',
      'Barbe Bleue', 'Le Roi Barbe-d\'Ours', 'La Méchante Reine', 'Rumpelstiltskin', 'Le Joueur de flûte',
      // Objets magiques
      'Baguette magique', 'Tapis volant', 'Lampe merveilleuse', 'Miroir magique', 'Pantoufle de verre',
      'Haricot magique', 'Pomme empoisonnée', 'Fuseau', 'Bottes de sept lieues', 'Cape d\'invisibilité',
      // Créatures légendaires
      'Licorne', 'Dragon', 'Phénix', 'Griffon', 'Pégase',
      'Loup-garou', 'Vampire', 'Fantôme', 'Sorcier', 'Fée',
      'Elfe', 'Nain', 'Géant', 'Sirène', 'Cyclope',
      // Légendes
      'Roi Arthur', 'Excalibur', 'Merlin', 'Lancelot', 'Table ronde',
      'Robin des Bois', 'Guillaume Tell',
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
