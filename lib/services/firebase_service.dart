// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_core/firebase_core.dart';
//
// class FirebaseService {
//   static final FirebaseService _instance = FirebaseService._internal();
//   late final FirebaseDatabase database;
//
//   factory FirebaseService() {
//     return _instance;
//   }
//
//   FirebaseService._internal() {
//    database = FirebaseDatabase.instanceFor(
//       app: Firebase.app(),
//       databaseURL: 'https://robikoshop-1df62-default-rtdb.europe-west1.firebasedatabase.app/',
//     );
//   }
//
//   Future<void> addData(String path, Map<String, dynamic> data) async {
//     await database.ref(path).set(data);
//     print('Transaction committed.');
//   }
//
//   Future<void> getAllData(String path) async {
//     DatabaseEvent snapshot = await database.ref(path).once();
//     print('Data: ${snapshot.snapshot.value}');
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late final FirebaseDatabase database;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal() {
    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://robikoshop-1df62-default-rtdb.europe-west1.firebasedatabase.app/',
    );
  }

  Future<void> addData(String path, Map<String, dynamic> data) async {
    await database.ref(path).set(data);
    print('Transaction committed.');
  }

  Future<void> getAllData() async {
    // DatabaseEvent snapshot = await database.ref().once();
    // database.once().then((DatabaseEvent snapshot) {
    //   print('Data : ${snapshot.snapshot.value}');
    // });

    fetchProductItems().then((value) {
      print('Data: $value');
    });
  }

  Future<Map<String, ProductDetail>> fetchProductItems() async {
    DatabaseEvent snapshot = await database.ref().once();
    Map<String, ProductDetail> productDetails = {};

    Map<String, dynamic> json =
        (snapshot.snapshot.value as Map).cast<String, dynamic>();

    json.forEach((key, value) {
      productDetails[key] =
          ProductDetail.fromJson(Map<String, dynamic>.from(value));
    });

    return productDetails;
  }
}

class ProductDetail {
  final String katBroj;
  final String? barkod;
  final String? slika;
  final String?
      listingId; // Optional, as it might not be available for all entries
  final double? price; // Optional, as it might not be available for all entries

  ProductDetail({
    required this.katBroj,
    this.barkod,
    this.slika,
    this.listingId,
    this.price,
  });

// Metoda za kreiranje instance ProductDetail iz JSON objekta
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
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
