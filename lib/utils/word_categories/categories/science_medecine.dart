// ============================================================
// CATÉGORIE : Science et Médecine
// ============================================================
//
// DESCRIPTION :
// Vocabulaire scientifique et médical : anatomie, maladies,
// éléments chimiques, astronomie, inventions et découvertes.
//
// SECTIONS EXISTANTES :
// - Anatomie (parties du corps, organes, os)
// - Maladies courantes (grippe, diabète, cancer)
// - Symptômes (fièvre, toux, douleur)
// - Spécialités médicales (cardiologie, neurologie)
// - Éléments chimiques (oxygène, hydrogène, carbone)
// - Espace et astronomie (planètes, étoiles, galaxies)
// - Inventions et découvertes
// - Scientifiques célèbres (Einstein, Newton, Curie)
// - Phénomènes physiques (gravité, électricité)
// - Unités de mesure
//
// IDÉES D'ENRICHISSEMENT :
// - Technologies médicales récentes (IRM, scanner)
// - Découvertes scientifiques 2020-2025
// - Prix Nobel et leurs découvertes
// - Maladies rares mais connues
// - Termes de biologie cellulaire
// - Minéraux et géologie
// - Théories scientifiques célèbres
//
// CRITÈRES DE DIFFICULTÉ :
// - 1 (Facile) : Connu de tous (cœur, grippe, Soleil)
// - 2 (Moyen) : Culture scientifique (ADN, photosynthèse)
// - 3 (Difficile) : Spécialisé (mitochondrie, boson de Higgs)
//
// ============================================================

import '../models.dart';

