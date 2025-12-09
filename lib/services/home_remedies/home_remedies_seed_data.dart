import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/home_remedy_model.dart';

/// Service to seed home remedies data into Firestore
class HomeRemediesSeedData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all home remedies to Firestore
  static Future<void> seedAllRemedies() async {
    try {
      print('Starting to seed home remedies...');
      
      final remedies = _getAllRemedies();
      
      for (var remedy in remedies) {
        await _firestore
            .collection('homeRemedies')
            .doc(remedy.id)
            .set(remedy.toJson());
        print('Added remedy: ${remedy.name}');
      }
      
      print('Successfully seeded ${remedies.length} home remedies!');
    } catch (e) {
      print('Error seeding remedies: $e');
      rethrow;
    }
  }

  /// Get all home remedies
  static List<HomeRemedyModel> _getAllRemedies() {
    return [
      ..._getRespiratoryRemedies(),
      ..._getImmunityRemedies(),
      ..._getSkinCareRemedies(),
      ..._getDigestiveRemedies(),
      ..._getOralCareRemedies(),
      ..._getHairCareRemedies(),
      ..._getSleepRemedies(),
      ..._getJointPainRemedies(),
      ..._getStressRemedies(),
      ..._getMenstrualRemedies(),
      ..._getChildrenRemedies(),
      ..._getFirstAidRemedies(),
    ];
  }

  static List<HomeRemedyModel> _getRespiratoryRemedies() {
    final now = DateTime.now();
    
    return [
      HomeRemedyModel(
        id: 'resp_001',
        name: 'Warm Honey Water',
        category: 'Respiratory Health',
        condition: 'Cough and Sore Throat',
        description: 'A soothing drink that helps calm coughs and throat irritation using honey\'s natural antimicrobial properties.',
        symptoms: ['Cough', 'Sore throat', 'Throat irritation'],
        ingredients: [
          Ingredient(name: 'Honey', quantity: '1-2', unit: 'teaspoons'),
          Ingredient(name: 'Warm water or herbal tea', quantity: '1', unit: 'cup'),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Heat water until warm (not boiling)',
            duration: 2,
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Mix 1-2 teaspoons of honey into the warm water',
          ),
          PreparationStep(
            stepNumber: 3,
            instruction: 'Stir well until honey is completely dissolved',
          ),
        ],
        usage: 'Sip slowly to soothe coughs and throat irritation',
        dosage: 'Drink 1-2 times daily as needed',
        benefits: [
          'Soothes throat irritation',
          'Calms cough symptoms',
          'Mild antimicrobial properties',
          'Natural and gentle remedy',
        ],
        precautions: [
          'Use only for adults and children over 1 year old',
          'Never give honey to infants under 12 months',
          'Ensure water is warm, not boiling',
        ],
        contraindications: ['Infants under 1 year', 'Honey allergy'],
        preparationTime: 5,
        difficulty: 'Easy',
        effectiveness: 4.0,
        isVerified: true,
        scientificEvidence: 'Honey has mild antimicrobial properties and can calm cough symptoms',
        tags: ['Cough', 'Sore throat', 'Natural', 'Easy', 'Children-safe'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'resp_002',
        name: 'Ginger-Lemon Tea',
        category: 'Respiratory Health',
        condition: 'Cold Symptoms',
        description: 'A spicy, warming tea that helps relieve congestion and throat pain using ginger\'s anti-inflammatory properties.',
        symptoms: ['Congestion', 'Throat pain', 'Cold symptoms', 'Runny nose'],
        ingredients: [
          Ingredient(name: 'Fresh ginger', quantity: '1-2', unit: 'inches'),
          Ingredient(name: 'Water', quantity: '2', unit: 'cups'),
          Ingredient(name: 'Lemon juice', quantity: '1', unit: 'tablespoon'),
          Ingredient(name: 'Honey', quantity: '1', unit: 'teaspoon', isOptional: true),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Slice or grate 1-2 inches of fresh ginger',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Add ginger to boiling water and simmer for 5-10 minutes',
            duration: 10,
          ),
          PreparationStep(
            stepNumber: 3,
            instruction: 'Strain the tea into a cup',
          ),
          PreparationStep(
            stepNumber: 4,
            instruction: 'Add lemon juice and honey to taste',
          ),
        ],
        usage: 'Drink this spicy tea to relieve congestion and throat pain',
        dosage: '1-2 times daily',
        benefits: [
          'Relieves congestion',
          'Reduces throat pain',
          'Anti-inflammatory properties',
          'Boosts immune system',
          'Warms the body',
        ],
        precautions: [
          'Fresh ginger can be strong for children',
          'Omit honey for children under 1 year',
          'May cause heartburn in sensitive individuals',
        ],
        contraindications: ['Ginger allergy', 'Severe acid reflux'],
        preparationTime: 15,
        difficulty: 'Easy',
        effectiveness: 4.5,
        isVerified: true,
        scientificEvidence: 'Ginger\'s anti-inflammatory compounds can help reduce cold symptoms',
        tags: ['Cold', 'Congestion', 'Natural', 'Anti-inflammatory'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'resp_003',
        name: 'Saltwater Gargle',
        category: 'Respiratory Health',
        condition: 'Sore Throat',
        description: 'A simple hypertonic saline solution that helps draw out mucus and soothe a scratchy throat.',
        symptoms: ['Sore throat', 'Scratchy throat', 'Throat mucus'],
        ingredients: [
          Ingredient(name: 'Salt', quantity: '1/4', unit: 'teaspoon'),
          Ingredient(name: 'Warm water', quantity: '1/2', unit: 'cup'),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Dissolve 1/4 teaspoon of salt in 1/2 cup of warm water',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Stir until salt is completely dissolved',
          ),
        ],
        usage: 'Gargle for 15-30 seconds and spit out',
        dosage: 'Repeat 2-3 times daily',
        benefits: [
          'Draws out mucus',
          'Soothes scratchy throat',
          'Reduces throat inflammation',
          'Simple and effective',
        ],
        precautions: [
          'Do not swallow the solution',
          'Supervise younger children who can gargle',
          'Not for infants',
          'Avoid excessive use if you have high blood pressure',
        ],
        contraindications: ['Cannot gargle', 'Severe hypertension'],
        preparationTime: 2,
        difficulty: 'Easy',
        effectiveness: 4.0,
        isVerified: true,
        scientificEvidence: 'Hypertonic saline solution helps draw out mucus and soothe throat',
        tags: ['Sore throat', 'Quick', 'Easy', 'Inexpensive'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'resp_004',
        name: 'Steam Inhalation',
        category: 'Respiratory Health',
        condition: 'Nasal Congestion',
        description: 'Warm moist air therapy that loosens mucus and relieves congestion.',
        symptoms: ['Nasal congestion', 'Stuffy nose', 'Sinus pressure'],
        ingredients: [
          Ingredient(name: 'Hot water', quantity: '1', unit: 'bowl'),
          Ingredient(name: 'Eucalyptus or peppermint oil', quantity: '2-3', unit: 'drops', isOptional: true),
          Ingredient(name: 'Towel', quantity: '1', unit: 'piece'),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Fill a bowl with hot (not boiling) water',
            tip: 'Test temperature to avoid burns',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Add a few drops of eucalyptus or peppermint oil if available',
          ),
          PreparationStep(
            stepNumber: 3,
            instruction: 'Lean over the bowl with a towel draped over your head',
          ),
          PreparationStep(
            stepNumber: 4,
            instruction: 'Inhale deeply for 5-10 minutes',
            duration: 10,
            tip: 'Keep eyes closed to avoid irritation',
          ),
        ],
        usage: 'Inhale steam to loosen mucus and relieve congestion',
        dosage: '1-2 times daily',
        benefits: [
          'Loosens mucus',
          'Relieves congestion',
          'Opens nasal passages',
          'Soothes irritated airways',
        ],
        precautions: [
          'Keep face at safe distance from hot water',
          'Keep eyes closed to avoid irritation',
          'Only for adults and older children',
          'Beware of burns',
        ],
        contraindications: ['Young children', 'Cannot maintain safe distance'],
        preparationTime: 10,
        difficulty: 'Easy',
        effectiveness: 4.0,
        isVerified: true,
        scientificEvidence: 'Warm moist air loosens mucus and relieves congestion',
        tags: ['Congestion', 'Sinus', 'Steam', 'Natural'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'resp_005',
        name: 'Chicken Broth or Soup',
        category: 'Respiratory Health',
        condition: 'Cold Relief',
        description: 'Traditional remedy that provides fluids, nutrients, and helps thin mucus.',
        symptoms: ['Cold', 'Congestion', 'Dehydration', 'Weakness'],
        ingredients: [
          Ingredient(name: 'Chicken or vegetable broth', quantity: '1-2', unit: 'cups'),
          Ingredient(name: 'Vegetables', quantity: 'As desired', isOptional: true),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Prepare homemade chicken or vegetable soup',
            duration: 30,
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Ensure soup is warm but not too hot',
          ),
        ],
        usage: 'Drink warm soup to stay hydrated and soothe throat',
        dosage: '1-2 bowls daily',
        benefits: [
          'Provides fluids and nutrients',
          'Helps thin mucus',
          'Keeps you hydrated',
          'Soothes the throat',
          'Warms the body',
        ],
        precautions: [
          'Avoid giving very hot soup to small children',
          'Check temperature before serving',
        ],
        contraindications: ['Specific food allergies'],
        preparationTime: 30,
        difficulty: 'Easy',
        effectiveness: 3.5,
        isVerified: true,
        scientificEvidence: 'Traditional remedy that soothes throat and provides hydration',
        tags: ['Cold', 'Nutrition', 'Hydration', 'Comfort food'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<HomeRemedyModel> _getImmunityRemedies() {
    final now = DateTime.now();
    
    return [
      HomeRemedyModel(
        id: 'imm_001',
        name: 'Raw Garlic',
        category: 'Immunity Boosting',
        condition: 'Immune Support',
        description: 'Garlic contains allicin with antiviral properties that can help fight common cold and flu viruses.',
        symptoms: ['Weak immunity', 'Frequent colds', 'Flu prevention'],
        ingredients: [
          Ingredient(name: 'Fresh garlic cloves', quantity: '1-2', unit: 'cloves'),
          Ingredient(name: 'Water', quantity: '1', unit: 'glass'),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Crush or finely chop 1-2 garlic cloves',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Swallow with water or add to soups and stir-fries',
          ),
        ],
        usage: 'Consume daily during cold/flu season for immune support',
        dosage: '1-2 cloves daily',
        benefits: [
          'Contains allicin with antiviral properties',
          'Helps fight cold and flu viruses',
          'Boosts immune system',
          'Natural antibiotic properties',
        ],
        precautions: [
          'Raw garlic can burn the mouth',
          'Mix into food for easier consumption',
          'Avoid excessive amounts if prone to stomach upset',
        ],
        contraindications: ['Garlic allergy', 'Bleeding disorders', 'Before surgery'],
        preparationTime: 2,
        difficulty: 'Easy',
        effectiveness: 4.0,
        isVerified: true,
        scientificEvidence: 'Studies suggest garlic can help fight common cold and flu viruses',
        tags: ['Immunity', 'Antiviral', 'Natural antibiotic', 'Prevention'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'imm_002',
        name: 'Golden Milk (Turmeric-Ginger Drink)',
        category: 'Immunity Boosting',
        condition: 'Immune Support & Inflammation',
        description: 'Anti-inflammatory golden milk rich in antioxidants that may strengthen immunity.',
        symptoms: ['Weak immunity', 'Inflammation', 'Joint pain'],
        ingredients: [
          Ingredient(name: 'Milk (dairy or plant-based)', quantity: '1', unit: 'cup'),
          Ingredient(name: 'Turmeric powder', quantity: '1/2-1', unit: 'teaspoon'),
          Ingredient(name: 'Black pepper', quantity: '1', unit: 'pinch', notes: 'Activates curcumin'),
          Ingredient(name: 'Fresh ginger', quantity: '1', unit: 'small piece', notes: 'Grated'),
          Ingredient(name: 'Honey', quantity: '1', unit: 'teaspoon', isOptional: true),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Heat 1 cup of milk in a saucepan',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Add turmeric powder, black pepper, and grated ginger',
          ),
          PreparationStep(
            stepNumber: 3,
            instruction: 'Simmer for 5-10 minutes',
            duration: 10,
          ),
          PreparationStep(
            stepNumber: 4,
            instruction: 'Strain and sweeten with honey if desired',
          ),
        ],
        usage: 'Drink once nightly for immune support',
        dosage: '1 cup before bedtime',
        benefits: [
          'Anti-inflammatory properties',
          'Rich in antioxidants',
          'Strengthens immunity',
          'Reduces joint pain',
          'Promotes better sleep',
        ],
        precautions: [
          'May be spicy for children',
          'Skip honey for babies under 1 year',
          'Turmeric can stain',
        ],
        contraindications: ['Dairy allergy', 'Turmeric allergy', 'Gallbladder problems'],
        preparationTime: 15,
        difficulty: 'Easy',
        effectiveness: 4.5,
        isVerified: true,
        scientificEvidence: 'Curcumin and ginger have proven anti-inflammatory and immune-boosting properties',
        tags: ['Immunity', 'Anti-inflammatory', 'Antioxidant', 'Sleep'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'imm_003',
        name: 'Honey-Lemon Water',
        category: 'Immunity Boosting',
        condition: 'Hydration & Immune Support',
        description: 'Simple tonic that hydrates, provides vitamin C, and uses honey\'s soothing effects.',
        symptoms: ['Dehydration', 'Weak immunity', 'Sore throat'],
        ingredients: [
          Ingredient(name: 'Honey', quantity: '1', unit: 'teaspoon'),
          Ingredient(name: 'Fresh lemon juice', quantity: '1', unit: 'tablespoon'),
          Ingredient(name: 'Warm water', quantity: '1', unit: 'glass'),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Squeeze fresh lemon juice',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Stir honey and lemon juice into warm water',
          ),
          PreparationStep(
            stepNumber: 3,
            instruction: 'Mix well until honey dissolves',
          ),
        ],
        usage: 'Drink in the morning or when sick',
        dosage: '1 glass daily',
        benefits: [
          'Hydrates the body',
          'Provides vitamin C',
          'Soothes mucous membranes',
          'Boosts immunity',
          'Refreshing taste',
        ],
        precautions: [
          'Not for infants under 1 year',
          'Be mindful of citrus if you have acid reflux',
        ],
        contraindications: ['Honey allergy', 'Citrus allergy', 'Severe acid reflux'],
        preparationTime: 3,
        difficulty: 'Easy',
        effectiveness: 3.5,
        isVerified: true,
        scientificEvidence: 'Vitamin C supports immune function; honey soothes throat',
        tags: ['Immunity', 'Hydration', 'Vitamin C', 'Quick'],
        createdAt: now,
        updatedAt: now,
      ),
      
      HomeRemedyModel(
        id: 'imm_004',
        name: 'Probiotic Yogurt or Kefir',
        category: 'Immunity Boosting',
        condition: 'Gut-Immune Health',
        description: 'Beneficial bacteria that help balance gut flora, linked to stronger immune response.',
        symptoms: ['Weak immunity', 'Digestive issues', 'Frequent infections'],
        ingredients: [
          Ingredient(name: 'Plain yogurt or kefir with live cultures', quantity: '1', unit: 'cup'),
        ],
        preparationSteps: [
          PreparationStep(
            stepNumber: 1,
            instruction: 'Choose plain yogurt or kefir containing live probiotic cultures',
          ),
          PreparationStep(
            stepNumber: 2,
            instruction: 'Consume directly or add to smoothies',
          ),
        ],
        usage: 'Eat or drink once daily for gut health',
        dosage: '1 cup daily',
        benefits: [
          'Balances gut flora',
          'Strengthens immune response',
          'Improves digestion',
          'Provides probiotics',
          'Good source of protein and calcium',
        ],
        precautions: [
          'Choose unsweetened varieties',
          'Infants can have yogurt after 6 months',
        ],
        contraindications: ['Lactose intolerance', 'Dairy allergy'],
        preparationTime: 0,
        difficulty: 'Easy',
        effectiveness: 4.0,
        isVerified: true,
        scientificEvidence: 'Probiotics help balance gut flora, linked to stronger immune system',
        tags: ['Immunity', 'Probiotics', 'Gut health', 'Nutrition'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Continue with other categories...
  static List<HomeRemedyModel> _getSkinCareRemedies() {
    // Implementation for skin care remedies
    return [];
  }

  static List<HomeRemedyModel> _getDigestiveRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getOralCareRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getHairCareRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getSleepRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getJointPainRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getStressRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getMenstrualRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getChildrenRemedies() {
    return [];
  }

  static List<HomeRemedyModel> _getFirstAidRemedies() {
    return [];
  }
}
