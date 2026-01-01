import '../models.dart';

const categoryNature = WordCategory(
  id: 'nature',
  name: 'Nature',
  icon: '🌿',
  words: [

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
);
