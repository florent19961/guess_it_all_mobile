// ============================================================
// CATÉGORIE : Nature et Gastronomie
// ============================================================
//
// DESCRIPTION :
// Monde naturel (faune, flore, phénomènes) et gastronomie
// (plats du monde, boissons, fromages, vins).
//
// SECTIONS EXISTANTES :
// - Animaux sauvages, domestiques, marins, oiseaux, insectes
// - Félins, reptiles, rongeurs, primates, cervidés, bovidés
// - Plantes, fleurs, arbres, arbustes, plantes d'intérieur
// - Fruits, légumes, champignons
// - Phénomènes naturels, météo, géologie, minéraux
// - Plats italiens, asiatiques, français, du monde
// - Fromages, vins, pains du monde
// - Desserts, confiseries, pâtisseries
// - Boissons chaudes, froides, alcoolisées, cocktails
// - Condiments, sauces, ingrédients cuisine
//
// IDÉES D'ENRICHISSEMENT :
// - Races de chiens et chats populaires
// - Plantes médicinales et aromatiques
// - Spécialités régionales françaises
// - Poissons et fruits de mer moins connus
// - Épices du monde
// - Desserts et pâtisseries régionales
//
// CRITÈRES DE DIFFICULTÉ :
// - 1 (Facile) : Animaux/plats très connus (chat, pizza, pomme)
// - 2 (Moyen) : Moins courant mais reconnaissable (lynx, risotto)
// - 3 (Difficile) : Spécialisé ou exotique (ornithorynque, bouillabaisse)
//
// ============================================================

import '../models.dart';

