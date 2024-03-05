class FirebaseItem {
  final String katBroj;
  final String? barkod;
  String? slika;
  String? listingId;
  double? price;

  FirebaseItem({
    required this.katBroj,
    this.barkod,
    this.slika,
    this.listingId,
    this.price,
  });

// Metoda za kreiranje instance ProductDetail iz JSON objekta
  factory FirebaseItem.fromJson(Map<String, dynamic> json) {
    if (json['katBroj'] == null) {
      throw Exception('ProductDetail.fromJson: katBroj is null in $json');
    }

    return FirebaseItem(
      katBroj: json['katBroj'] as String,
      barkod: json['barkod'] as String?,
      slika: json['slika'] as String?,
      listingId: json['listingId'] as String?,
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : null,
    );
  }

  // Method to convert an instance of ProductDetail to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'katBroj': katBroj,
      'barkod': barkod,
      'slika': slika,
      'listingId': listingId,
      'price': price,
    };
  }
}