const categoryScienceMedecine = WordCategory(
  id: 'science_medecine',
  name: 'Science et Médecine',
  icon: '🔬',
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
      WordWithDifficulty('Transfusion', difficulty: 2),
      WordWithDifficulty('Greffe', difficulty: 2),
      WordWithDifficulty('Transplantation', difficulty: 2),
      WordWithDifficulty('Anesthésie', difficulty: 2),
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
      WordWithDifficulty('Radiologue', difficulty: 2),
      WordWithDifficulty('Anesthésiste', difficulty: 2),
      WordWithDifficulty('Chirurgien', difficulty: 2),
      WordWithDifficulty('Urologue', difficulty: 3),
      WordWithDifficulty('Rhumatologue', difficulty: 2),
      WordWithDifficulty('Gastro-entérologue', difficulty: 2),
      WordWithDifficulty('Oncologue', difficulty: 2),

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
      WordWithDifficulty('Tensiomètre', difficulty: 3),
      WordWithDifficulty('Scalpel', difficulty: 2),
      WordWithDifficulty('Seringue', difficulty: 2),
      WordWithDifficulty('Bistouri', difficulty: 2),
      WordWithDifficulty('Défibrillateur', difficulty: 2),

      // TRAUMATISMES / BLESSURES - Facile
      WordWithDifficulty('Bleu', difficulty: 1),
      WordWithDifficulty('Bosse', difficulty: 1),
      WordWithDifficulty('Coupure', difficulty: 1),
      WordWithDifficulty('Égratignure', difficulty: 1),

      // TRAUMATISMES / BLESSURES - Moyen
      WordWithDifficulty('Fracture', difficulty: 2),
      WordWithDifficulty('Entorse', difficulty: 2),
      WordWithDifficulty('Foulure', difficulty: 2),
      WordWithDifficulty('Brûlure', difficulty: 2),
      WordWithDifficulty('Contusion', difficulty: 2),
      WordWithDifficulty('Hématome', difficulty: 2),
      WordWithDifficulty('Ecchymose', difficulty: 2),
      WordWithDifficulty('Plaie', difficulty: 2),
      WordWithDifficulty('Hémorragie', difficulty: 2),
      WordWithDifficulty('Saignement', difficulty: 2),

      // TRAUMATISMES / BLESSURES - Difficile
      WordWithDifficulty('Luxation', difficulty: 3),
      WordWithDifficulty('Commotion', difficulty: 3),
      WordWithDifficulty('Traumatisme crânien', difficulty: 3),

      // MALADIES INFANTILES - Facile
      WordWithDifficulty('Varicelle', difficulty: 1),
      WordWithDifficulty('Rougeole', difficulty: 1),

      // MALADIES INFANTILES - Moyen
      WordWithDifficulty('Oreillons', difficulty: 2),
      WordWithDifficulty('Rubéole', difficulty: 3),

      // MALADIES INFANTILES - Difficile
      WordWithDifficulty('Coqueluche', difficulty: 3),
      WordWithDifficulty('Diphtérie', difficulty: 3),

      // DERMATOLOGIE - Facile
      WordWithDifficulty('Bouton', difficulty: 1),
      WordWithDifficulty('Acné', difficulty: 1),
      WordWithDifficulty('Verrue', difficulty: 1),

      // DERMATOLOGIE - Moyen
      WordWithDifficulty('Eczéma', difficulty: 2),
      WordWithDifficulty('Mycose', difficulty: 2),
      WordWithDifficulty('Urticaire', difficulty: 2),
      WordWithDifficulty('Zona', difficulty: 2),
      WordWithDifficulty('Furoncle', difficulty: 3),
      WordWithDifficulty('Abcès', difficulty: 2),

      // DERMATOLOGIE - Difficile
      WordWithDifficulty('Psoriasis', difficulty: 3),
      WordWithDifficulty('Vitiligo', difficulty: 3),
      WordWithDifficulty('Rosacée', difficulty: 3),
      WordWithDifficulty('Dermite', difficulty: 3),

      // PATHOLOGIES DES YEUX - Facile
      WordWithDifficulty('Myopie', difficulty: 1),
      WordWithDifficulty('Lunettes', difficulty: 1),

      // PATHOLOGIES DES YEUX - Moyen
      WordWithDifficulty('Presbytie', difficulty: 2),
      WordWithDifficulty('Astigmatisme', difficulty: 2),
      WordWithDifficulty('Strabisme', difficulty: 2),
      WordWithDifficulty('Orgelet', difficulty: 2),

      // PATHOLOGIES DES YEUX - Difficile
      WordWithDifficulty('Cataracte', difficulty: 3),
      WordWithDifficulty('Glaucome', difficulty: 3),
      WordWithDifficulty('DMLA', difficulty: 3),

      // SANTÉ MENTALE / PSYCHIATRIE - Moyen
      WordWithDifficulty('Dépression', difficulty: 2),
      WordWithDifficulty('Anxiété', difficulty: 2),
      WordWithDifficulty('Stress', difficulty: 2),
      WordWithDifficulty('Insomnie', difficulty: 2),
      WordWithDifficulty('Phobie', difficulty: 2),
      WordWithDifficulty('Anorexie', difficulty: 2),
      WordWithDifficulty('Boulimie', difficulty: 2),

      // SANTÉ MENTALE / PSYCHIATRIE - Difficile
      WordWithDifficulty('Bipolarité', difficulty: 3),
      WordWithDifficulty('Schizophrénie', difficulty: 3),
      WordWithDifficulty('TOC', difficulty: 3),
      WordWithDifficulty('Paranoïa', difficulty: 3),
      WordWithDifficulty('Burn-out', difficulty: 2),

      // CANCERS - Moyen
      WordWithDifficulty('Cancer', difficulty: 2),
      WordWithDifficulty('Tumeur', difficulty: 2),
      WordWithDifficulty('Métastase', difficulty: 2),

      // CANCERS - Difficile
      WordWithDifficulty('Leucémie', difficulty: 3),
      WordWithDifficulty('Lymphome', difficulty: 3),
      WordWithDifficulty('Mélanome', difficulty: 3),
      WordWithDifficulty('Sarcome', difficulty: 3),
      WordWithDifficulty('Carcinome', difficulty: 3),

      // MALADIES GÉNÉTIQUES - Difficile
      WordWithDifficulty('Mucoviscidose', difficulty: 3),
      WordWithDifficulty('Trisomie', difficulty: 3),
      WordWithDifficulty('Myopathie', difficulty: 3),

      // PREMIERS SECOURS / URGENCES - Facile
      WordWithDifficulty('Urgence', difficulty: 1),
      WordWithDifficulty('Ambulance', difficulty: 1),
      WordWithDifficulty('SAMU', difficulty: 1),

      // PREMIERS SECOURS / URGENCES - Moyen
      WordWithDifficulty('Massage cardiaque', difficulty: 2),
      WordWithDifficulty('Bouche-à-bouche', difficulty: 2),
      WordWithDifficulty('Garrot', difficulty: 2),
      WordWithDifficulty('Brancard', difficulty: 2),

      // MILIEU HOSPITALIER - Facile
      WordWithDifficulty('Hôpital', difficulty: 1),
      WordWithDifficulty('Clinique', difficulty: 1),
      WordWithDifficulty('Chambre', difficulty: 1),
      WordWithDifficulty('Lit', difficulty: 1),

      // MILIEU HOSPITALIER - Moyen
      WordWithDifficulty('Service', difficulty: 2),
      WordWithDifficulty('Urgences', difficulty: 2),
      WordWithDifficulty('Bloc opératoire', difficulty: 2),
      WordWithDifficulty('Salle de réveil', difficulty: 2),
      WordWithDifficulty('Consultation', difficulty: 2),
      WordWithDifficulty('Dispensaire', difficulty: 3),

      // MILIEU HOSPITALIER - Difficile
      WordWithDifficulty('Unité de soins intensifs', difficulty: 3),
      WordWithDifficulty('Bloc stérile', difficulty: 3),

      // PROFESSIONS PARAMÉDICALES - Facile
      WordWithDifficulty('Infirmier', difficulty: 1),
      WordWithDifficulty('Pharmacien', difficulty: 1),

      // PROFESSIONS PARAMÉDICALES - Moyen
      WordWithDifficulty('Aide-soignant', difficulty: 2),
      WordWithDifficulty('Sage-femme', difficulty: 2),
      WordWithDifficulty('Ambulancier', difficulty: 2),
      WordWithDifficulty('Psychologue', difficulty: 2),
      WordWithDifficulty('Orthophoniste', difficulty: 2),
      WordWithDifficulty('Podologue', difficulty: 2),
      WordWithDifficulty('Ostéopathe', difficulty: 2),
      WordWithDifficulty('Diététicien', difficulty: 2),

      // PROFESSIONS PARAMÉDICALES - Difficile
      WordWithDifficulty('Ergothérapeute', difficulty: 3),
      WordWithDifficulty('Psychomotricien', difficulty: 3),
      WordWithDifficulty('Orthoptiste', difficulty: 3),
      WordWithDifficulty('Manipulateur radio', difficulty: 3),

      // DISPOSITIFS MÉDICAUX - Moyen
      WordWithDifficulty('Prothèse', difficulty: 2),
      WordWithDifficulty('Béquilles', difficulty: 2),
      WordWithDifficulty('Fauteuil roulant', difficulty: 2),
      WordWithDifficulty('Appareil auditif', difficulty: 2),
      WordWithDifficulty('Lentilles', difficulty: 2),
      WordWithDifficulty('Pacemaker', difficulty: 2),

      // DISPOSITIFS MÉDICAUX - Difficile
      WordWithDifficulty('Stimulateur cardiaque', difficulty: 3),
      WordWithDifficulty('Pompe à insuline', difficulty: 3),
      WordWithDifficulty('Valve cardiaque', difficulty: 3),

      // VIRUS ET BACTÉRIES - Moyen
      WordWithDifficulty('Virus', difficulty: 2),
      WordWithDifficulty('Bactérie', difficulty: 2),
      WordWithDifficulty('Microbe', difficulty: 2),
      WordWithDifficulty('Infection', difficulty: 2),

      // VIRUS ET BACTÉRIES - Difficile
      WordWithDifficulty('Staphylocoque', difficulty: 3),
      WordWithDifficulty('E. coli', difficulty: 3),
      WordWithDifficulty('Salmonelle', difficulty: 3),
      WordWithDifficulty('COVID', difficulty: 3),
      WordWithDifficulty('VIH', difficulty: 3),

      // ADDICTIONS - Moyen
      WordWithDifficulty('Addiction', difficulty: 2),
      WordWithDifficulty('Dépendance', difficulty: 2),
      WordWithDifficulty('Sevrage', difficulty: 2),

      // ADDICTIONS - Difficile
      WordWithDifficulty('Alcoolisme', difficulty: 2),
      WordWithDifficulty('Tabagisme', difficulty: 2),
      WordWithDifficulty('Toxicomanie', difficulty: 3),

      // NUTRITION MÉDICALE - Facile
      WordWithDifficulty('Vitamine', difficulty: 1),
      WordWithDifficulty('Calcium', difficulty: 1),
      WordWithDifficulty('Fer', difficulty: 1),

      // NUTRITION MÉDICALE - Moyen
      WordWithDifficulty('Protéine', difficulty: 2),
      WordWithDifficulty('Glucide', difficulty: 2),
      WordWithDifficulty('Lipide', difficulty: 2),
      WordWithDifficulty('Fibre', difficulty: 2),
      WordWithDifficulty('Magnésium', difficulty: 2),
      WordWithDifficulty('Potassium', difficulty: 3),
      WordWithDifficulty('Zinc', difficulty: 2),

      // NUTRITION MÉDICALE - Difficile
      WordWithDifficulty('Oméga-3', difficulty: 3),
      WordWithDifficulty('Antioxydant', difficulty: 3),
      WordWithDifficulty('Oligoélément', difficulty: 3),

      // ============================================
      // SECTION SCIENCE
      // ============================================

      // ÉLÉMENTS CHIMIQUES - Facile
      WordWithDifficulty('Oxygène', difficulty: 1),
      WordWithDifficulty('Hydrogène', difficulty: 1),
      WordWithDifficulty('Azote', difficulty: 1),
      WordWithDifficulty('Carbone', difficulty: 1),
      WordWithDifficulty('Or', difficulty: 1),
      WordWithDifficulty('Argent', difficulty: 1),

      // ÉLÉMENTS CHIMIQUES - Moyen
      WordWithDifficulty('Hélium', difficulty: 2),
      WordWithDifficulty('Néon', difficulty: 2),
      WordWithDifficulty('Sodium', difficulty: 2),
      WordWithDifficulty('Chlore', difficulty: 2),
      WordWithDifficulty('Phosphore', difficulty: 2),
      WordWithDifficulty('Soufre', difficulty: 2),
      WordWithDifficulty('Aluminium', difficulty: 2),
      WordWithDifficulty('Cuivre', difficulty: 2),
      WordWithDifficulty('Plomb', difficulty: 2),
      WordWithDifficulty('Platine', difficulty: 3),

      // ÉLÉMENTS CHIMIQUES - Difficile
      WordWithDifficulty('Uranium', difficulty: 2),
      WordWithDifficulty('Iode', difficulty: 3),
      WordWithDifficulty('Silicium', difficulty: 3),

      // DOMAINES SCIENTIFIQUES - Facile
      WordWithDifficulty('Physique', difficulty: 1),
      WordWithDifficulty('Chimie', difficulty: 1),
      WordWithDifficulty('Biologie', difficulty: 1),
      WordWithDifficulty('Astronomie', difficulty: 1),
      WordWithDifficulty('Mathématiques', difficulty: 1),

      // DOMAINES SCIENTIFIQUES - Moyen
      WordWithDifficulty('Géologie', difficulty: 2),
      WordWithDifficulty('Écologie', difficulty: 2),
      WordWithDifficulty('Botanique', difficulty: 2),
      WordWithDifficulty('Zoologie', difficulty: 2),
      WordWithDifficulty('Génétique', difficulty: 2),
      WordWithDifficulty('Paléontologie', difficulty: 2),
      WordWithDifficulty('Archéologie', difficulty: 2),
      WordWithDifficulty('Météorologie', difficulty: 2),
      WordWithDifficulty('Océanographie', difficulty: 2),

      // DOMAINES SCIENTIFIQUES - Difficile
      WordWithDifficulty('Astrophysique', difficulty: 3),
      WordWithDifficulty('Biochimie', difficulty: 3),
      WordWithDifficulty('Microbiologie', difficulty: 3),
      WordWithDifficulty('Électromagnétisme', difficulty: 3),
      WordWithDifficulty('Thermodynamique', difficulty: 3),
      WordWithDifficulty('Mécanique quantique', difficulty: 3),
      WordWithDifficulty('Relativité générale', difficulty: 3),
      WordWithDifficulty('Cosmologie', difficulty: 3),

      // THÉORIES ET LOIS - Facile
      WordWithDifficulty('Gravité', difficulty: 1),
      WordWithDifficulty('Atome', difficulty: 1),
      WordWithDifficulty('Molécule', difficulty: 1),
      WordWithDifficulty('Énergie', difficulty: 1),

      // THÉORIES ET LOIS - Moyen
      WordWithDifficulty('Évolution', difficulty: 2),
      WordWithDifficulty('Big Bang', difficulty: 2),
      WordWithDifficulty('Photosynthèse', difficulty: 2),
      WordWithDifficulty('Magnétisme', difficulty: 2),
      WordWithDifficulty('Radioactivité', difficulty: 2),
      WordWithDifficulty('Fusion nucléaire', difficulty: 2),

      // THÉORIES ET LOIS - Difficile
      WordWithDifficulty('Relativité', difficulty: 3),
      WordWithDifficulty('Quantique', difficulty: 2),
      WordWithDifficulty('Entropie', difficulty: 3),
      WordWithDifficulty('Sélection naturelle', difficulty: 3),
      WordWithDifficulty('Tectonique des plaques', difficulty: 2),

      // ESPACE ET ASTRONOMIE - Facile
      WordWithDifficulty('Terre', difficulty: 1),
      WordWithDifficulty('Lune', difficulty: 1),
      WordWithDifficulty('Soleil', difficulty: 1),
      WordWithDifficulty('Mars', difficulty: 1),
      WordWithDifficulty('Jupiter', difficulty: 1),
      WordWithDifficulty('Saturne', difficulty: 1),
      WordWithDifficulty('Vénus', difficulty: 1),
      WordWithDifficulty('Étoile', difficulty: 1),

      // ESPACE ET ASTRONOMIE - Moyen
      WordWithDifficulty('Neptune', difficulty: 2),
      WordWithDifficulty('Uranus', difficulty: 2),
      WordWithDifficulty('Voie lactée', difficulty: 2),
      WordWithDifficulty('Système solaire', difficulty: 2),
      WordWithDifficulty('Galaxie', difficulty: 2),
      WordWithDifficulty('Satellite', difficulty: 2),
      WordWithDifficulty('Fusée', difficulty: 2),
      WordWithDifficulty('Station spatiale', difficulty: 2),
      WordWithDifficulty('Comète', difficulty: 2),
      WordWithDifficulty('Astéroïde', difficulty: 2),
      WordWithDifficulty('Éclipse', difficulty: 2),
      WordWithDifficulty('Météorite', difficulty: 2),

      // ESPACE ET ASTRONOMIE - Difficile
      WordWithDifficulty('Trou noir', difficulty: 3),
      WordWithDifficulty('Exoplanète', difficulty: 3),
      WordWithDifficulty('Constellation', difficulty: 3),
      WordWithDifficulty('Matière noire', difficulty: 3),
      WordWithDifficulty('Énergie sombre', difficulty: 3),
      WordWithDifficulty('Supernova', difficulty: 3),
      WordWithDifficulty('Nébuleuse', difficulty: 3),

      // INVENTIONS ET DÉCOUVERTES - Facile
      WordWithDifficulty('Roue', difficulty: 1),
      WordWithDifficulty('Feu', difficulty: 1),
      WordWithDifficulty('Imprimerie', difficulty: 1),
      WordWithDifficulty('Ampoule', difficulty: 1),
      WordWithDifficulty('Téléphone', difficulty: 1),
      WordWithDifficulty('Ordinateur', difficulty: 1),

      // INVENTIONS ET DÉCOUVERTES - Moyen
      WordWithDifficulty('Moteur à vapeur', difficulty: 2),
      WordWithDifficulty('Pénicilline', difficulty: 2),
      WordWithDifficulty('Microscope', difficulty: 2),
      WordWithDifficulty('Télescope', difficulty: 2),
      WordWithDifficulty('Boussole', difficulty: 2),
      WordWithDifficulty('Poudre à canon', difficulty: 2),
      WordWithDifficulty('Papier', difficulty: 2),
      WordWithDifficulty('Photographie', difficulty: 2),

      // INVENTIONS ET DÉCOUVERTES - Difficile
      WordWithDifficulty('Pasteurisation', difficulty: 3),
      WordWithDifficulty('Transistor', difficulty: 3),
      WordWithDifficulty('Laser', difficulty: 2),
      WordWithDifficulty('Fission nucléaire', difficulty: 2),
      WordWithDifficulty('Rayons X', difficulty: 3),

      // SCIENTIFIQUES CÉLÈBRES - Moyen
      WordWithDifficulty('Edison', difficulty: 2),
      WordWithDifficulty('Lavoisier', difficulty: 3),
      WordWithDifficulty('Mendeleïev', difficulty: 2),
      WordWithDifficulty('Archimède', difficulty: 2),
      WordWithDifficulty('Copernic', difficulty: 3),
      WordWithDifficulty('Kepler', difficulty: 3),

      // SCIENTIFIQUES CÉLÈBRES - Difficile
      WordWithDifficulty('Hawking', difficulty: 3),
      WordWithDifficulty('Turing', difficulty: 3),
      WordWithDifficulty('Schrödinger', difficulty: 3),
      WordWithDifficulty('Heisenberg', difficulty: 3),
      WordWithDifficulty('Bohr', difficulty: 3),
      WordWithDifficulty('Planck', difficulty: 3),
      WordWithDifficulty('Faraday', difficulty: 3),

      // PHÉNOMÈNES PHYSIQUES - Facile
      WordWithDifficulty('Lumière', difficulty: 1),
      WordWithDifficulty('Son', difficulty: 1),
      WordWithDifficulty('Chaleur', difficulty: 1),
      WordWithDifficulty('Froid', difficulty: 1),
      WordWithDifficulty('Vent', difficulty: 1),

      // PHÉNOMÈNES PHYSIQUES - Moyen
      WordWithDifficulty('Onde', difficulty: 2),
      WordWithDifficulty('Fréquence', difficulty: 2),
      WordWithDifficulty('Réfraction', difficulty: 2),
      WordWithDifficulty('Réflexion', difficulty: 2),
      WordWithDifficulty('Diffraction', difficulty: 2),
      WordWithDifficulty('Pression', difficulty: 2),
      WordWithDifficulty('Densité', difficulty: 2),
      WordWithDifficulty('Viscosité', difficulty: 2),
      WordWithDifficulty('Condensation', difficulty: 2),
      WordWithDifficulty('Évaporation', difficulty: 2),

      // PHÉNOMÈNES PHYSIQUES - Difficile
      WordWithDifficulty('Plasma', difficulty: 3),
      WordWithDifficulty('Supraconductivité', difficulty: 3),
      WordWithDifficulty('Interférence', difficulty: 3),
      WordWithDifficulty('Polarisation', difficulty: 3),
      WordWithDifficulty('Effet Doppler', difficulty: 3),

      // UNITÉS DE MESURE - Facile
      WordWithDifficulty('Mètre', difficulty: 1),
      WordWithDifficulty('Gramme', difficulty: 1),
      WordWithDifficulty('Litre', difficulty: 1),
      WordWithDifficulty('Seconde', difficulty: 1),
      WordWithDifficulty('Kilomètre', difficulty: 1),

      // UNITÉS DE MESURE - Moyen
      WordWithDifficulty('Kelvin', difficulty: 2),
      WordWithDifficulty('Newton', difficulty: 2),
      WordWithDifficulty('Joule', difficulty: 2),
      WordWithDifficulty('Watt', difficulty: 2),
      WordWithDifficulty('Volt', difficulty: 2),
      WordWithDifficulty('Ampère', difficulty: 2),
      WordWithDifficulty('Ohm', difficulty: 2),
      WordWithDifficulty('Celsius', difficulty: 2),

      // UNITÉS DE MESURE - Difficile
      WordWithDifficulty('Hertz', difficulty: 3),
      WordWithDifficulty('Pascal', difficulty: 3),
      WordWithDifficulty('Becquerel', difficulty: 3),

      // BIOLOGIE CELLULAIRE - Moyen
      WordWithDifficulty('Noyau cellulaire', difficulty: 2),
      WordWithDifficulty('Membrane', difficulty: 2),
      WordWithDifficulty('Cytoplasme', difficulty: 3),

      // BIOLOGIE CELLULAIRE - Difficile
      WordWithDifficulty('Ribosome', difficulty: 3),
      WordWithDifficulty('Enzyme', difficulty: 3),
      WordWithDifficulty('ARN', difficulty: 3),
      WordWithDifficulty('Mitose', difficulty: 3),
      WordWithDifficulty('Méiose', difficulty: 3),

      // CHIMIE - Facile
      WordWithDifficulty('Eau', difficulty: 1),
      WordWithDifficulty('Sel', difficulty: 1),
      WordWithDifficulty('Sucre', difficulty: 1),

      // CHIMIE - Moyen
      WordWithDifficulty('Acide', difficulty: 2),
      WordWithDifficulty('Base', difficulty: 2),
      WordWithDifficulty('pH', difficulty: 2),
      WordWithDifficulty('Réaction chimique', difficulty: 2),
      WordWithDifficulty('Catalyseur', difficulty: 2),
      WordWithDifficulty('Cristal', difficulty: 2),
      WordWithDifficulty('Solution', difficulty: 2),
      WordWithDifficulty('Mélange', difficulty: 2),

      // CHIMIE - Difficile
      WordWithDifficulty('Électrolyse', difficulty: 3),
      WordWithDifficulty('Oxydation', difficulty: 3),
      WordWithDifficulty('Réduction', difficulty: 3),
      WordWithDifficulty('Polymère', difficulty: 3),
      WordWithDifficulty('Isomère', difficulty: 3),
      WordWithDifficulty('Liaison covalente', difficulty: 3),

      // GÉOLOGIE ET MINÉRALOGIE - Moyen
      WordWithDifficulty('Roche sédimentaire', difficulty: 3),
      WordWithDifficulty('Roche métamorphique', difficulty: 3),
      WordWithDifficulty('Roche magmatique', difficulty: 3),
      WordWithDifficulty('Fossile', difficulty: 2),
      WordWithDifficulty('Éruption volcanique', difficulty: 2),

      // GÉOLOGIE ET MINÉRALOGIE - Difficile
      WordWithDifficulty('Magma', difficulty: 2),
      WordWithDifficulty('Sismologie', difficulty: 3),

      // ============================================
      // FIN SECTION SCIENCE
      // ============================================

  ],
);
