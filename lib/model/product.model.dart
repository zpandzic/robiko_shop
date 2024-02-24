import 'package:robiko_shop/model/attribute_value.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/visokaZaliheData.model.dart';

class Product {
  final String imageUrl;
  String name;
  final String code;
  String catalogNumber;
  String description;
  late List<AttributeValue>? attributesList;
  String? category;
  int? categoryId;
  double price;
  String? listingId;

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
    this.listingId,
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
  // Map<String, dynamic> toListing() {
  //   return {
  //     'title': '$name $catalogNumber',
  //     'listing_type': 'sell', // Assuming 'sell' as default
  //     'description': description,
  //     'price': price,
  //     'category_id': categoryId,
  //     'attributes': attributesList
  //             ?.where((attr) => attr.value.isNotEmpty)
  //             .map((attr) => attr.toJson())
  //             .toList() ??
  //         [],
  //     'available': true, // Assuming always true
  //     'state': 'new', // Assuming 'new' as default
  //     'country_id': 49, // Set default or dynamic value
  //     'city_id': 16, // Set default or dynamic value
  //   };
  // }

  Map<String, dynamic> toListing() {
    // Kreirajte mapu bez ključa 'attributes' na početku
    final Map<String, dynamic> listing = {
      'title': '$name $catalogNumber',
      'listing_type': 'sell', // Assuming 'sell' as default
      'description': description,
      'price': price,
      'category_id': categoryId,
      'available': true, // Assuming always true
      'state': 'new', // Assuming 'new' as default
      'country_id': 49, // Set default or dynamic value
      'city_id': 16, // Set default or dynamic value
    };

    // Dodajte 'attributes' samo ako attributesList postoji i nije prazan
    if (attributesList != null && attributesList!.isNotEmpty) {
      listing['attributes'] = attributesList!
          .where((attr) => attr.value.isNotEmpty)
          .map((attr) => attr.toJson())
          .toList();
    }

    return listing;
  }

  static Product fromListing(Listing listing) {
    return Product(
      imageUrl: listing.image ?? 'https://via.placeholder.com/150', // Ako `listing.image` ne postoji, koristi placeholder
      name: listing.title,
      code: listing.id.toString(), // Pretvaranje `id` u string možda nije idealno za `code`, ali ovo je samo primjer
      catalogNumber: '', // Ovisno o strukturi `Listing`, možda ćete trebati dodati odgovarajuće polje
      description: 'Opis nije dostupan', // Pretpostavka da `Listing` sadrži `description`
      category: null, // Možda će biti potrebno dodatno mapiranje za kategoriju
      categoryId: listing.categoryId,
      price: listing.price,
      attributesList: [], // Ovisno o `Listing`, možda ćete trebati implementirati logiku za mapiranje atributa
    );

    return Product(
      imageUrl: listing.image ?? 'https://via.placeholder.com/150',
      name: listing.title,
      code: listing.id.toString(),
      catalogNumber: listing.id.toString(),
      description: listing.title,
      category: listing.listing_type,
      categoryId: listing.categoryId,
      price: listing.price,
      attributesList: null,
      listingId: listing.id.toString(),

      // catalogNumber: '', // Ovisno o strukturi `Listing`, možda ćete trebati dodati odgovarajuće polje
      // description: listing.description ?? 'Opis nije dostupan', // Pretpostavka da `Listing` sadrži `description`
      // category: null, // Možda će biti potrebno dodatno mapiranje za kategoriju
      // categoryId: listing.categoryId,
      // price: listing.price,
      // attributesList: [], // Ovisno o `Listing`, možda ćete trebati implementirati logiku za mapiranje atributa

    );
  }
}
