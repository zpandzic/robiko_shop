import 'package:robiko_shop/model/visokaZaliheData.model.dart';
import 'package:robiko_shop/screens/products_screen.dart';

class Product {
  final String imageUrl;
  final String name;
  final String code;
  final String catalogNumber;
  final String description;
  late List<AttributeValue>? attributesList;
  String? category;
  int? categoryId;
  final double price;

  Product({
    required this.imageUrl,
    required this.name,
    required this.code,
    required this.catalogNumber,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.price,
    required this.attributesList,
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
        category: null,
        categoryId: null,
        attributesList: null,
        price: visokaZalihe.mpc,
      );
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'name': name,
      'code': code,
      'catalogNumber': catalogNumber,
      'description': description,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'attributesList': attributesList?.map((e) => e.toJson()).toList(),
    };
  }
}
