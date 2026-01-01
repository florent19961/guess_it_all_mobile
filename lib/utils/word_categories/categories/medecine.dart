import '../models.dart';

const categoryMedecine = WordCategory(
  id: 'medecine',
  name: 'Médecine',
  icon: '⚕️',
  words: [

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
      WordWithDifficulty('Diaphragme', difficulty: 3),
      WordWithDifficulty('Thyroïde', difficulty: 3),
      WordWithDifficulty('Hypothalamus', difficulty: 3),
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
      WordWithDifficulty('Arthrose', difficulty: 2),
      WordWithDifficulty('Appendicite', difficulty: 2),
      WordWithDifficulty('Otite', difficulty: 2),
      WordWithDifficulty('Sinusite', difficulty: 2),
      WordWithDifficulty('Conjonctivite', difficulty: 2),
      WordWithDifficulty('Colite', difficulty: 2),
      WordWithDifficulty('Anémie', difficulty: 2),

      // MALADIES - Difficile
      WordWithDifficulty('Méningite', difficulty: 3),
      WordWithDifficulty('Hépatite', difficulty: 3),
      WordWithDifficulty('Péritonite', difficulty: 3),
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
      WordWithDifficulty('Gastro-entérologue', difficulty: 3),
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
      WordWithDifficulty('Antihistaminique', difficulty: 2),

      // ÉQUIPEMENTS - Moyen
      WordWithDifficulty('Stéthoscope', difficulty: 2),
      WordWithDifficulty('Thermomètre', difficulty: 2),
      WordWithDifficulty('Tensiomètre', difficulty: 2),
      WordWithDifficulty('Scalpel', difficulty: 2),
      WordWithDifficulty('Seringue', difficulty: 2),
      WordWithDifficulty('Bistouri', difficulty: 2),
      WordWithDifficulty('Défibrillateur', difficulty: 2),
    
  ],
);
