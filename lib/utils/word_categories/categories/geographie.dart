import '../models.dart';

const categoryGeographie = WordCategory(
  id: 'geographie',
  name: 'Monde',
  icon: '🌍',
  words: [

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
);
