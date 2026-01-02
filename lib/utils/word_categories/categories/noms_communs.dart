import '../models.dart';

const categoryNomsCommuns = WordCategory(
  id: 'noms_communs',
  name: 'Noms communs',
  icon: '🔧',
  words: [

      // OBJETS ÉLECTRONIQUES - Facile
      WordWithDifficulty('Téléphone', difficulty: 1),
      WordWithDifficulty('Ordinateur', difficulty: 1),
      WordWithDifficulty('Télévision', difficulty: 1),
      WordWithDifficulty('Radio', difficulty: 1),
      WordWithDifficulty('Appareil photo', difficulty: 1),
      WordWithDifficulty('Console de jeux', difficulty: 1),

      // OBJETS ÉLECTRONIQUES - Moyen
      WordWithDifficulty('Tablette', difficulty: 1),
      WordWithDifficulty('Casque', difficulty: 1),
      WordWithDifficulty('Enceinte', difficulty: 2),
      WordWithDifficulty('Chargeur', difficulty: 1),
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
      WordWithDifficulty('Brosse à dents', difficulty: 1),
      WordWithDifficulty('Peigne', difficulty: 1),
      WordWithDifficulty('Savon', difficulty: 1),
      WordWithDifficulty('Serviette', difficulty: 1),
      WordWithDifficulty('Télécommande', difficulty: 1),

      // OBJETS QUOTIDIEN - Moyen
      WordWithDifficulty('Lampe', difficulty: 1),
      WordWithDifficulty('Horloge', difficulty: 2),
      WordWithDifficulty('Réveil', difficulty: 1),
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
      WordWithDifficulty('Matelas', difficulty: 2),
      WordWithDifficulty('Oreiller', difficulty: 1),
      WordWithDifficulty('Couverture', difficulty: 1),
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
      WordWithDifficulty('Wi-Fi', difficulty: 2),
      WordWithDifficulty('Bluetooth', difficulty: 2),
      WordWithDifficulty('Code-barres', difficulty: 2),
      WordWithDifficulty('Fermeture éclair', difficulty: 3),
      WordWithDifficulty('Velcro', difficulty: 3),
      WordWithDifficulty('Post-it', difficulty: 2),
      WordWithDifficulty('Laser', difficulty: 2),

      // MAISON & HABITAT - Pièces - Facile
      WordWithDifficulty('Cuisine', difficulty: 1),
      WordWithDifficulty('Chambre', difficulty: 1),
      WordWithDifficulty('Salon', difficulty: 1),
      WordWithDifficulty('Salle de bain', difficulty: 1),
      WordWithDifficulty('Garage', difficulty: 1),

      // MAISON & HABITAT - Pièces - Moyen
      WordWithDifficulty('Cave', difficulty: 2),
      WordWithDifficulty('Grenier', difficulty: 2),
      WordWithDifficulty('Couloir', difficulty: 1),
      WordWithDifficulty('Entrée', difficulty: 1),
      WordWithDifficulty('Terrasse', difficulty: 2),
      WordWithDifficulty('Balcon', difficulty: 2),

      // MAISON & HABITAT - Pièces - Difficile
      WordWithDifficulty('Buanderie', difficulty: 2),
      WordWithDifficulty('Cellier', difficulty: 2),
      WordWithDifficulty('Véranda', difficulty: 2),
      WordWithDifficulty('Vestibule', difficulty: 3),

      // MAISON & HABITAT - Éléments construction - Facile
      WordWithDifficulty('Porte', difficulty: 1),
      WordWithDifficulty('Fenêtre', difficulty: 1),
      WordWithDifficulty('Mur', difficulty: 1),
      WordWithDifficulty('Toit', difficulty: 1),
      WordWithDifficulty('Escalier', difficulty: 1),

      // MAISON & HABITAT - Éléments construction - Moyen
      WordWithDifficulty('Cheminée', difficulty: 2),
      WordWithDifficulty('Plafond', difficulty: 2),
      WordWithDifficulty('Sol', difficulty: 2),
      WordWithDifficulty('Volet', difficulty: 2),
      WordWithDifficulty('Radiateur', difficulty: 2),
      WordWithDifficulty('Interrupteur', difficulty: 2),
      WordWithDifficulty('Prise', difficulty: 2),

      // MAISON & HABITAT - Éléments construction - Difficile
      WordWithDifficulty('Plinthe', difficulty: 3),
      WordWithDifficulty('Corniche', difficulty: 3),
      WordWithDifficulty('Gouttière', difficulty: 2),
      WordWithDifficulty('Charpente', difficulty: 2),
      WordWithDifficulty('Tuile', difficulty: 2),
      WordWithDifficulty('Ardoise', difficulty: 2),

      // MAISON & HABITAT - Bâtiments - Facile
      WordWithDifficulty('Maison', difficulty: 1),
      WordWithDifficulty('Immeuble', difficulty: 1),
      WordWithDifficulty('École', difficulty: 1),
      WordWithDifficulty('Hôpital', difficulty: 1),
      WordWithDifficulty('Église', difficulty: 1),

      // MAISON & HABITAT - Bâtiments - Moyen
      WordWithDifficulty('Château', difficulty: 2),
      WordWithDifficulty('Pont', difficulty: 2),
      WordWithDifficulty('Tour', difficulty: 2),
      WordWithDifficulty('Musée', difficulty: 2),
      WordWithDifficulty('Gare', difficulty: 2),
      WordWithDifficulty('Aéroport', difficulty: 2),

      // MAISON & HABITAT - Bâtiments - Difficile
      WordWithDifficulty('Cathédrale', difficulty: 2),
      WordWithDifficulty('Beffroi', difficulty: 3),
      WordWithDifficulty('Phare', difficulty: 2),
      WordWithDifficulty('Donjon', difficulty: 2),
      WordWithDifficulty('Aqueduc', difficulty: 3),

      // ÉDUCATION & LOISIRS - Matériel scolaire - Facile
      WordWithDifficulty('Cartable', difficulty: 1),
      WordWithDifficulty('Trousse', difficulty: 1),
      WordWithDifficulty('Gomme', difficulty: 1),
      WordWithDifficulty('Taille-crayon', difficulty: 1),
      WordWithDifficulty('Feutre', difficulty: 1),
      WordWithDifficulty('Surligneur', difficulty: 1),

      // ÉDUCATION & LOISIRS - Matériel scolaire - Moyen
      WordWithDifficulty('Rapporteur', difficulty: 2),
      WordWithDifficulty('Compas', difficulty: 2),
      WordWithDifficulty('Équerre', difficulty: 2),
      WordWithDifficulty('Classeur', difficulty: 2),
      WordWithDifficulty('Cahier de texte', difficulty: 2),

      // ÉDUCATION & LOISIRS - Matériel scolaire - Difficile
      WordWithDifficulty('Plumier', difficulty: 3),
      WordWithDifficulty('Protège-cahier', difficulty: 3),
      WordWithDifficulty('Perforatrice', difficulty: 3),

      // ÉDUCATION & LOISIRS - Matériel bureau - Facile
      WordWithDifficulty('Agrafeuse', difficulty: 1),
      WordWithDifficulty('Trombones', difficulty: 1),
      WordWithDifficulty('Scotch', difficulty: 1),

      // ÉDUCATION & LOISIRS - Matériel bureau - Moyen
      WordWithDifficulty('Dégrafeuse', difficulty: 3),
      WordWithDifficulty('Colle', difficulty: 2),
      WordWithDifficulty('Punaises', difficulty: 2),
      WordWithDifficulty('Élastiques', difficulty: 2),

      // ÉDUCATION & LOISIRS - Matériel bureau - Difficile
      WordWithDifficulty('Massicot', difficulty: 3),
      WordWithDifficulty('Reliure', difficulty: 3),

      // ÉDUCATION & LOISIRS - Jouets - Facile
      WordWithDifficulty('Ballon', difficulty: 1),
      WordWithDifficulty('Poupée', difficulty: 1),
      WordWithDifficulty('Voiture miniature', difficulty: 1),
      WordWithDifficulty('Puzzle', difficulty: 1),
      WordWithDifficulty('Peluche', difficulty: 1),

      // ÉDUCATION & LOISIRS - Jouets - Moyen
      WordWithDifficulty('Jeu de société', difficulty: 2),
      WordWithDifficulty('Lego', difficulty: 2),
      WordWithDifficulty('Yo-yo', difficulty: 2),
      WordWithDifficulty('Toupie', difficulty: 2),
      WordWithDifficulty('Marionnette', difficulty: 2),
      WordWithDifficulty('Cerf-volant', difficulty: 2),

      // ÉDUCATION & LOISIRS - Jouets - Difficile
      WordWithDifficulty('Bilboquet', difficulty: 3),
      WordWithDifficulty('Diabolo', difficulty: 2),
      WordWithDifficulty('Kapla', difficulty: 2),
      WordWithDifficulty('Billes', difficulty: 2),

      // ÉDUCATION & LOISIRS - Sports - Facile
      WordWithDifficulty('Raquette', difficulty: 1),
      WordWithDifficulty('Ballon de foot', difficulty: 1),
      WordWithDifficulty('Basket', difficulty: 1),
      WordWithDifficulty('Skis', difficulty: 1),

      // ÉDUCATION & LOISIRS - Sports - Moyen
      WordWithDifficulty('Club de golf', difficulty: 2),
      WordWithDifficulty('Crosse de hockey', difficulty: 2),
      WordWithDifficulty('Arc', difficulty: 2),
      WordWithDifficulty('Flèche', difficulty: 2),
      WordWithDifficulty('Haltères', difficulty: 2),
      WordWithDifficulty('Corde à sauter', difficulty: 2),

      // EXTÉRIEUR & JARDINAGE - Facile
      WordWithDifficulty('Pelle', difficulty: 1),
      WordWithDifficulty('Râteau', difficulty: 1),
      WordWithDifficulty('Arrosoir', difficulty: 1),
      WordWithDifficulty('Tuyau', difficulty: 1),
      WordWithDifficulty('Seau', difficulty: 1),

      // EXTÉRIEUR & JARDINAGE - Moyen
      WordWithDifficulty('Brouette', difficulty: 2),
      WordWithDifficulty('Tondeuse', difficulty: 2),
      WordWithDifficulty('Tronçonneuse', difficulty: 2),
      WordWithDifficulty('Bêche', difficulty: 2),
      WordWithDifficulty('Pioche', difficulty: 2),
      WordWithDifficulty('Sécateur', difficulty: 2),
      WordWithDifficulty('Cisailles', difficulty: 3),

      // EXTÉRIEUR & JARDINAGE - Difficile
      WordWithDifficulty('Binette', difficulty: 3),

      // ACCESSOIRES & DÉCORATION - Bijoux - Facile
      WordWithDifficulty('Collier', difficulty: 1),
      WordWithDifficulty('Bracelet', difficulty: 1),
      WordWithDifficulty('Bague', difficulty: 1),
      WordWithDifficulty('Boucles d\'oreilles', difficulty: 1),

      // ACCESSOIRES & DÉCORATION - Bijoux - Moyen
      WordWithDifficulty('Broche', difficulty: 2),
      WordWithDifficulty('Pendentif', difficulty: 2),
      WordWithDifficulty('Médaillon', difficulty: 2),
      WordWithDifficulty('Chevalière', difficulty: 2),

      // ACCESSOIRES & DÉCORATION - Bijoux - Difficile
      WordWithDifficulty('Diadème', difficulty: 2),
      WordWithDifficulty('Parure', difficulty: 3),
      WordWithDifficulty('Jonc', difficulty: 3),

      // ACCESSOIRES & DÉCORATION - Récipients - Facile
      WordWithDifficulty('Boîte', difficulty: 1),
      WordWithDifficulty('Bocal', difficulty: 1),
      WordWithDifficulty('Bouteille', difficulty: 1),
      WordWithDifficulty('Sac plastique', difficulty: 1),

      // ACCESSOIRES & DÉCORATION - Récipients - Moyen
      WordWithDifficulty('Carafe', difficulty: 2),
      WordWithDifficulty('Cruche', difficulty: 2),
      WordWithDifficulty('Pot', difficulty: 2),
      WordWithDifficulty('Corbeille', difficulty: 2),
      WordWithDifficulty('Urne', difficulty: 2),

      // ACCESSOIRES & DÉCORATION - Récipients - Difficile
      WordWithDifficulty('Amphore', difficulty: 2),
      WordWithDifficulty('Fiole', difficulty: 2),
      WordWithDifficulty('Bonbonne', difficulty: 2),
      WordWithDifficulty('Flacon', difficulty: 2),

  ],
);
