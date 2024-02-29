class JsonSavedArticle {
  final String listingId;
  // final String title;
  final double price;

  JsonSavedArticle({
    required this.listingId,
    required this.price,
  });

  factory JsonSavedArticle.fromJson(Map<String, dynamic> json) {
    return JsonSavedArticle(
      listingId: json['listingId'] as String,
      price: json['price'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'price': price,
    };
  }
}
