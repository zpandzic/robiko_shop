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
import 'package:robiko_shop/model/firebase_item.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/product_repository.dart';

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

  FirebaseItem? findFirebaseItem(String catalogNumber) {
    return ProductRepository().firebaseAllProducts[sanitizeKey(catalogNumber)];
  }

  String sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[\$\#\.\[\]\/]'), '_');
  }

  // Future<void> addData(String path, Map<String, dynamic> data) async {
  //   await database.ref(path).set(data);
  //     print('Transaction committed.');
  // }

  String? getImageFromProduct(String catalogNumber) {
    return findFirebaseItem(catalogNumber)?.slika;
  }

  Future<Map<String, dynamic>> getAllData() async {
    DatabaseEvent snapshot = await database.ref().once();
    Map<String, FirebaseItem> productDetails = {};
    Map<String, FirebaseItem> uploadedListings = {};

    Map<String, dynamic> json =
        (snapshot.snapshot.value as Map).cast<String, dynamic>();

    json.forEach((key, value) {
      FirebaseItem item =
          FirebaseItem.fromJson(Map<String, dynamic>.from(value));
      productDetails[key] = item;
      if (item.listingId != null) {
        uploadedListings[key] = item;
      }
    });

    return {
      'productDetails': productDetails,
      'uploadedListings': uploadedListings,
    };
  }

  Future<void> addProducts(List<Product> successfulUploads) async {
    Map<String, Object?> updates = {};

    for (var product in successfulUploads) {
      var savedProduct = findFirebaseItem(product.catalogNumber) ??
          FirebaseItem(
            katBroj: product.catalogNumber,
            slika: product.imageUrl,
            barkod: product.code,
            listingId: product.listingId,
            price: product.price,
          );

      savedProduct.listingId = product.listingId;
      savedProduct.price = product.price;

      String sanitizedKey = sanitizeKey(product.catalogNumber);
      updates['/$sanitizedKey'] = savedProduct.toJson();
    }

    // Izvrši sve ažuriranja u jednom pozivu
    // if (updates.isNotEmpty) {
    //   await database.ref().update(updates);
    // }
  }

  Future<void> deleteProducts(List<FirebaseItem> products) async {
    Map<String, Object?> updates = {};

    for (var product in products) {
      String sanitizedKey = sanitizeKey(product.katBroj);
      updates['/$sanitizedKey/listingId'] = null;
    }

    await database.ref().update(updates).then((_) {
      print('All selected products successfully deleted.');
    }).catchError((error) {
      print('Error deleting products: $error');

      throw Exception('Failed to delete selected products');
    });
  }
}
