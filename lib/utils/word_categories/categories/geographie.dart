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
      WordWithDifficulty('Berlin', difficulty: 1),
      WordWithDifficulty('Madrid', difficulty: 1),
      WordWithDifficulty('Lisbonne', difficulty: 1),
      WordWithDifficulty('Athènes', difficulty: 1),
      WordWithDifficulty('Paris', difficulty: 1),
      WordWithDifficulty('Rome', difficulty: 1),
      WordWithDifficulty('Londres', difficulty: 1),

      // PAYS EUROPE - Moyen
      WordWithDifficulty('Belgique', difficulty: 1),
      WordWithDifficulty('Pays-Bas', difficulty: 2),
      WordWithDifficulty('Suisse', difficulty: 1),
      WordWithDifficulty('Portugal', difficulty: 1),
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
      WordWithDifficulty('Amazone', difficulty: 3),
      WordWithDifficulty('Mississippi', difficulty: 3),
      WordWithDifficulty('Rhin', difficulty: 2),
      WordWithDifficulty('Danube', difficulty: 2),
      WordWithDifficulty('Tamise', difficulty: 2),
      WordWithDifficulty('Gange', difficulty: 2),

      // FLEUVES - Difficile
      WordWithDifficulty('Loire', difficulty: 2),
      WordWithDifficulty('Rhône', difficulty: 2),
      WordWithDifficulty('Garonne', difficulty: 2),
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
      WordWithDifficulty('Grand Est', difficulty: 3),

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
      WordWithDifficulty('Mer Baltique', difficulty: 3),

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
      WordWithDifficulty('Grand Canyon', difficulty: 2),
      WordWithDifficulty('Chutes du Niagara', difficulty: 2),
      WordWithDifficulty('Grande Barrière de Corail', difficulty: 3),
      WordWithDifficulty('Mont Blanc', difficulty: 2),
      WordWithDifficulty('Yellowstone', difficulty: 3),
      WordWithDifficulty('Désert de Gobi', difficulty: 3),
      WordWithDifficulty('Patagonie', difficulty: 3),
      WordWithDifficulty('Antarctique', difficulty: 2),

      // VOLCANS - Facile
      WordWithDifficulty('Vésuve', difficulty: 2),
      WordWithDifficulty('Etna', difficulty: 2),

      // VOLCANS - Moyen
      WordWithDifficulty('Stromboli', difficulty: 3),
      WordWithDifficulty('Mont Fuji', difficulty: 2),
      WordWithDifficulty('Krakatoa', difficulty: 3),

      // VOLCANS - Difficile
      WordWithDifficulty('Piton de la Fournaise', difficulty: 3),
      WordWithDifficulty('Popocatépetl', difficulty: 3),

      // CAPITALES - Facile (non déjà listées ailleurs)
      WordWithDifficulty('Washington', difficulty: 1),
      WordWithDifficulty('Ottawa', difficulty: 3),

      // CAPITALES - Moyen
      WordWithDifficulty('Bruxelles', difficulty: 2),
      WordWithDifficulty('Berne', difficulty: 2),
      WordWithDifficulty('La Haye', difficulty: 3),
      WordWithDifficulty('Rabat', difficulty: 3),
      WordWithDifficulty('Tunis', difficulty: 3),
      WordWithDifficulty('Alger', difficulty: 2),
      WordWithDifficulty('Nairobi', difficulty: 3),
      WordWithDifficulty('Lagos', difficulty: 2),
      WordWithDifficulty('Téhéran', difficulty: 2),
      WordWithDifficulty('Bagdad', difficulty: 2),
      WordWithDifficulty('Kaboul', difficulty: 2),
      WordWithDifficulty('Islamabad', difficulty: 2),
      WordWithDifficulty('Dacca', difficulty: 3),
      WordWithDifficulty('Katmandou', difficulty: 2),
      WordWithDifficulty('Colombo', difficulty: 3),
      WordWithDifficulty('Hanoï', difficulty: 2),
      WordWithDifficulty('Manille', difficulty: 2),
      WordWithDifficulty('Jakarta', difficulty: 2),
      WordWithDifficulty('Kuala Lumpur', difficulty: 2),
      WordWithDifficulty('Canberra', difficulty: 2),
      WordWithDifficulty('Wellington', difficulty: 2),
      WordWithDifficulty('Buenos Aires', difficulty: 2),
      WordWithDifficulty('Santiago', difficulty: 2),
      WordWithDifficulty('Lima', difficulty: 3),
      WordWithDifficulty('Bogota', difficulty: 2),
      WordWithDifficulty('Caracas', difficulty: 3),
      WordWithDifficulty('La Havane', difficulty: 2),

      // CAPITALES - Difficile
      WordWithDifficulty('Montevideo', difficulty: 3),
      WordWithDifficulty('La Paz', difficulty: 3),
      WordWithDifficulty('Asunción', difficulty: 3),
      WordWithDifficulty('San José', difficulty: 3),
      WordWithDifficulty('Reykjavik', difficulty: 3),
      WordWithDifficulty('Tallin', difficulty: 3),
      WordWithDifficulty('Riga', difficulty: 3),
      WordWithDifficulty('Vilnius', difficulty: 3),
      WordWithDifficulty('Ljubljana', difficulty: 3),
      WordWithDifficulty('Zagreb', difficulty: 3),
      WordWithDifficulty('Belgrade', difficulty: 3),
      WordWithDifficulty('Sofia', difficulty: 3),
      WordWithDifficulty('Bratislava', difficulty: 3),
      WordWithDifficulty('La Valette', difficulty: 3),
      WordWithDifficulty('Nicosie', difficulty: 3),
      WordWithDifficulty('Addis-Abeba', difficulty: 3),
      WordWithDifficulty('Ouagadougou', difficulty: 3),
      WordWithDifficulty('Bamako', difficulty: 3),
      WordWithDifficulty('Niamey', difficulty: 3),
      WordWithDifficulty('Khartoum', difficulty: 3),
      WordWithDifficulty('Kampala', difficulty: 3),
      WordWithDifficulty('Kigali', difficulty: 3),
      WordWithDifficulty('Bujumbura', difficulty: 3),
      WordWithDifficulty('Dodoma', difficulty: 3),
      WordWithDifficulty('Lusaka', difficulty: 3),
      WordWithDifficulty('Harare', difficulty: 3),
      WordWithDifficulty('Gaborone', difficulty: 3),
      WordWithDifficulty('Windhoek', difficulty: 3),
      WordWithDifficulty('Antananarivo', difficulty: 3),

      // DÉPARTEMENTS FRANÇAIS - Facile
      WordWithDifficulty('75 - Paris', difficulty: 1),
      WordWithDifficulty('13 - Bouches-du-Rhône', difficulty: 1),
      WordWithDifficulty('69 - Rhône', difficulty: 1),
      WordWithDifficulty('59 - Nord', difficulty: 1),
      WordWithDifficulty('83 - Var', difficulty: 1),

      // DÉPARTEMENTS FRANÇAIS - Moyen
      WordWithDifficulty('33 - Gironde', difficulty: 2),
      WordWithDifficulty('44 - Loire-Atlantique', difficulty: 2),
      WordWithDifficulty('34 - Hérault', difficulty: 2),
      WordWithDifficulty('31 - Haute-Garonne', difficulty: 2),
      WordWithDifficulty('06 - Alpes-Maritimes', difficulty: 2),
      WordWithDifficulty('35 - Ille-et-Vilaine', difficulty: 2),
      WordWithDifficulty('67 - Bas-Rhin', difficulty: 2),
      WordWithDifficulty('38 - Isère', difficulty: 2),
      WordWithDifficulty('76 - Seine-Maritime', difficulty: 2),
      WordWithDifficulty('29 - Finistère', difficulty: 2),

      // DÉPARTEMENTS FRANÇAIS - Difficile
      WordWithDifficulty('21 - Côte-d\'Or', difficulty: 3),
      WordWithDifficulty('49 - Maine-et-Loire', difficulty: 3),
      WordWithDifficulty('56 - Morbihan', difficulty: 3),
      WordWithDifficulty('22 - Côtes-d\'Armor', difficulty: 3),
      WordWithDifficulty('51 - Marne', difficulty: 3),
      WordWithDifficulty('84 - Vaucluse', difficulty: 3),
      WordWithDifficulty('48 - Lozère', difficulty: 3),
      WordWithDifficulty('23 - Creuse', difficulty: 3),
      WordWithDifficulty('15 - Cantal', difficulty: 3),
      WordWithDifficulty('43 - Haute-Loire', difficulty: 3),

      // ÎLES - Facile
      WordWithDifficulty('Sicile', difficulty: 1),
      WordWithDifficulty('Crète', difficulty: 1),

      // ÎLES - Moyen
      WordWithDifficulty('Sardaigne', difficulty: 2),
      WordWithDifficulty('Majorque', difficulty: 2),
      WordWithDifficulty('Ibiza', difficulty: 2),
      WordWithDifficulty('Capri', difficulty: 2),
      WordWithDifficulty('Rhodes', difficulty: 3),
      WordWithDifficulty('Santorin', difficulty: 3),
      WordWithDifficulty('Bali', difficulty: 3),
      WordWithDifficulty('Hawaï', difficulty: 2),
      WordWithDifficulty('Tahiti', difficulty: 2),
      WordWithDifficulty('La Réunion', difficulty: 2),
      WordWithDifficulty('Martinique', difficulty: 2),
      WordWithDifficulty('Guadeloupe', difficulty: 2),

      // ÎLES - Difficile
      WordWithDifficulty('Île de Pâques', difficulty: 3),
      WordWithDifficulty('Seychelles', difficulty: 3),
      WordWithDifficulty('Maldives', difficulty: 3),
      WordWithDifficulty('Açores', difficulty: 3),
      WordWithDifficulty('Canaries', difficulty: 2),
      WordWithDifficulty('Île Maurice', difficulty: 3),
      WordWithDifficulty('Zanzibar', difficulty: 3),
      WordWithDifficulty('Bora-Bora', difficulty: 3),
      WordWithDifficulty('Île de Ré', difficulty: 2),
      WordWithDifficulty('Île d\'Oléron', difficulty: 3),
      WordWithDifficulty('Belle-Île-en-Mer', difficulty: 3),

      // LACS - Facile
      WordWithDifficulty('Lac Léman', difficulty: 2),

      // LACS - Moyen
      WordWithDifficulty('Lac Victoria', difficulty: 3),
      WordWithDifficulty('Lac Baïkal', difficulty: 3),
      WordWithDifficulty('Lac Tanganyika', difficulty: 3),
      WordWithDifficulty('Grands Lacs', difficulty: 3),

      // LACS - Difficile
      WordWithDifficulty('Lac d\'Annecy', difficulty: 2),
      WordWithDifficulty('Lac du Bourget', difficulty: 3),
      WordWithDifficulty('Lac de Côme', difficulty: 3),
      WordWithDifficulty('Lac Majeur', difficulty: 3),
      WordWithDifficulty('Loch Ness', difficulty: 2),
      WordWithDifficulty('Lac Balaton', difficulty: 3),

      // DÉTROITS ET CANAUX - Facile
      WordWithDifficulty('Canal de Suez', difficulty: 1),
      WordWithDifficulty('Canal de Panama', difficulty: 1),

      // DÉTROITS ET CANAUX - Moyen
      WordWithDifficulty('Détroit de Gibraltar', difficulty: 2),
      WordWithDifficulty('Détroit de Béring', difficulty: 3),
      WordWithDifficulty('Manche', difficulty: 1),

      // DÉTROITS ET CANAUX - Difficile
      WordWithDifficulty('Détroit du Bosphore', difficulty: 3),
      WordWithDifficulty('Détroit des Dardanelles', difficulty: 3),
      WordWithDifficulty('Détroit de Magellan', difficulty: 3),
      WordWithDifficulty('Canal de Corinthe', difficulty: 3),

  ],
);
