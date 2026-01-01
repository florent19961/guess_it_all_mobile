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
);
