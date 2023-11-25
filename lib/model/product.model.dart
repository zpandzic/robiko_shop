import 'package:robiko_shop/model/visokaZaliheData.model.dart';

class Product {
  final String imageUrl;
  final String name;
  final String code;
  final String catalogNumber;
  final String description;
  final String category;
  final double price;

  Product({
    required this.imageUrl,
    required this.name,
    required this.code,
    required this.catalogNumber,
    required this.description,
    required this.category,
    required this.price,
  });

  // Static method to map VisokaZalihe to Product
  static List<Product> fromVisokaZaliheList(
      List<VisokaZalihe> visokaZaliheList) {
    return visokaZaliheList.map((visokaZalihe) {
      return Product(
        imageUrl: 'https://via.placeholder.com/150',
        name: visokaZalihe.nazivRobe,
        code: visokaZalihe.sifraRobe,
        catalogNumber: visokaZalihe.katBroj,
        description: 'Opis proizvoda',
        category: 'Kategorija',
        price: visokaZalihe.mpc,
      );
    }).toList();
  }
}
