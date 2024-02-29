// ignore_for_file: non_constant_identifier_names

class Listing {
  final dynamic score;
  final int id;
  final String type;
  final String title;
  final int categoryId;
  final String topCategoryId; // Promijenjeno u String zbog vašeg primjera
  final dynamic brandId;
  final int cityId;
  final bool hasDiscount;
  final double discountedPriceFloat;
  final String discountedPrice;
  final bool showPrice;
  final double price;
  final String displayPrice;
  final double priceMax;
  final int date;
  final String? image; // Može biti null

  // Dodana nova polja
  final String user_type;
  final int user_id;
  final String state;
  final String status;
  final dynamic location; // Može biti kompleksniji objekt, ovisno o strukturi
  final List<dynamic> labels; // Pretpostavljamo da je lista labela
  final String listing_type;
  final bool refresh_available;
  final dynamic special_labels; // Može biti kompleksniji objekt
  final int sponsored;

  Listing({
    this.score,
    required this.id,
    required this.type,
    required this.title,
    required this.categoryId,
    required this.topCategoryId,
    this.brandId,
    required this.cityId,
    required this.hasDiscount,
    required this.discountedPriceFloat,
    required this.discountedPrice,
    required this.showPrice,
    required this.price,
    required this.displayPrice,
    required this.priceMax,
    required this.date,
    this.image,
    // Inicijalizacija novih polja
    required this.user_type,
    required this.user_id,
    required this.state,
    required this.status,
    this.location,
    required this.labels,
    required this.listing_type,
    required this.refresh_available,
    this.special_labels,
    required this.sponsored,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      score: json['score'],
      id: json['id'],
      type: json['type'],
      title: json['title'],
      categoryId: json['category_id'],
      brandId: json['brand_id'],
      topCategoryId: json['top_category_id'].toString(),
      cityId: json['city_id'],
      hasDiscount: json['has_discount'],
      discountedPriceFloat: json['discounted_price_float'].toDouble(),
      discountedPrice: json['discounted_price'],
      showPrice: json['show_price'],
      price: json['price'].toDouble(),
      displayPrice: json['display_price'],
      priceMax: json['price_max'].toDouble(),
      date: json['date'],
      image: json['image'],
      // Mapiranje novih polja
      user_type: json['user_type'],
      user_id: json['user_id'],
      state: json['state'],
      status: json['status'],
      location: json['location'],
      labels: List<dynamic>.from(json['labels']),
      listing_type: json['listing_type'],
      refresh_available: json['refresh_available'],
      special_labels: json['special_labels'],
      sponsored: json['sponsored'],
    );
  }

  @override
  String toString() {
    return 'Listing{'
        'score: $score, '
        'id: $id, '
        'type: $type, '
        'title: $title, '
        'categoryId: $categoryId, '
        'topCategoryId: $topCategoryId, '
        'brandId: $brandId, '
        'cityId: $cityId, '
        'hasDiscount: $hasDiscount, '
        'discountedPriceFloat: $discountedPriceFloat, '
        'discountedPrice: $discountedPrice, '
        'showPrice: $showPrice, '
        'price: $price, '
        'displayPrice: $displayPrice, '
        'priceMax: $priceMax, '
        'date: $date, '
        'image: $image, '
        'user_type: $user_type, '
        'user_id: $user_id, '
        'state: $state, '
        'status: $status, '
        'location: $location, '
        'labels: $labels, '
        'listing_type: $listing_type, '
        'refresh_available: $refresh_available, '
        'special_labels: $special_labels, '
        'sponsored: $sponsored'
        '}';
  }
}
