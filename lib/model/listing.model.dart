class Listing {
  final dynamic score;
  final int id;
  final String type;
  final String title;
  final int categoryId;
  final int topCategoryId;
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
  final String image;

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
    required this.image,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      score: json['score'], // Assuming score can be null or int
      id: int.parse(json['id'].toString()),
      type: json['type'],
      title: json['title'],
      categoryId: int.parse(json['category_id'].toString()),
      topCategoryId: int.parse(json['top_category_id'].toString()),
      brandId: json['brand_id'], // Assuming brandId can be null or int
      cityId: int.parse(json['city_id'].toString()),
      hasDiscount: json['has_discount'],
      discountedPriceFloat:
          double.parse(json['discounted_price_float'].toString()),
      discountedPrice: json['discounted_price'],
      showPrice: json['show_price'],
      price: double.parse(json['price'].toString()),
      displayPrice: json['display_price'],
      priceMax: double.parse(json['price_max'].toString()),
      date: int.parse(json['date'].toString()),
      image: json['image'],
    );
  }

  @override
  String toString() {
    return 'Listing{score: $score, id: $id, type: $type, title: $title, categoryId: $categoryId, topCategoryId: $topCategoryId, brandId: $brandId, cityId: $cityId, hasDiscount: $hasDiscount, discountedPriceFloat: $discountedPriceFloat, discountedPrice: $discountedPrice, showPrice: $showPrice, price: $price, displayPrice: $displayPrice, priceMax: $priceMax, date: $date, image: $image}';
  }
}
