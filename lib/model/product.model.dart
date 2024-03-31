import 'package:robiko_shop/model/attribute_value.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/nuic_csv.dart';
import 'package:robiko_shop/model/visokaZaliheData.model.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/services/firebase_service.dart';

class Product {
  String? imageUrl;
  String name;
  String? code;
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
    return visokaZaliheList.fold<List<Product>>([],
        (List<Product> list, VisokaZalihe visokaZalihe) {
      //todo compare prices also
      if (!ProductRepository()
          .firebaseUploadedListings
          .containsKey(FirebaseService().sanitizeKey(visokaZalihe.katBroj))) {
        list.add(Product(
          imageUrl: null,
          name: visokaZalihe.nazivRobe,
          code: visokaZalihe.sifraRobe,
          catalogNumber: visokaZalihe.katBroj,
          description: '',
          category: null,
          categoryId: null,
          attributesList: null,
          price: visokaZalihe.mpc,
        ));
      }
      return list;
    });
  }

  static List<Product> fromNuicList(List<NuicCsv> nuicList) {
    return nuicList.fold<List<Product>>([], (List<Product> list, NuicCsv nuic) {
      //todo compare prices also

      if (!ProductRepository()
          .firebaseUploadedListings
          .containsKey(FirebaseService().sanitizeKey(nuic.katBroj))) {
        list.add(Product(
          imageUrl: null,
          name: nuic.nazivRobe,
          code: null,
          catalogNumber: nuic.katBroj,
          description: '',
          category: null,
          categoryId: null,
          attributesList: null,
          price: nuic.mpc,
        ));
      }
      return list;
    });
  }

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      imageUrl: json['imageUrl'],
      name: json['name'],
      code: json['code'],
      catalogNumber: json['catalogNumber'],
      description: json['description'],
      category: json['category'],
      categoryId: json['categoryId'],
      price: json['price']?.toDouble() ?? 0.0,
      // Pretpostavka ukoliko je price tipa String u JSON-u
      attributesList: json['attributesList'] != null
          ? List<AttributeValue>.from(
              json['attributesList'].map((x) => AttributeValue.fromJson(x)))
          : null,
      listingId: json['listingId'],
    );
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
    String description = this.description.isNotEmpty
        ? "${this.description.split(";").map((item) => "<p>$item</p>").join("")}<p><br></p>"
        : "";

    description +=
        "<p>Robiko d.o.o.</p><p><br></p><p>Autodijelovi<br>Servis<br>Optika trapa</p><p><br></p><p>Sovici bb Grude</p><p><br></p><p>08:00-16:00h</p><p><br></p><p>00387 39 670 959</p>";

    final Map<String, dynamic> listing = {
      'title': '$name $catalogNumber',
      'listing_type': 'sell',
      'description': description,
      'price': price,
      'category_id': categoryId,
      'available': true,
      'state': 'new', // Assuming 'new' as default
      'country_id': 49, // Set default or dynamic value
      'city_id': 16, // Set default or dynamic value
    };

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
      imageUrl: listing.image,
      name: listing.title,
      code: null,
      listingId: listing.id.toString(),
      catalogNumber: '',
      description: 'Opis nije dostupan',
      category: null,
      categoryId: listing.categoryId,
      price: listing.price,
      attributesList: [], // Ovisno o `Listing`, možda ćete trebati implementirati logiku za mapiranje atributa
    );
  }
}
