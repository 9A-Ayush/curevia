import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/home_remedy_model.dart';

/// Service for home remedies and natural treatments
class HomeRemediesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all remedy categories from Firestore
  static Future<List<RemedyCategory>> getRemedyCategories() async {
    try {
      final snapshot = await _firestore.collection('remedy_categories').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RemedyCategory.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      // Fallback to local data if Firestore fails
      return _getLocalCategories();
    }
  }

  /// Get local categories as fallback
  static List<RemedyCategory> _getLocalCategories() {
    return [
      const RemedyCategory(
        id: 'respiratory',
        name: 'Respiratory',
        description: 'Remedies for cough, cold, and breathing issues',
        iconName: 'lungs',
        color: 'blue',
        remedyCount: 15,
      ),
      const RemedyCategory(
        id: 'digestive',
        name: 'Digestive',
        description: 'Natural treatments for stomach and digestive problems',
        iconName: 'stomach',
        color: 'green',
        remedyCount: 12,
      ),
      const RemedyCategory(
        id: 'skin',
        name: 'Skin Care',
        description: 'Natural remedies for skin conditions and beauty',
        iconName: 'face',
        color: 'pink',
        remedyCount: 18,
      ),
      const RemedyCategory(
        id: 'immunity',
        name: 'Immunity',
        description: 'Boost immune system naturally',
        iconName: 'shield',
        color: 'purple',
        remedyCount: 8,
      ),
    ];
  }

  /// Get remedies by category from Firestore
  static Future<List<HomeRemedyModel>> getRemediesByCategory(
    String category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('home_remedies')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HomeRemedyModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return _getLocalRemedies()
          .where((remedy) => remedy.category == category)
          .toList();
    }
  }

  /// Search remedies from Firestore
  static Future<List<HomeRemedyModel>> searchRemedies(String query) async {
    try {
      final snapshot = await _firestore.collection('home_remedies').get();
      final allRemedies = snapshot.docs.map((doc) {
        final data = doc.data();
        return HomeRemedyModel.fromJson({...data, 'id': doc.id});
      }).toList();

      final lowerQuery = query.toLowerCase();
      return allRemedies.where((remedy) {
        return remedy.name.toLowerCase().contains(lowerQuery) ||
            remedy.condition.toLowerCase().contains(lowerQuery) ||
            remedy.description.toLowerCase().contains(lowerQuery) ||
            remedy.symptoms.any(
              (symptom) => symptom.toLowerCase().contains(lowerQuery),
            ) ||
            remedy.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      return _searchLocalRemedies(query);
    }
  }

  /// Get remedy by ID from Firestore
  static Future<HomeRemedyModel?> getRemedyById(String id) async {
    try {
      final doc = await _firestore.collection('home_remedies').doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return HomeRemedyModel.fromJson({...data, 'id': doc.id});
    } catch (e) {
      return _getLocalRemedies().where((remedy) => remedy.id == id).firstOrNull;
    }
  }

  /// Get popular remedies from Firestore
  static Future<List<HomeRemedyModel>> getPopularRemedies({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('home_remedies')
          .orderBy('effectiveness', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HomeRemedyModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      final allRemedies = _getLocalRemedies();
      allRemedies.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
      return allRemedies.take(limit).toList();
    }
  }

  /// Get verified remedies
  static List<HomeRemedyModel> getVerifiedRemedies() {
    final allRemedies = getSampleRemedies();
    return allRemedies.where((remedy) => remedy.isVerified).toList();
  }

  /// Get remedies by symptoms
  static List<HomeRemedyModel> getRemediesBySymptoms(List<String> symptoms) {
    final allRemedies = getSampleRemedies();
    return allRemedies.where((remedy) {
      return symptoms.any(
        (symptom) => remedy.symptoms.any(
          (remedySymptom) =>
              remedySymptom.toLowerCase().contains(symptom.toLowerCase()),
        ),
      );
    }).toList();
  }

  /// Get sample remedies data
  static List<HomeRemedyModel> getSampleRemedies() {
    final now = DateTime.now();

    return [
      HomeRemedyModel(
        id: 'honey_ginger_tea',
        name: 'Honey Ginger Tea',
        category: 'respiratory',
        condition: 'Cough and Cold',
        description:
            'A soothing natural remedy that combines the antibacterial properties of honey with the anti-inflammatory effects of ginger to relieve cough and cold symptoms.',
        symptoms: ['Cough', 'Sore throat', 'Cold', 'Congestion'],
        ingredients: [
          const Ingredient(
            name: 'Fresh ginger',
            quantity: '1',
            unit: 'inch piece',
          ),
          const Ingredient(name: 'Honey', quantity: '2', unit: 'tablespoons'),
          const Ingredient(name: 'Hot water', quantity: '1', unit: 'cup'),
          const Ingredient(
            name: 'Lemon juice',
            quantity: '1',
            unit: 'teaspoon',
            isOptional: true,
          ),
        ],
        preparationSteps: [
          const PreparationStep(
            stepNumber: 1,
            instruction: 'Peel and slice the fresh ginger into thin pieces.',
            tip: 'Use a spoon to easily peel ginger skin',
          ),
          const PreparationStep(
            stepNumber: 2,
            instruction: 'Boil water in a pot and add the ginger slices.',
            duration: 5,
          ),
          const PreparationStep(
            stepNumber: 3,
            instruction:
                'Let it simmer for 5-10 minutes until the water turns golden.',
          ),
          const PreparationStep(
            stepNumber: 4,
            instruction: 'Strain the tea and add honey while it\'s still warm.',
            tip:
                'Don\'t add honey to boiling water as it destroys beneficial enzymes',
          ),
          const PreparationStep(
            stepNumber: 5,
            instruction: 'Add lemon juice if desired and stir well.',
          ),
        ],
        usage: 'Drink 2-3 times daily, preferably warm',
        dosage: '1 cup, 2-3 times per day',
        benefits: [
          'Soothes sore throat',
          'Reduces cough',
          'Boosts immunity',
          'Anti-inflammatory properties',
          'Natural antibacterial effects',
        ],
        precautions: [
          'Not suitable for children under 1 year due to honey',
          'Diabetics should monitor honey intake',
          'May interact with blood thinning medications',
        ],
        contraindications: [
          'Infants under 12 months',
          'Severe diabetes without medical supervision',
        ],
        preparationTime: 15,
        difficulty: 'Easy',
        effectiveness: 4.5,
        isVerified: true,
        scientificEvidence:
            'Studies show ginger has anti-inflammatory properties and honey has antimicrobial effects.',
        tags: ['natural', 'immunity', 'winter', 'traditional'],
        createdAt: now,
        updatedAt: now,
      ),
      HomeRemedyModel(
        id: 'turmeric_milk',
        name: 'Golden Turmeric Milk',
        category: 'immunity',
        condition: 'Immunity Boost',
        description:
            'A traditional Ayurvedic remedy that combines turmeric\'s powerful anti-inflammatory properties with warm milk to boost immunity and promote healing.',
        symptoms: ['Low immunity', 'Inflammation', 'Joint pain', 'Poor sleep'],
        ingredients: [
          const Ingredient(
            name: 'Turmeric powder',
            quantity: '1',
            unit: 'teaspoon',
          ),
          const Ingredient(name: 'Warm milk', quantity: '1', unit: 'cup'),
          const Ingredient(name: 'Black pepper', quantity: '1', unit: 'pinch'),
          const Ingredient(
            name: 'Honey',
            quantity: '1',
            unit: 'teaspoon',
            isOptional: true,
          ),
          const Ingredient(
            name: 'Cinnamon powder',
            quantity: '1/2',
            unit: 'teaspoon',
            isOptional: true,
          ),
        ],
        preparationSteps: [
          const PreparationStep(
            stepNumber: 1,
            instruction: 'Heat milk in a saucepan over medium heat.',
          ),
          const PreparationStep(
            stepNumber: 2,
            instruction: 'Add turmeric powder and a pinch of black pepper.',
            tip: 'Black pepper enhances turmeric absorption',
          ),
          const PreparationStep(
            stepNumber: 3,
            instruction:
                'Whisk well to avoid lumps and simmer for 2-3 minutes.',
          ),
          const PreparationStep(
            stepNumber: 4,
            instruction:
                'Remove from heat and add honey and cinnamon if using.',
          ),
          const PreparationStep(
            stepNumber: 5,
            instruction: 'Stir well and serve warm.',
          ),
        ],
        usage: 'Drink before bedtime for best results',
        dosage: '1 cup daily, preferably at night',
        benefits: [
          'Boosts immune system',
          'Reduces inflammation',
          'Improves sleep quality',
          'Supports joint health',
          'Rich in antioxidants',
        ],
        precautions: [
          'May stain teeth and clothes',
          'Can increase bleeding risk if on blood thinners',
          'May worsen acid reflux in some people',
        ],
        contraindications: [
          'Gallstones',
          'Blood clotting disorders',
          'Before surgery (stop 2 weeks prior)',
        ],
        preparationTime: 10,
        difficulty: 'Easy',
        effectiveness: 4.3,
        isVerified: true,
        scientificEvidence:
            'Curcumin in turmeric has proven anti-inflammatory and antioxidant properties.',
        tags: ['ayurvedic', 'immunity', 'anti-inflammatory', 'bedtime'],
        createdAt: now,
        updatedAt: now,
      ),
      HomeRemedyModel(
        id: 'aloe_vera_gel',
        name: 'Fresh Aloe Vera Gel',
        category: 'skin',
        condition: 'Skin Irritation',
        description:
            'Pure aloe vera gel extracted from fresh leaves provides natural healing and moisturizing properties for various skin conditions.',
        symptoms: [
          'Sunburn',
          'Dry skin',
          'Minor cuts',
          'Skin irritation',
          'Acne',
        ],
        ingredients: [
          const Ingredient(
            name: 'Fresh aloe vera leaf',
            quantity: '1',
            unit: 'large leaf',
          ),
        ],
        preparationSteps: [
          const PreparationStep(
            stepNumber: 1,
            instruction: 'Cut a fresh aloe vera leaf from the plant.',
            tip: 'Choose thick, mature leaves for maximum gel content',
          ),
          const PreparationStep(
            stepNumber: 2,
            instruction:
                'Wash the leaf thoroughly and let it drain for 10 minutes.',
            tip: 'This removes the yellow latex which can be irritating',
          ),
          const PreparationStep(
            stepNumber: 3,
            instruction:
                'Cut off the spiky edges and slice the leaf lengthwise.',
          ),
          const PreparationStep(
            stepNumber: 4,
            instruction: 'Scoop out the clear gel using a spoon.',
          ),
          const PreparationStep(
            stepNumber: 5,
            instruction: 'Blend the gel until smooth if desired, or use as is.',
          ),
        ],
        usage: 'Apply directly to affected skin area',
        dosage: 'Apply 2-3 times daily as needed',
        benefits: [
          'Soothes sunburn',
          'Moisturizes dry skin',
          'Promotes wound healing',
          'Reduces inflammation',
          'Natural antimicrobial properties',
        ],
        precautions: [
          'Test on small skin area first',
          'Avoid if allergic to aloe',
          'Don\'t use on deep wounds',
        ],
        contraindications: ['Allergy to aloe vera', 'Deep or infected wounds'],
        preparationTime: 5,
        difficulty: 'Easy',
        effectiveness: 4.7,
        isVerified: true,
        scientificEvidence:
            'Aloe vera contains compounds that promote healing and have anti-inflammatory effects.',
        tags: ['natural', 'skincare', 'healing', 'moisturizing'],
        createdAt: now,
        updatedAt: now,
      ),
      HomeRemedyModel(
        id: 'peppermint_tea',
        name: 'Peppermint Tea for Digestion',
        category: 'digestive',
        condition: 'Digestive Issues',
        description:
            'Refreshing peppermint tea that helps soothe digestive discomfort and promotes healthy digestion.',
        symptoms: ['Indigestion', 'Bloating', 'Nausea', 'Stomach cramps'],
        ingredients: [
          const Ingredient(
            name: 'Fresh peppermint leaves',
            quantity: '10-15',
            unit: 'leaves',
          ),
          const Ingredient(name: 'Hot water', quantity: '1', unit: 'cup'),
          const Ingredient(
            name: 'Honey',
            quantity: '1',
            unit: 'teaspoon',
            isOptional: true,
          ),
        ],
        preparationSteps: [
          const PreparationStep(
            stepNumber: 1,
            instruction: 'Wash fresh peppermint leaves thoroughly.',
          ),
          const PreparationStep(
            stepNumber: 2,
            instruction:
                'Place leaves in a cup and pour hot (not boiling) water over them.',
            tip: 'Boiling water can destroy delicate oils',
          ),
          const PreparationStep(
            stepNumber: 3,
            instruction: 'Cover and steep for 5-7 minutes.',
          ),
          const PreparationStep(
            stepNumber: 4,
            instruction: 'Strain the tea and add honey if desired.',
          ),
        ],
        usage: 'Drink after meals for best digestive benefits',
        dosage: '1 cup after meals, up to 3 times daily',
        benefits: [
          'Relieves indigestion',
          'Reduces bloating',
          'Soothes stomach cramps',
          'Freshens breath',
          'Calms nausea',
        ],
        precautions: [
          'May worsen acid reflux in some people',
          'Can interact with certain medications',
          'Avoid if pregnant without consulting doctor',
        ],
        contraindications: [
          'Severe acid reflux',
          'Gallstones',
          'Hiatal hernia',
        ],
        preparationTime: 10,
        difficulty: 'Easy',
        effectiveness: 4.2,
        isVerified: true,
        scientificEvidence:
            'Peppermint oil has been shown to relax digestive muscles and reduce IBS symptoms.',
        tags: ['digestive', 'natural', 'refreshing', 'after-meals'],
        createdAt: now,
        updatedAt: now,
      ),
      HomeRemedyModel(
        id: 'chamomile_tea',
        name: 'Chamomile Tea for Sleep',
        category: 'sleep',
        condition: 'Insomnia and Anxiety',
        description:
            'Gentle chamomile tea that promotes relaxation and helps improve sleep quality naturally.',
        symptoms: ['Insomnia', 'Anxiety', 'Stress', 'Restlessness'],
        ingredients: [
          const Ingredient(
            name: 'Dried chamomile flowers',
            quantity: '1',
            unit: 'tablespoon',
          ),
          const Ingredient(name: 'Hot water', quantity: '1', unit: 'cup'),
          const Ingredient(
            name: 'Honey',
            quantity: '1',
            unit: 'teaspoon',
            isOptional: true,
          ),
        ],
        preparationSteps: [
          const PreparationStep(
            stepNumber: 1,
            instruction:
                'Boil water and let it cool slightly (not boiling hot).',
          ),
          const PreparationStep(
            stepNumber: 2,
            instruction:
                'Add chamomile flowers to a tea infuser or directly to cup.',
          ),
          const PreparationStep(
            stepNumber: 3,
            instruction: 'Pour hot water over chamomile and cover.',
          ),
          const PreparationStep(
            stepNumber: 4,
            instruction: 'Steep for 5-10 minutes for stronger effect.',
          ),
          const PreparationStep(
            stepNumber: 5,
            instruction: 'Strain and add honey if desired.',
          ),
        ],
        usage: 'Drink 30 minutes before bedtime',
        dosage: '1 cup before sleep',
        benefits: [
          'Promotes better sleep',
          'Reduces anxiety',
          'Calms nervous system',
          'Mild sedative effect',
          'Reduces inflammation',
        ],
        precautions: [
          'May cause drowsiness',
          'Can interact with blood thinners',
          'Allergic reactions possible',
        ],
        contraindications: [
          'Allergy to ragweed family',
          'Pregnancy (large amounts)',
          'Before driving or operating machinery',
        ],
        preparationTime: 12,
        difficulty: 'Easy',
        effectiveness: 4.4,
        isVerified: true,
        scientificEvidence:
            'Chamomile contains apigenin, which binds to brain receptors to promote sleepiness.',
        tags: ['sleep', 'relaxation', 'bedtime', 'anxiety'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Get local remedies as fallback
  static List<HomeRemedyModel> _getLocalRemedies() {
    return getSampleRemedies();
  }

  /// Search local remedies as fallback
  static List<HomeRemedyModel> _searchLocalRemedies(String query) {
    final allRemedies = getSampleRemedies();
    final lowerQuery = query.toLowerCase();

    return allRemedies.where((remedy) {
      return remedy.name.toLowerCase().contains(lowerQuery) ||
          remedy.condition.toLowerCase().contains(lowerQuery) ||
          remedy.description.toLowerCase().contains(lowerQuery) ||
          remedy.symptoms.any(
            (symptom) => symptom.toLowerCase().contains(lowerQuery),
          ) ||
          remedy.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get herbs encyclopedia from Firestore
  static Future<List<HerbModel>> getHerbsEncyclopedia() async {
    try {
      final snapshot = await _firestore.collection('herbs').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HerbModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return _getLocalHerbs();
    }
  }

  /// Get local herbs as fallback
  static List<HerbModel> _getLocalHerbs() {
    final now = DateTime.now();

    return [
      HerbModel(
        id: 'turmeric',
        name: 'Turmeric',
        scientificName: 'Curcuma longa',
        description:
            'A golden-colored spice with powerful anti-inflammatory and antioxidant properties.',
        commonNames: ['Haldi', 'Indian Saffron', 'Golden Spice'],
        properties: [
          'Anti-inflammatory',
          'Antioxidant',
          'Antimicrobial',
          'Hepatoprotective',
        ],
        uses: [
          'Inflammation',
          'Digestive issues',
          'Skin conditions',
          'Immunity boost',
        ],
        benefits: [
          'Reduces inflammation',
          'Supports liver health',
          'Boosts immune system',
          'May help with arthritis',
          'Supports brain health',
        ],
        sideEffects: ['May stain skin/teeth', 'Stomach upset in large doses'],
        contraindications: ['Gallstones', 'Blood clotting disorders'],
        origin: 'Southeast Asia',
        availability: 'Widely available',
        createdAt: now,
        updatedAt: now,
      ),
      HerbModel(
        id: 'ginger',
        name: 'Ginger',
        scientificName: 'Zingiber officinale',
        description:
            'A warming root with digestive and anti-nausea properties.',
        commonNames: ['Adrak', 'Fresh Ginger Root'],
        properties: [
          'Anti-nausea',
          'Digestive',
          'Anti-inflammatory',
          'Warming',
        ],
        uses: ['Nausea', 'Digestive issues', 'Cold and flu', 'Motion sickness'],
        benefits: [
          'Reduces nausea',
          'Aids digestion',
          'Anti-inflammatory effects',
          'May reduce muscle pain',
          'Supports immune system',
        ],
        sideEffects: ['Heartburn', 'Stomach upset in large doses'],
        contraindications: ['Gallstones', 'Blood thinning medications'],
        origin: 'Southeast Asia',
        availability: 'Widely available',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
