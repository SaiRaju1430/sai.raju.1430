class DemoImageItem {
  final String name;
  final String assetPath;
  final String category;
  final String defaultUnit;
  final String defaultDescription;

  const DemoImageItem({
    required this.name,
    required this.assetPath,
    required this.category,
    this.defaultUnit = 'kg',
    this.defaultDescription = '',
  });
}

class DemoImages {
  // 17 General Product Demo Items
  static const List<DemoImageItem> generalProducts = [
    DemoImageItem(
      name: 'Carrot',
      assetPath: 'assets/demo_products/carrot.png',
      category: 'Vegetables',
      defaultUnit: 'kg',
      defaultDescription: 'Fresh farm-picked orange crunchy carrots, rich in Vitamin A.',
    ),
    DemoImageItem(
      name: 'Cucumber',
      assetPath: 'assets/demo_products/cucumber.png',
      category: 'Vegetables',
      defaultUnit: 'kg',
      defaultDescription: 'Crisp and hydrating garden fresh green cucumbers.',
    ),
    DemoImageItem(
      name: 'Banana',
      assetPath: 'assets/demo_products/banana.png',
      category: 'Fruits',
      defaultUnit: 'kg',
      defaultDescription: 'Naturally ripened sweet and energy-packed bananas.',
    ),
    DemoImageItem(
      name: 'Pomegranate',
      assetPath: 'assets/demo_products/pomegranate.png',
      category: 'Fruits',
      defaultUnit: 'kg',
      defaultDescription: 'Juicy ruby-red seeds rich in antioxidants and vitamins.',
    ),
    DemoImageItem(
      name: 'Orange',
      assetPath: 'assets/demo_products/orange.png',
      category: 'Fruits',
      defaultUnit: 'kg',
      defaultDescription: 'Tangy, sweet, and bursting with citrus Vitamin C flavor.',
    ),
    DemoImageItem(
      name: 'Grapes',
      assetPath: 'assets/demo_products/grapes.png',
      category: 'Fruits',
      defaultUnit: 'kg',
      defaultDescription: 'Sweet and fresh seedless green grapes perfect for snacking.',
    ),
    DemoImageItem(
      name: 'Curd',
      assetPath: 'assets/demo_products/curd.png',
      category: 'Dairy',
      defaultUnit: 'packet',
      defaultDescription: 'Thick, creamy, and probiotic-rich natural farm curd.',
    ),
    DemoImageItem(
      name: 'Potato',
      assetPath: 'assets/demo_products/potato.png',
      category: 'Vegetables',
      defaultUnit: 'kg',
      defaultDescription: 'Top grade organic cooking potatoes suitable for any dish.',
    ),
    DemoImageItem(
      name: 'Salt Chips',
      assetPath: 'assets/demo_products/salt_chips.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Classic salted crispy golden potato wafers.',
    ),
    DemoImageItem(
      name: 'Banana Chips',
      assetPath: 'assets/demo_products/banana_chips.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Authentic Kerala style crispy coconut oil fried banana chips.',
    ),
    DemoImageItem(
      name: 'Potato Chilli Chips',
      assetPath: 'assets/demo_products/potato_chilli_chips.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Spicy and tangy masala coated crisp potato chips.',
    ),
    DemoImageItem(
      name: 'Cassava Tuber Chips',
      assetPath: 'assets/demo_products/cassava_tuber_chips.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Crunchy traditional tapioca/cassava roots seasoned wafers.',
    ),
    DemoImageItem(
      name: 'Cauliflower Pakoda',
      assetPath: 'assets/demo_products/cauliflower_pakoda.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Spiced gram-flour battered crispy fried cauliflower florets.',
    ),
    DemoImageItem(
      name: 'Mango Pickle',
      assetPath: 'assets/demo_products/mango_pickle.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Spicy, tangy Andhra style traditional raw mango pickle in mustard oil.',
    ),
    DemoImageItem(
      name: 'Chicken Pickle',
      assetPath: 'assets/demo_products/chicken_pickle.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Homestyle spicy boneless chicken pickle packed with rich aromatic spices.',
    ),
    DemoImageItem(
      name: 'Prawn Pickle',
      assetPath: 'assets/demo_products/prawn_pickle.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Delicious coastal spicy masala marinated prawn pickle.',
    ),
    DemoImageItem(
      name: 'Groundnut Chikki',
      assetPath: 'assets/demo_products/groundnut_chikki.png',
      category: 'Snacks',
      defaultUnit: 'packet',
      defaultDescription: 'Traditional crunchy peanut and jaggery energy candy brittle.',
    ),
  ];

  // 7 Fast Food Demo Items
  static const List<DemoImageItem> fastFood = [
    DemoImageItem(
      name: 'Chicken Fried Rice',
      assetPath: 'assets/demo_fast_food/chicken_fried_rice.png',
      category: 'Rice Items',
      defaultUnit: 'portion',
      defaultDescription: 'Wok-tossed long grain rice with shredded tender chicken, egg & seasonings.',
    ),
    DemoImageItem(
      name: 'Egg Fried Rice',
      assetPath: 'assets/demo_fast_food/egg_fried_rice.png',
      category: 'Rice Items',
      defaultUnit: 'portion',
      defaultDescription: 'Classic wok-fried rice tossed with fluffy scrambled eggs and veggies.',
    ),
    DemoImageItem(
      name: 'Veg Fried Rice',
      assetPath: 'assets/demo_fast_food/veg_fried_rice.png',
      category: 'Rice Items',
      defaultUnit: 'portion',
      defaultDescription: 'Fragrant basmati rice wok-tossed with fresh crunchy garden veggies.',
    ),
    DemoImageItem(
      name: 'Chicken Noodles',
      assetPath: 'assets/demo_fast_food/chicken_noodles.png',
      category: 'Noodles',
      defaultUnit: 'portion',
      defaultDescription: 'Stir-fried noodles with spiced juicy chicken strips, garlic and soy sauces.',
    ),
    DemoImageItem(
      name: 'Egg Noodles',
      assetPath: 'assets/demo_fast_food/egg_noodles.png',
      category: 'Noodles',
      defaultUnit: 'portion',
      defaultDescription: 'Savory stir-fried noodles loaded with golden scrambled eggs and spring onions.',
    ),
    DemoImageItem(
      name: 'Veg Noodles',
      assetPath: 'assets/demo_fast_food/veg_noodles.png',
      category: 'Noodles',
      defaultUnit: 'portion',
      defaultDescription: 'Street style Hakka noodles stir fried with julienned vegetables.',
    ),
    DemoImageItem(
      name: 'Chicken Joint',
      assetPath: 'assets/demo_fast_food/chicken_joint.png',
      category: 'Sides & Starters',
      defaultUnit: 'piece',
      defaultDescription: 'Crispy seasoned spiced chicken drumstick joint roasted to golden perfection.',
    ),
  ];
}
