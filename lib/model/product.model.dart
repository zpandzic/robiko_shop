import 'package:robiko_shop/model/listing.model.dart';
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

  // Convert a Product to a Listing Map
  Map<String, dynamic> toListing() {
    return {
      'title': '$name $catalogNumber',
      'listing_type': 'sell', // Assuming 'sell' as default
      'description': description,
      'price': price,
      'category_id': categoryId,
      'attributes': attributesList
              ?.where((attr) => attr.value.isNotEmpty)
              .map((attr) => attr.toJson())
              .toList() ??
          [],
      'available': true, // Assuming always true
      'state': 'new', // Assuming 'new' as default
      'country_id': 49, // Set default or dynamic value
      'city_id': 16, // Set default or dynamic value
    };
  }

  // Map<String, dynamic> toListing() {
  //   Map<String, dynamic> listingData = {
  //     'title': 'Treci test',
  //     'listing_type': 'sell',
  //     'description': 'Test description',
  //     'price': 100,
  //     'category_id': 947,
  //     'attributes': [
  //       {'id': 7192, 'value': 'Prodaja'}
  //     ],
  //     'available': true,
  //     'state': 'new',
  //     'country_id': 49,
  //     'city_id': 16,
  //   };

  //   return listingData;
  // }
}