const categoryNature = WordCategory(
  id: 'nature',
  name: 'Nature et Gastronomie',
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
      WordWithDifficulty('Pingouin', difficulty: 2),
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
      WordWithDifficulty('Oie', difficulty: 1),
      WordWithDifficulty('Hamster', difficulty: 1),
      WordWithDifficulty('Âne', difficulty: 1),
      WordWithDifficulty('Dindon', difficulty: 1),
      WordWithDifficulty('Cochon d\'Inde', difficulty: 1),

      // ANIMAUX MARINS - Facile
      WordWithDifficulty('Dauphin', difficulty: 1),
      WordWithDifficulty('Requin', difficulty: 1),
      WordWithDifficulty('Baleine', difficulty: 1),
      WordWithDifficulty('Poisson', difficulty: 1),
      WordWithDifficulty('Crabe', difficulty: 1),
      WordWithDifficulty('Étoile de mer', difficulty: 2),

      // FÉLINS - Moyen
      WordWithDifficulty('Léopard', difficulty: 2),
      WordWithDifficulty('Panthère', difficulty: 2),
      WordWithDifficulty('Guépard', difficulty: 2),
      WordWithDifficulty('Lynx', difficulty: 2),
      WordWithDifficulty('Puma', difficulty: 2),

      // GRANDS MAMMIFÈRES - Moyen
      WordWithDifficulty('Rhinocéros', difficulty: 1),
      WordWithDifficulty('Hippopotame', difficulty: 1),
      WordWithDifficulty('Gorille', difficulty: 1),
      WordWithDifficulty('Chimpanzé', difficulty: 2),
      WordWithDifficulty('Orang-outan', difficulty: 2),
      WordWithDifficulty('Panda', difficulty: 1),
      WordWithDifficulty('Koala', difficulty: 1),
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
      WordWithDifficulty('Perroquet', difficulty: 1),
      WordWithDifficulty('Flamant rose', difficulty: 2),
      WordWithDifficulty('Autruche', difficulty: 2),
      WordWithDifficulty('Hibou', difficulty: 1),
      WordWithDifficulty('Chouette', difficulty: 1),
      WordWithDifficulty('Faucon', difficulty: 2),
      WordWithDifficulty('Vautour', difficulty: 2),
      WordWithDifficulty('Corbeau', difficulty: 2),
      WordWithDifficulty('Pie', difficulty: 2),
      WordWithDifficulty('Mouette', difficulty: 2),
      WordWithDifficulty('Cigogne', difficulty: 2),

      // PETITS MAMMIFÈRES - Moyen
      WordWithDifficulty('Écureuil', difficulty: 1),
      WordWithDifficulty('Hérisson', difficulty: 1),
      WordWithDifficulty('Castor', difficulty: 2),
      WordWithDifficulty('Taupe', difficulty: 2),
      WordWithDifficulty('Souris', difficulty: 1),
      WordWithDifficulty('Rat', difficulty: 1),

      // FÉLINS - Difficile
      WordWithDifficulty('Jaguar', difficulty: 3),

      // CANIDÉS - Difficile
      WordWithDifficulty('Fennec', difficulty: 3),
      WordWithDifficulty('Chacal', difficulty: 3),
      WordWithDifficulty('Coyote', difficulty: 3),
      WordWithDifficulty('Dingo', difficulty: 3),

      // HERBIVORES - Difficile
      WordWithDifficulty('Chameau', difficulty: 2),
      WordWithDifficulty('Dromadaire', difficulty: 2),
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
      WordWithDifficulty('Libellule', difficulty: 1),
      WordWithDifficulty('Sauterelle', difficulty: 1),
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
      WordWithDifficulty('Abricot', difficulty: 1),
      WordWithDifficulty('Mangue', difficulty: 2),
      WordWithDifficulty('Citron', difficulty: 1),
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
      WordWithDifficulty('Courgette', difficulty: 1),
      WordWithDifficulty('Aubergine', difficulty: 1),
      WordWithDifficulty('Brocoli', difficulty: 1),
      WordWithDifficulty('Chou-fleur', difficulty: 2),
      WordWithDifficulty('Épinard', difficulty: 2),
      WordWithDifficulty('Haricot', difficulty: 2),
      WordWithDifficulty('Petit pois', difficulty: 2),
      WordWithDifficulty('Poireau', difficulty: 2),
      WordWithDifficulty('Céleri', difficulty: 2),
      WordWithDifficulty('Chou', difficulty: 2),
      WordWithDifficulty('Courge', difficulty: 2),
      WordWithDifficulty('Citrouille', difficulty: 2),

      // LÉGUMES - Difficile
      WordWithDifficulty('Asperge', difficulty: 3),
      WordWithDifficulty('Artichaut', difficulty: 2),
      WordWithDifficulty('Betterave', difficulty: 2),
      WordWithDifficulty('Navet', difficulty: 2),
      WordWithDifficulty('Panais', difficulty: 3),
      WordWithDifficulty('Rutabaga', difficulty: 3),
      WordWithDifficulty('Topinambour', difficulty: 3),
      WordWithDifficulty('Endive', difficulty: 2),
      WordWithDifficulty('Fenouil', difficulty: 3),
      WordWithDifficulty('Salsifis', difficulty: 3),

      // AMPHIBIENS - Facile
      WordWithDifficulty('Grenouille', difficulty: 1),
      WordWithDifficulty('Crapaud', difficulty: 1),

      // AMPHIBIENS - Moyen
      WordWithDifficulty('Triton', difficulty: 3),
      WordWithDifficulty('Rainette', difficulty: 3),

      // CRUSTACÉS - Facile
      WordWithDifficulty('Crevette', difficulty: 2),
      WordWithDifficulty('Homard', difficulty: 2),

      // CRUSTACÉS - Moyen
      WordWithDifficulty('Langouste', difficulty: 3),
      WordWithDifficulty('Écrevisse', difficulty: 3),
      WordWithDifficulty('Langoustine', difficulty: 3),
      WordWithDifficulty('Tourteau', difficulty: 3),

      // CRUSTACÉS - Difficile
      WordWithDifficulty('Bernard-l\'ermite', difficulty: 3),
      WordWithDifficulty('Araignée de mer', difficulty: 3),
      WordWithDifficulty('Cloporte', difficulty: 3),

      // MOLLUSQUES - Facile
      WordWithDifficulty('Escargot', difficulty: 1),

      // MOLLUSQUES - Moyen
      WordWithDifficulty('Moule', difficulty: 2),
      WordWithDifficulty('Huître', difficulty: 2),
      WordWithDifficulty('Seiche', difficulty: 3),
      WordWithDifficulty('Limace', difficulty: 2),

      // MOLLUSQUES - Difficile
      WordWithDifficulty('Coquille Saint-Jacques', difficulty: 2),
      WordWithDifficulty('Bigorneau', difficulty: 3),
      WordWithDifficulty('Bulot', difficulty: 3),
      WordWithDifficulty('Poulpe', difficulty: 2),

      // URSIDÉS - Facile
      WordWithDifficulty('Ours polaire', difficulty: 1),

      // URSIDÉS - Moyen
      WordWithDifficulty('Ours brun', difficulty: 2),
      WordWithDifficulty('Ours noir', difficulty: 2),

      // URSIDÉS - Difficile
      WordWithDifficulty('Grizzly', difficulty: 3),

      // POISSONS D'EAU DOUCE - Facile
      WordWithDifficulty('Poisson rouge', difficulty: 1),
      WordWithDifficulty('Carpe', difficulty: 1),

      // POISSONS D'EAU DOUCE - Moyen
      WordWithDifficulty('Truite', difficulty: 2),
      WordWithDifficulty('Brochet', difficulty: 3),
      WordWithDifficulty('Perche', difficulty: 2),
      WordWithDifficulty('Gardon', difficulty: 3),

      // POISSONS D'EAU DOUCE - Difficile
      WordWithDifficulty('Silure', difficulty: 3),
      WordWithDifficulty('Anguille', difficulty: 3),
      WordWithDifficulty('Tanche', difficulty: 3),

      // ARACHNIDES - Facile
      WordWithDifficulty('Scorpion', difficulty: 1),

      // ARACHNIDES - Moyen
      WordWithDifficulty('Tarentule', difficulty: 2),
      WordWithDifficulty('Veuve noire', difficulty: 3),

      // ARACHNIDES - Difficile
      WordWithDifficulty('Tique', difficulty: 3),
      WordWithDifficulty('Acarien', difficulty: 3),

      // PLANTES AROMATIQUES & ÉPICES - Facile
      WordWithDifficulty('Basilic', difficulty: 1),
      WordWithDifficulty('Menthe', difficulty: 1),
      WordWithDifficulty('Persil', difficulty: 1),

      // PLANTES AROMATIQUES & ÉPICES - Moyen
      WordWithDifficulty('Thym', difficulty: 2),
      WordWithDifficulty('Romarin', difficulty: 2),
      WordWithDifficulty('Origan', difficulty: 2),
      WordWithDifficulty('Ciboulette', difficulty: 2),
      WordWithDifficulty('Coriandre', difficulty: 2),
      WordWithDifficulty('Estragon', difficulty: 3),

      // PLANTES AROMATIQUES & ÉPICES - Difficile
      WordWithDifficulty('Safran', difficulty: 3),
      WordWithDifficulty('Cardamome', difficulty: 3),
      WordWithDifficulty('Cannelle', difficulty: 3),
      WordWithDifficulty('Curcuma', difficulty: 3),
      WordWithDifficulty('Gingembre', difficulty: 3),
      WordWithDifficulty('Anis', difficulty: 3),
      WordWithDifficulty('Vanille', difficulty: 1),
      WordWithDifficulty('Muscade', difficulty: 3),

      // CÉRÉALES & LÉGUMINEUSES - Facile
      WordWithDifficulty('Blé', difficulty: 1),
      WordWithDifficulty('Riz', difficulty: 1),

      // CÉRÉALES & LÉGUMINEUSES - Moyen
      WordWithDifficulty('Orge', difficulty: 2),
      WordWithDifficulty('Avoine', difficulty: 2),
      WordWithDifficulty('Seigle', difficulty: 2),
      WordWithDifficulty('Lentilles', difficulty: 2),
      WordWithDifficulty('Pois chiches', difficulty: 2),

      // CÉRÉALES & LÉGUMINEUSES - Difficile
      WordWithDifficulty('Quinoa', difficulty: 3),
      WordWithDifficulty('Sarrasin', difficulty: 3),
      WordWithDifficulty('Épeautre', difficulty: 3),
      WordWithDifficulty('Soja', difficulty: 3),
      WordWithDifficulty('Fèves', difficulty: 3),

      // NOIX & FRUITS SECS - Facile
      WordWithDifficulty('Noix', difficulty: 1),
      WordWithDifficulty('Noisette', difficulty: 2),
      WordWithDifficulty('Cacahuète', difficulty: 2),

      // NOIX & FRUITS SECS - Moyen
      WordWithDifficulty('Amande', difficulty: 2),
      WordWithDifficulty('Pistache', difficulty: 2),
      WordWithDifficulty('Raisin sec', difficulty: 2),
      WordWithDifficulty('Abricot sec', difficulty: 2),

      // NOIX & FRUITS SECS - Difficile
      WordWithDifficulty('Noix de cajou', difficulty: 3),
      WordWithDifficulty('Noix de pécan', difficulty: 3),
      WordWithDifficulty('Noix de macadamia', difficulty: 3),
      WordWithDifficulty('Pignon de pin', difficulty: 2),
      WordWithDifficulty('Châtaigne', difficulty: 2),

      // CHAMPIGNONS - Facile
      WordWithDifficulty('Champignon de Paris', difficulty: 1),

      // CHAMPIGNONS - Moyen
      WordWithDifficulty('Pleurote', difficulty: 3),
      WordWithDifficulty('Shiitake', difficulty: 3),

      // CHAMPIGNONS - Difficile
      WordWithDifficulty('Cèpe', difficulty: 3),
      WordWithDifficulty('Morille', difficulty: 3),
      WordWithDifficulty('Girolle', difficulty: 3),
      WordWithDifficulty('Truffe', difficulty: 3),
      WordWithDifficulty('Bolet', difficulty: 3),
      WordWithDifficulty('Chanterelle', difficulty: 3),
      // PLANTES SAUVAGES - Facile
      WordWithDifficulty('Fougère', difficulty: 1),
      WordWithDifficulty('Mousse', difficulty: 1),

      // PLANTES SAUVAGES - Moyen
      WordWithDifficulty('Lierre', difficulty: 2),
      WordWithDifficulty('Algue', difficulty: 2),
      WordWithDifficulty('Bambou', difficulty: 2),
      WordWithDifficulty('Roseau', difficulty: 2),

      // PLANTES SAUVAGES - Difficile
      WordWithDifficulty('Lichen', difficulty: 3),
      WordWithDifficulty('Jonc', difficulty: 3),
      WordWithDifficulty('Bruyère', difficulty: 3),

      // HERBES SAUVAGES - Facile
      WordWithDifficulty('Trèfle', difficulty: 1),

      // HERBES SAUVAGES - Moyen
      WordWithDifficulty('Pissenlit', difficulty: 2),
      WordWithDifficulty('Ortie', difficulty: 2),
      WordWithDifficulty('Ronce', difficulty: 2),

      // HERBES SAUVAGES - Difficile
      WordWithDifficulty('Chardon', difficulty: 3),
      WordWithDifficulty('Chiendent', difficulty: 3),

      // PHÉNOMÈNES NATURELS - Facile
      WordWithDifficulty('Orage', difficulty: 1),
      WordWithDifficulty('Arc-en-ciel', difficulty: 1),
      WordWithDifficulty('Pluie', difficulty: 1),
      WordWithDifficulty('Neige', difficulty: 1),
      WordWithDifficulty('Vent', difficulty: 1),

      // PHÉNOMÈNES NATURELS - Moyen
      WordWithDifficulty('Éclair', difficulty: 2),
      WordWithDifficulty('Tonnerre', difficulty: 2),
      WordWithDifficulty('Grêle', difficulty: 2),
      WordWithDifficulty('Brouillard', difficulty: 2),
      WordWithDifficulty('Rosée', difficulty: 2),
      WordWithDifficulty('Givre', difficulty: 2),

      // PHÉNOMÈNES NATURELS - Difficile
      WordWithDifficulty('Éclipse', difficulty: 2),
      WordWithDifficulty('Tsunami', difficulty: 2),
      WordWithDifficulty('Volcan', difficulty: 2),
      WordWithDifficulty('Tornade', difficulty: 2),
      WordWithDifficulty('Avalanche', difficulty: 2),
      WordWithDifficulty('Séisme', difficulty: 2),
      WordWithDifficulty('Cyclone', difficulty:2),
      WordWithDifficulty('Ouragan', difficulty: 2),
      WordWithDifficulty('Aurore boréale', difficulty: 3),

      // MINÉRAUX & PIERRES PRÉCIEUSES - Facile
      WordWithDifficulty('Or', difficulty: 1),
      WordWithDifficulty('Diamant', difficulty: 1),

      // MINÉRAUX & PIERRES PRÉCIEUSES - Moyen
      WordWithDifficulty('Argent', difficulty: 2),
      WordWithDifficulty('Rubis', difficulty: 2),
      WordWithDifficulty('Émeraude', difficulty: 2),
      WordWithDifficulty('Saphir', difficulty: 2),
      WordWithDifficulty('Quartz', difficulty: 2),

      // MINÉRAUX & PIERRES PRÉCIEUSES - Difficile
      WordWithDifficulty('Améthyste', difficulty: 3),
      WordWithDifficulty('Topaze', difficulty: 3),
      WordWithDifficulty('Opale', difficulty: 3),
      WordWithDifficulty('Jade', difficulty: 3),
      WordWithDifficulty('Turquoise', difficulty: 3),
      WordWithDifficulty('Agate', difficulty: 3),
      WordWithDifficulty('Obsidienne', difficulty: 3),
      WordWithDifficulty('Grenat', difficulty: 3),

      // GÉOLOGIE & RELIEF - Facile
      WordWithDifficulty('Montagne', difficulty: 1),
      WordWithDifficulty('Vallée', difficulty: 1),
      WordWithDifficulty('Plage', difficulty: 1),
      WordWithDifficulty('Île', difficulty: 1),

      // GÉOLOGIE & RELIEF - Moyen
      WordWithDifficulty('Canyon', difficulty: 2),
      WordWithDifficulty('Grotte', difficulty: 2),
      WordWithDifficulty('Falaise', difficulty: 2),
      WordWithDifficulty('Dune', difficulty: 2),
      WordWithDifficulty('Glacier', difficulty: 2),
      WordWithDifficulty('Plateau', difficulty: 2),
      WordWithDifficulty('Colline', difficulty: 2),

      // GÉOLOGIE & RELIEF - Difficile
      WordWithDifficulty('Cratère', difficulty: 2),
      WordWithDifficulty('Fjord', difficulty: 3),
      WordWithDifficulty('Stalactite', difficulty: 2),
      WordWithDifficulty('Stalagmite', difficulty: 2),
      WordWithDifficulty('Archipel', difficulty: 3),
      WordWithDifficulty('Isthme', difficulty: 3),

      // MILIEUX AQUATIQUES - Facile
      WordWithDifficulty('Rivière', difficulty: 1),
      WordWithDifficulty('Lac', difficulty: 1),
      WordWithDifficulty('Océan', difficulty: 1),
      WordWithDifficulty('Mer', difficulty: 1),

      // MILIEUX AQUATIQUES - Moyen
      WordWithDifficulty('Cascade', difficulty: 2),
      WordWithDifficulty('Ruisseau', difficulty: 2),
      WordWithDifficulty('Étang', difficulty: 2),
      WordWithDifficulty('Fleuve', difficulty: 2),
      WordWithDifficulty('Torrent', difficulty: 2),

      // MILIEUX AQUATIQUES - Difficile
      WordWithDifficulty('Marais', difficulty: 2),
      WordWithDifficulty('Marécage', difficulty: 2),
      WordWithDifficulty('Lagune', difficulty: 3),
      WordWithDifficulty('Estuaire', difficulty: 3),
      WordWithDifficulty('Delta', difficulty: 3),
      WordWithDifficulty('Geyser', difficulty: 2),

      // ASTRES - Facile
      WordWithDifficulty('Soleil', difficulty: 1),
      WordWithDifficulty('Lune', difficulty: 1),
      WordWithDifficulty('Étoile', difficulty: 1),

      // ASTRES - Moyen
      WordWithDifficulty('Planète', difficulty: 2),
      WordWithDifficulty('Comète', difficulty: 2),
      WordWithDifficulty('Météorite', difficulty: 2),

      // ASTRES - Difficile
      WordWithDifficulty('Galaxie', difficulty: 2),
      WordWithDifficulty('Nébuleuse', difficulty: 3),
      WordWithDifficulty('Trou noir', difficulty: 2),
      WordWithDifficulty('Supernova', difficulty: 3),

      // ÉCOSYSTÈMES - Facile
      WordWithDifficulty('Forêt', difficulty: 1),
      WordWithDifficulty('Désert', difficulty: 1),
      WordWithDifficulty('Jungle', difficulty: 1),

      // ÉCOSYSTÈMES - Moyen
      WordWithDifficulty('Savane', difficulty: 2),
      WordWithDifficulty('Prairie', difficulty: 2),
      WordWithDifficulty('Steppe', difficulty: 3),
      WordWithDifficulty('Taïga', difficulty: 3),

      // ÉCOSYSTÈMES - Difficile
      WordWithDifficulty('Toundra', difficulty: 3),
      WordWithDifficulty('Récif corallien', difficulty: 3),
      WordWithDifficulty('Mangrove', difficulty: 3),
      WordWithDifficulty('Pampa', difficulty: 3),
      WordWithDifficulty('Lande', difficulty: 3),

      // ============================================
      // SECTION GASTRONOMIE
      // ============================================

      // PLATS ITALIENS - Facile
      WordWithDifficulty('Pizza', difficulty: 1),
      WordWithDifficulty('Pâtes', difficulty: 1),
      WordWithDifficulty('Lasagne', difficulty: 1),
      WordWithDifficulty('Risotto', difficulty: 2),
      WordWithDifficulty('Tiramisu', difficulty: 2),

      // PLATS ITALIENS - Moyen
      WordWithDifficulty('Osso buco', difficulty: 3),
      WordWithDifficulty('Carpaccio', difficulty: 2),
      WordWithDifficulty('Panna cotta', difficulty: 2),
      WordWithDifficulty('Bruschetta', difficulty: 2),
      WordWithDifficulty('Arancini', difficulty: 3),

      // PLATS ASIATIQUES - Facile
      WordWithDifficulty('Sushi', difficulty: 1),
      WordWithDifficulty('Ramen', difficulty: 1),
      WordWithDifficulty('Nems', difficulty: 1),
      WordWithDifficulty('Riz cantonais', difficulty: 1),

      // PLATS ASIATIQUES - Moyen
      WordWithDifficulty('Pad thaï', difficulty: 2),
      WordWithDifficulty('Pho', difficulty: 3),
      WordWithDifficulty('Tempura', difficulty: 3),
      WordWithDifficulty('Bahn mi', difficulty: 3),
      WordWithDifficulty('Curry', difficulty: 2),
      WordWithDifficulty('Samosa', difficulty: 2),

      // PLATS ASIATIQUES - Difficile
      WordWithDifficulty('Bibimbap', difficulty: 3),
      WordWithDifficulty('Gyoza', difficulty: 3),
      WordWithDifficulty('Tandoori', difficulty: 3),

      // PLATS FRANÇAIS TRADITIONNELS - Facile
      WordWithDifficulty('Croissant', difficulty: 1),
      WordWithDifficulty('Baguette', difficulty: 1),
      WordWithDifficulty('Crêpe', difficulty: 1),
      WordWithDifficulty('Quiche', difficulty: 1),
      WordWithDifficulty('Ratatouille', difficulty: 1),
      WordWithDifficulty('Steak frites', difficulty: 1),
      WordWithDifficulty('Poulet rôti', difficulty: 2),
      WordWithDifficulty('Raclette', difficulty: 1),
      WordWithDifficulty('Fondue', difficulty: 1),
      WordWithDifficulty('Gaufre', difficulty: 1),

      // PLATS FRANÇAIS TRADITIONNELS - Moyen
      WordWithDifficulty('Bouillabaisse', difficulty: 2),
      WordWithDifficulty('Cassoulet', difficulty: 2),
      WordWithDifficulty('Coq au vin', difficulty: 3),
      WordWithDifficulty('Pot-au-feu', difficulty: 2),
      WordWithDifficulty('Blanquette de veau', difficulty: 2),
      WordWithDifficulty('Bœuf bourguignon', difficulty: 3),
      WordWithDifficulty('Choucroute', difficulty: 2),
      WordWithDifficulty('Gratin dauphinois', difficulty: 2),

      // PLATS FRANÇAIS TRADITIONNELS - Difficile
      WordWithDifficulty('Navarin d\'agneau', difficulty: 3),
      WordWithDifficulty('Aligot', difficulty: 2),
      WordWithDifficulty('Brandade', difficulty: 3),

      // PLATS DU MONDE - Moyen
      WordWithDifficulty('Paella', difficulty: 2),
      WordWithDifficulty('Tacos', difficulty: 1),
      WordWithDifficulty('Kebab', difficulty: 2),
      WordWithDifficulty('Falafel', difficulty: 2),
      WordWithDifficulty('Houmous', difficulty: 2),
      WordWithDifficulty('Couscous', difficulty: 1),
      WordWithDifficulty('Tajine', difficulty: 2),
      WordWithDifficulty('Fish and chips', difficulty: 2),
      WordWithDifficulty('Hamburger', difficulty: 1),

      // PLATS DU MONDE - Difficile
      WordWithDifficulty('Moussaka', difficulty: 3),
      WordWithDifficulty('Pastrami', difficulty: 3),
      WordWithDifficulty('Chimichurri', difficulty: 3),
      WordWithDifficulty('Ceviche', difficulty: 3),
      WordWithDifficulty('Empanada', difficulty: 3),

      // TECHNIQUES CULINAIRES - Moyen
      WordWithDifficulty('Pocher', difficulty: 3),
      WordWithDifficulty('Braiser', difficulty: 3),
      WordWithDifficulty('Sauter', difficulty: 2),
      WordWithDifficulty('Rôtir', difficulty: 2),
      WordWithDifficulty('Griller', difficulty: 2),
      WordWithDifficulty('Émincer', difficulty: 2),
      WordWithDifficulty('Ciseler', difficulty: 3),

      // TECHNIQUES CULINAIRES - Difficile
      WordWithDifficulty('Flamber', difficulty: 3),
      WordWithDifficulty('Confire', difficulty: 3),
      WordWithDifficulty('Déglacer', difficulty: 3),
      WordWithDifficulty('Émulsionner', difficulty: 3),
      WordWithDifficulty('Suer', difficulty: 2),
      WordWithDifficulty('Blanchir', difficulty: 3),

      // USTENSILES SPÉCIALISÉS - Moyen
      WordWithDifficulty('Mandoline', difficulty: 2),
      WordWithDifficulty('Chinois', difficulty: 2),
      WordWithDifficulty('Fouet', difficulty: 2),
      WordWithDifficulty('Spatule', difficulty: 2),
      WordWithDifficulty('Passoire', difficulty: 2),

      // USTENSILES SPÉCIALISÉS - Difficile
      WordWithDifficulty('Siphon', difficulty: 3),
      WordWithDifficulty('Emporte-pièce', difficulty: 3),

      // SAUCES CÉLÈBRES - Moyen
      WordWithDifficulty('Béchamel', difficulty: 2),
      WordWithDifficulty('Hollandaise', difficulty: 2),
      WordWithDifficulty('Béarnaise', difficulty: 3),
      WordWithDifficulty('Mayonnaise', difficulty: 2),
      WordWithDifficulty('Vinaigrette', difficulty: 2),

      // SAUCES CÉLÈBRES - Difficile
      WordWithDifficulty('Rémoulade', difficulty: 3),

      // PÂTISSERIES & DESSERTS - Facile
      WordWithDifficulty('Gâteau', difficulty: 1),
      WordWithDifficulty('Tarte', difficulty: 1),
      WordWithDifficulty('Éclair au chocolat', difficulty: 1),
      WordWithDifficulty('Macaron', difficulty: 1),
      WordWithDifficulty('Crème brûlée', difficulty: 1),
      WordWithDifficulty('Tarte aux pommes', difficulty: 1),
      WordWithDifficulty('Mousse au chocolat', difficulty: 1),
      WordWithDifficulty('Profiterole', difficulty: 1),

      // PÂTISSERIES & DESSERTS - Moyen
      WordWithDifficulty('Mille-feuille', difficulty: 2),
      WordWithDifficulty('Paris-Brest', difficulty: 2),
      WordWithDifficulty('Saint-Honoré', difficulty: 3),
      WordWithDifficulty('Opéra', difficulty: 2),
      WordWithDifficulty('Religieuse', difficulty: 2),
      WordWithDifficulty('Cannelé', difficulty: 2),

      // PÂTISSERIES & DESSERTS - Difficile
      WordWithDifficulty('Financier', difficulty: 3),
      WordWithDifficulty('Dacquoise', difficulty: 3),
      WordWithDifficulty('Baba au rhum', difficulty: 3),

      // FROMAGES - Facile
      WordWithDifficulty('Camembert', difficulty: 1),
      WordWithDifficulty('Brie', difficulty: 1),
      WordWithDifficulty('Comté', difficulty: 1),
      WordWithDifficulty('Roquefort', difficulty: 1),
      WordWithDifficulty('Chèvre', difficulty: 1),

      // FROMAGES - Moyen
      WordWithDifficulty('Reblochon', difficulty: 2),
      WordWithDifficulty('Munster', difficulty: 2),
      WordWithDifficulty('Beaufort', difficulty: 2),
      WordWithDifficulty('Emmental', difficulty: 2),
      WordWithDifficulty('Cantal', difficulty: 2),
      WordWithDifficulty('Morbier', difficulty: 2),

      // FROMAGES - Difficile
      WordWithDifficulty('Époisses', difficulty: 3),
      WordWithDifficulty('Maroilles', difficulty: 3),
      WordWithDifficulty('Salers', difficulty: 3),
      WordWithDifficulty('Ossau-Iraty', difficulty: 3),

      // VINS & CÉPAGES - Moyen
      WordWithDifficulty('Bordeaux', difficulty: 2),
      WordWithDifficulty('Bourgogne', difficulty: 2),
      WordWithDifficulty('Champagne', difficulty: 2),
      WordWithDifficulty('Pinot noir', difficulty: 3),
      WordWithDifficulty('Chardonnay', difficulty: 3),
      WordWithDifficulty('Cabernet', difficulty: 3),

      // VINS & CÉPAGES - Difficile
      WordWithDifficulty('Châteauneuf-du-Pape', difficulty: 2),
      WordWithDifficulty('Côtes-du-Rhône', difficulty: 3),

      // PAINS DU MONDE - Facile
      WordWithDifficulty('Pain', difficulty: 1),
      WordWithDifficulty('Brioche', difficulty: 1),

      // PAINS DU MONDE - Moyen
      WordWithDifficulty('Ciabatta', difficulty: 3),
      WordWithDifficulty('Focaccia', difficulty: 2),
      WordWithDifficulty('Pain pita', difficulty: 2),
      WordWithDifficulty('Naan', difficulty: 2),
      WordWithDifficulty('Bagel', difficulty: 2),

      // PAINS DU MONDE - Difficile
      WordWithDifficulty('Pain de seigle', difficulty: 3),
      WordWithDifficulty('Panettone', difficulty: 2),
      WordWithDifficulty('Challah', difficulty: 3),

      // TERMES CULINAIRES PROFESSIONNELS - Difficile
      WordWithDifficulty('Mise en place', difficulty: 3),
      WordWithDifficulty('Al dente', difficulty: 2),
      WordWithDifficulty('À point', difficulty: 2),
      WordWithDifficulty('Saignant', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - OISEAUX COMMUNS
      // ============================================

      // OISEAUX COMMUNS - Facile
      WordWithDifficulty('Pigeon', difficulty: 1),
      WordWithDifficulty('Moineau', difficulty: 1),
      WordWithDifficulty('Hirondelle', difficulty: 1),
      WordWithDifficulty('Canari', difficulty: 1),
      WordWithDifficulty('Merle', difficulty: 1),
      WordWithDifficulty('Rouge-gorge', difficulty: 1),
      WordWithDifficulty('Colombe', difficulty: 1),
      WordWithDifficulty('Coucou', difficulty: 1),
      WordWithDifficulty('Pic-vert', difficulty: 2),
      WordWithDifficulty('Martinet', difficulty: 2),

      // OISEAUX COMMUNS - Moyen
      WordWithDifficulty('Rossignol', difficulty: 2),
      WordWithDifficulty('Mésange', difficulty: 2),
      WordWithDifficulty('Pinson', difficulty: 2),
      WordWithDifficulty('Chardonneret', difficulty: 3),
      WordWithDifficulty('Verdier', difficulty: 3),
      WordWithDifficulty('Étourneau', difficulty: 2),
      WordWithDifficulty('Geai', difficulty: 2),
      WordWithDifficulty('Tourterelle', difficulty: 2),
      WordWithDifficulty('Faisan', difficulty: 2),
      WordWithDifficulty('Perdrix', difficulty: 2),
      WordWithDifficulty('Caille', difficulty: 2),
      WordWithDifficulty('Bécasse', difficulty: 3),
      WordWithDifficulty('Héron', difficulty: 2),
      WordWithDifficulty('Grue', difficulty: 2),
      WordWithDifficulty('Cormoran', difficulty: 3),
      WordWithDifficulty('Goéland', difficulty: 2),
      WordWithDifficulty('Macareux', difficulty: 3),
      WordWithDifficulty('Martin-pêcheur', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - POISSONS
      // ============================================

      // POISSONS - Facile
      WordWithDifficulty('Sardine', difficulty: 1),
      WordWithDifficulty('Maquereau', difficulty: 2),
      WordWithDifficulty('Anchois', difficulty: 2),
      WordWithDifficulty('Hareng', difficulty: 2),
      WordWithDifficulty('Sole', difficulty: 2),
      WordWithDifficulty('Cabillaud', difficulty: 2),
      WordWithDifficulty('Morue', difficulty: 2),
      WordWithDifficulty('Merlan', difficulty: 2),
      WordWithDifficulty('Daurade', difficulty: 2),
      WordWithDifficulty('Bar', difficulty: 2),
      WordWithDifficulty('Loup de mer', difficulty: 2),
      WordWithDifficulty('Rouget', difficulty: 3),
      WordWithDifficulty('Turbot', difficulty: 3),
      WordWithDifficulty('Flétan', difficulty: 3),
      WordWithDifficulty('Espadon', difficulty: 2),
      WordWithDifficulty('Mérou', difficulty: 3),
      WordWithDifficulty('Lieu', difficulty: 3),
      WordWithDifficulty('Colin', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - BOISSONS
      // ============================================

      // BOISSONS CHAUDES - Facile
      WordWithDifficulty('Café', difficulty: 1),
      WordWithDifficulty('Thé', difficulty: 1),
      WordWithDifficulty('Chocolat chaud', difficulty: 1),
      WordWithDifficulty('Cappuccino', difficulty: 1),
      WordWithDifficulty('Expresso', difficulty: 2),
      WordWithDifficulty('Latte', difficulty: 2),
      WordWithDifficulty('Infusion', difficulty: 2),
      WordWithDifficulty('Tisane', difficulty: 2),
      WordWithDifficulty('Thé vert', difficulty: 2),
      WordWithDifficulty('Maté', difficulty: 3),

      // BOISSONS FROIDES - Facile
      WordWithDifficulty('Jus d\'orange', difficulty: 1),
      WordWithDifficulty('Jus de pomme', difficulty: 1),
      WordWithDifficulty('Limonade', difficulty: 1),
      WordWithDifficulty('Coca-Cola', difficulty: 1),
      WordWithDifficulty('Orangina', difficulty: 1),
      WordWithDifficulty('Sprite', difficulty: 1),
      WordWithDifficulty('Fanta', difficulty: 1),
      WordWithDifficulty('Eau gazeuse', difficulty: 1),
      WordWithDifficulty('Sirop', difficulty: 1),
      WordWithDifficulty('Smoothie', difficulty: 1),
      WordWithDifficulty('Milkshake', difficulty: 1),
      WordWithDifficulty('Jus de raisin', difficulty: 1),
      WordWithDifficulty('Thé glacé', difficulty: 1),
      WordWithDifficulty('Citronnade', difficulty: 2),
      WordWithDifficulty('Grenadine', difficulty: 2),

      // BOISSONS ALCOOLISÉES - Moyen
      WordWithDifficulty('Bière', difficulty: 1),
      WordWithDifficulty('Vin rouge', difficulty: 1),
      WordWithDifficulty('Vin blanc', difficulty: 1),
      WordWithDifficulty('Rosé', difficulty: 1),
      WordWithDifficulty('Cidre', difficulty: 1),
      WordWithDifficulty('Whisky', difficulty: 2),
      WordWithDifficulty('Vodka', difficulty: 2),
      WordWithDifficulty('Rhum', difficulty: 2),
      WordWithDifficulty('Gin', difficulty: 2),
      WordWithDifficulty('Tequila', difficulty: 2),
      WordWithDifficulty('Cognac', difficulty: 2),
      WordWithDifficulty('Pastis', difficulty: 2),
      WordWithDifficulty('Mojito', difficulty: 2),
      WordWithDifficulty('Margarita', difficulty: 2),
      WordWithDifficulty('Piña colada', difficulty: 2),
      WordWithDifficulty('Sangria', difficulty: 2),
      WordWithDifficulty('Kir', difficulty: 2),
      WordWithDifficulty('Spritz', difficulty: 2),

      // BOISSONS ALCOOLISÉES - Difficile
      WordWithDifficulty('Armagnac', difficulty: 3),
      WordWithDifficulty('Calvados', difficulty: 3),
      WordWithDifficulty('Limoncello', difficulty: 3),
      WordWithDifficulty('Amaretto', difficulty: 3),
      WordWithDifficulty('Chartreuse', difficulty: 3),
      WordWithDifficulty('Génépi', difficulty: 3),
      WordWithDifficulty('Absinthe', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - CONDIMENTS ET SAUCES
      // ============================================

      // CONDIMENTS - Facile
      WordWithDifficulty('Sel', difficulty: 1),
      WordWithDifficulty('Poivre', difficulty: 1),
      WordWithDifficulty('Moutarde', difficulty: 1),
      WordWithDifficulty('Ketchup', difficulty: 1),
      WordWithDifficulty('Vinaigre', difficulty: 1),
      WordWithDifficulty('Huile d\'olive', difficulty: 1),
      WordWithDifficulty('Sucre', difficulty: 1),
      WordWithDifficulty('Miel', difficulty: 1),
      WordWithDifficulty('Confiture', difficulty: 1),
      WordWithDifficulty('Beurre', difficulty: 1),
      WordWithDifficulty('Crème', difficulty: 1),
      WordWithDifficulty('Sauce tomate', difficulty: 1),
      WordWithDifficulty('Sauce soja', difficulty: 2),
      WordWithDifficulty('Sauce barbecue', difficulty: 2),
      WordWithDifficulty('Tabasco', difficulty: 2),

      // CONDIMENTS - Moyen
      WordWithDifficulty('Harissa', difficulty: 2),
      WordWithDifficulty('Wasabi', difficulty: 2),
      WordWithDifficulty('Nuoc-mâm', difficulty: 3),
      WordWithDifficulty('Pesto', difficulty: 2),
      WordWithDifficulty('Guacamole', difficulty: 2),
      WordWithDifficulty('Tzatziki', difficulty: 2),
      WordWithDifficulty('Aïoli', difficulty: 2),
      WordWithDifficulty('Tapenade', difficulty: 2),
      WordWithDifficulty('Chutney', difficulty: 3),
      WordWithDifficulty('Cornichon', difficulty: 1),
      WordWithDifficulty('Câpres', difficulty: 2),
      WordWithDifficulty('Olives', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - INGRÉDIENTS CUISINE
      // ============================================

      // PRODUITS LAITIERS - Facile
      WordWithDifficulty('Lait', difficulty: 1),
      WordWithDifficulty('Yaourt', difficulty: 1),
      WordWithDifficulty('Fromage blanc', difficulty: 1),
      WordWithDifficulty('Crème fraîche', difficulty: 1),
      WordWithDifficulty('Mascarpone', difficulty: 2),
      WordWithDifficulty('Ricotta', difficulty: 2),
      WordWithDifficulty('Mozzarella', difficulty: 1),
      WordWithDifficulty('Parmesan', difficulty: 1),
      WordWithDifficulty('Gruyère', difficulty: 1),
      WordWithDifficulty('Feta', difficulty: 2),

      // FÉCULENTS ET CÉRÉALES - Facile
      WordWithDifficulty('Farine', difficulty: 1),
      WordWithDifficulty('Pain de mie', difficulty: 1),
      WordWithDifficulty('Spaghetti', difficulty: 1),
      WordWithDifficulty('Tagliatelles', difficulty: 2),
      WordWithDifficulty('Penne', difficulty: 2),
      WordWithDifficulty('Macaroni', difficulty: 1),
      WordWithDifficulty('Semoule', difficulty: 2),
      WordWithDifficulty('Polenta', difficulty: 2),
      WordWithDifficulty('Nouilles', difficulty: 1),
      WordWithDifficulty('Vermicelles', difficulty: 2),

      // VIANDES ET PROTÉINES - Facile
      WordWithDifficulty('Poulet', difficulty: 1),
      WordWithDifficulty('Bœuf', difficulty: 1),
      WordWithDifficulty('Porc', difficulty: 1),
      WordWithDifficulty('Agneau', difficulty: 1),
      WordWithDifficulty('Veau', difficulty: 1),
      WordWithDifficulty('Dinde', difficulty: 1),
      WordWithDifficulty('Jambon', difficulty: 1),
      WordWithDifficulty('Saucisse', difficulty: 1),
      WordWithDifficulty('Bacon', difficulty: 1),
      WordWithDifficulty('Lard', difficulty: 2),
      WordWithDifficulty('Steak', difficulty: 1),
      WordWithDifficulty('Côtelette', difficulty: 2),
      WordWithDifficulty('Escalope', difficulty: 2),
      WordWithDifficulty('Filet', difficulty: 2),
      WordWithDifficulty('Cuisse', difficulty: 2),
      WordWithDifficulty('Aile', difficulty: 2),

      // CHARCUTERIE - Moyen
      WordWithDifficulty('Saucisson', difficulty: 1),
      WordWithDifficulty('Pâté', difficulty: 2),
      WordWithDifficulty('Rillettes', difficulty: 2),
      WordWithDifficulty('Chorizo', difficulty: 2),
      WordWithDifficulty('Salami', difficulty: 2),
      WordWithDifficulty('Mortadelle', difficulty: 2),
      WordWithDifficulty('Coppa', difficulty: 3),
      WordWithDifficulty('Bresaola', difficulty: 3),
      WordWithDifficulty('Jambon cru', difficulty: 2),
      WordWithDifficulty('Andouillette', difficulty: 3),
      WordWithDifficulty('Boudin', difficulty: 2),
      WordWithDifficulty('Terrine', difficulty: 2),

      // OEUFS ET DÉRIVÉS - Facile
      WordWithDifficulty('Œuf', difficulty: 1),
      WordWithDifficulty('Omelette', difficulty: 1),
      WordWithDifficulty('Œuf dur', difficulty: 1),
      WordWithDifficulty('Œuf au plat', difficulty: 1),
      WordWithDifficulty('Œuf brouillé', difficulty: 2),
      WordWithDifficulty('Œuf poché', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - DESSERTS DU MONDE
      // ============================================

      // DESSERTS INTERNATIONAUX - Facile
      WordWithDifficulty('Brownie', difficulty: 1),
      WordWithDifficulty('Cookie', difficulty: 1),
      WordWithDifficulty('Muffin', difficulty: 1),
      WordWithDifficulty('Cupcake', difficulty: 1),
      WordWithDifficulty('Cheesecake', difficulty: 1),
      WordWithDifficulty('Pancake', difficulty: 1),
      WordWithDifficulty('Donut', difficulty: 1),
      WordWithDifficulty('Churros', difficulty: 2),
      WordWithDifficulty('Glace', difficulty: 1),
      WordWithDifficulty('Sorbet', difficulty: 2),
      WordWithDifficulty('Crème glacée', difficulty: 1),
      WordWithDifficulty('Sundae', difficulty: 2),

      // DESSERTS INTERNATIONAUX - Moyen
      WordWithDifficulty('Strudel', difficulty: 2),
      WordWithDifficulty('Baklava', difficulty: 2),
      WordWithDifficulty('Mochi', difficulty: 2),
      WordWithDifficulty('Crème caramel', difficulty: 2),
      WordWithDifficulty('Flan', difficulty: 2),
      WordWithDifficulty('Pudding', difficulty: 2),
      WordWithDifficulty('Carrot cake', difficulty: 2),
      WordWithDifficulty('Banana split', difficulty: 2),
      WordWithDifficulty('Crumble', difficulty: 2),
      WordWithDifficulty('Clafoutis', difficulty: 2),
      WordWithDifficulty('Charlotte', difficulty: 2),
      WordWithDifficulty('Pavlova', difficulty: 3),
      WordWithDifficulty('Tarte Tatin', difficulty: 2),

      // CONFISERIES - Facile
      WordWithDifficulty('Bonbon', difficulty: 1),
      WordWithDifficulty('Chocolat', difficulty: 1),
      WordWithDifficulty('Caramel', difficulty: 1),
      WordWithDifficulty('Sucette', difficulty: 1),
      WordWithDifficulty('Chewing-gum', difficulty: 1),
      WordWithDifficulty('Réglisse', difficulty: 2),
      WordWithDifficulty('Nougat', difficulty: 2),
      WordWithDifficulty('Guimauve', difficulty: 2),
      WordWithDifficulty('Dragée', difficulty: 2),
      WordWithDifficulty('Praline', difficulty: 2),
      WordWithDifficulty('Calisson', difficulty: 3),
      WordWithDifficulty('Berlingot', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - FRUITS DE MER
      // ============================================

      // FRUITS DE MER - Moyen
      WordWithDifficulty('Palourde', difficulty: 2),
      WordWithDifficulty('Pétoncle', difficulty: 3),
      WordWithDifficulty('Praire', difficulty: 3),
      WordWithDifficulty('Couteau', difficulty: 2),
      WordWithDifficulty('Ormeau', difficulty: 3),
      WordWithDifficulty('Oursin', difficulty: 2),
      WordWithDifficulty('Gambas', difficulty: 2),
      WordWithDifficulty('Coquillage', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - ANIMAUX SUPPLÉMENTAIRES
      // ============================================

      // ANIMAUX DE FERME - Facile
      WordWithDifficulty('Bélier', difficulty: 2),
      WordWithDifficulty('Brebis', difficulty: 2),
      WordWithDifficulty('Poussin', difficulty: 1),
      WordWithDifficulty('Poulain', difficulty: 2),
      WordWithDifficulty('Taureau', difficulty: 2),
      WordWithDifficulty('Jument', difficulty: 2),
      WordWithDifficulty('Étalon', difficulty: 2),
      WordWithDifficulty('Truie', difficulty: 2),
      WordWithDifficulty('Verrat', difficulty: 3),

      // RONGEURS ET PETITS ANIMAUX - Moyen
      WordWithDifficulty('Gerbille', difficulty: 2),
      WordWithDifficulty('Chinchilla', difficulty: 2),
      WordWithDifficulty('Mulot', difficulty: 2),
      WordWithDifficulty('Campagnol', difficulty: 3),
      WordWithDifficulty('Musaraigne', difficulty: 3),
      WordWithDifficulty('Lemming', difficulty: 3),
      WordWithDifficulty('Marmotte', difficulty: 2),

      // CERVIDÉS - Moyen
      WordWithDifficulty('Biche', difficulty: 2),
      WordWithDifficulty('Faon', difficulty: 2),
      WordWithDifficulty('Chevreuil', difficulty: 2),
      WordWithDifficulty('Daim', difficulty: 2),
      WordWithDifficulty('Orignal', difficulty: 3),

      // BOVIDÉS - Moyen
      WordWithDifficulty('Bouc', difficulty: 2),
      WordWithDifficulty('Bouquetin', difficulty: 3),
      WordWithDifficulty('Mouflon', difficulty: 3),
      WordWithDifficulty('Chamois', difficulty: 2),
      WordWithDifficulty('Gnou', difficulty: 3),
      WordWithDifficulty('Zébu', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - PLANTES SUPPLÉMENTAIRES
      // ============================================

      // PLANTES D'INTÉRIEUR - Moyen
      WordWithDifficulty('Cactus', difficulty: 1),
      WordWithDifficulty('Aloe vera', difficulty: 2),
      WordWithDifficulty('Ficus', difficulty: 2),
      WordWithDifficulty('Philodendron', difficulty: 3),
      WordWithDifficulty('Monstera', difficulty: 2),
      WordWithDifficulty('Yucca', difficulty: 2),
      WordWithDifficulty('Dracaena', difficulty: 3),
      WordWithDifficulty('Pothos', difficulty: 3),

      // ARBUSTES - Moyen
      WordWithDifficulty('Buis', difficulty: 2),
      WordWithDifficulty('Houx', difficulty: 2),
      WordWithDifficulty('Laurier', difficulty: 2),
      WordWithDifficulty('Forsythia', difficulty: 3),
      WordWithDifficulty('Azalée', difficulty: 2),
      WordWithDifficulty('Troène', difficulty: 3),
      WordWithDifficulty('Genêt', difficulty: 3),
      WordWithDifficulty('Aubépine', difficulty: 3),
      WordWithDifficulty('Sureau', difficulty: 3),

      // PLANTES GRIMPANTES - Moyen
      WordWithDifficulty('Vigne', difficulty: 1),
      WordWithDifficulty('Clématite', difficulty: 3),
      WordWithDifficulty('Chèvrefeuille', difficulty: 3),
      WordWithDifficulty('Passiflore', difficulty: 3),
      WordWithDifficulty('Bougainvillier', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - MÉTÉO ET ENVIRONNEMENT
      // ============================================

      // ÉLÉMENTS NATURELS - Facile
      WordWithDifficulty('Sable', difficulty: 1),
      WordWithDifficulty('Roche', difficulty: 1),
      WordWithDifficulty('Terre', difficulty: 1),
      WordWithDifficulty('Boue', difficulty: 1),
      WordWithDifficulty('Argile', difficulty: 2),
      WordWithDifficulty('Gravier', difficulty: 2),
      WordWithDifficulty('Caillou', difficulty: 1),
      WordWithDifficulty('Galet', difficulty: 2),

      // PHÉNOMÈNES MÉTÉO SUPPLÉMENTAIRES - Moyen
      WordWithDifficulty('Averse', difficulty: 2),
      WordWithDifficulty('Giboulée', difficulty: 3),
      WordWithDifficulty('Rafale', difficulty: 2),
      WordWithDifficulty('Bourrasque', difficulty: 3),
      WordWithDifficulty('Accalmie', difficulty: 3),
      WordWithDifficulty('Canicule', difficulty: 2),
      WordWithDifficulty('Gel', difficulty: 1),
      WordWithDifficulty('Dégel', difficulty: 2),
      WordWithDifficulty('Fonte', difficulty: 2),

      // ============================================
      // FIN SECTION GASTRONOMIE ET ENRICHISSEMENT
      // ============================================

  ],
);
