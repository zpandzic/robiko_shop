import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:robiko_shop/model/firebase_item.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/services/firebase_service.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();

  ProductRepository._internal();

  factory ProductRepository() => _instance;

  String? dropdownValue;
  File? selectedFile;

  List<Product> products = [];
  List<Product> readyForPublishList = [];
  List<Product> activeProductList = [];

  //Firebase
  Map<String, FirebaseItem> firebaseUploadedListings = {};
  Map<String, FirebaseItem> firebaseAllProducts = {};

  Future<void> setProducts(List<Product> products) async {
    await initializeData();

    //todo sinkronizacija

    this.products = products;
    readyForPublishList = [];
  }

  Future<void> initializeData() async {
    await getUploadedData();
    // await refreshUserListings();
  }

  Future<void> getUploadedData() async {
    var getAllData = await FirebaseService().getAllData();
    firebaseAllProducts = getAllData['productDetails'];
    firebaseUploadedListings = getAllData['uploadedListings'];
  }

  Future<bool> refreshUserListings() async {
    List<Listing> listings = await NetworkService().fetchUserListings();

    activeProductList = listings.map((listing) {
      return Product.fromListing(listing);
    }).toList();
    return true;
  }

  // Method to delete a product by catalog number
  void deleteProduct(String catalogNumber) {
    products.removeWhere((product) => product.catalogNumber == catalogNumber);
    // Additional code for state management
  }

  // Method to edit a product
  void editProduct(String catalogNumber, Product updatedProduct) {
    int index = products
        .indexWhere((product) => product.catalogNumber == catalogNumber);
    if (index != -1) {
      products[index] = updatedProduct;
      // Additional code for state management
    }
  }

  // Method to filter products based on a query
  List<Product> filterProducts(String query) {
    return products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void printFormattedJson() {
    JsonEncoder encoder =
        const JsonEncoder.withIndent('  '); // Two-space indentation
    String prettyPrint =
        encoder.convert(products.map((e) => e.toJson()).toList());

    print(prettyPrint);
  }

  void moveProductsToReadyForPublishList(List<Product> productsToUpdate) {
    for (var product in productsToUpdate) {
      if (!readyForPublishList
          .any((p) => p.catalogNumber == product.catalogNumber)) {
        readyForPublishList.add(product);
      }
    }
    products.removeWhere((p) => productsToUpdate.any(
        (updatedProduct) => updatedProduct.catalogNumber == p.catalogNumber));
  }

  void removeUploadedProducts(List<Product> productsJson) {
    for (var product in productsJson) {
      if (product.listingId != null) {
        readyForPublishList
            .removeWhere((p) => p.catalogNumber == product.catalogNumber);
      }
    }
  }

  void setActiveListings(List<Listing> listingList) {
    activeProductList = listingList.map((listing) {
      return Product.fromListing(listing);
    }).toList();
  }

  List<FirebaseItem> getListToDeleteFromFirebase() {
    List<FirebaseItem> deleteList = [];
    Map<String, String> olxIds = {};

    if (activeProductList.isEmpty || firebaseUploadedListings.isEmpty) {
      return [];
    }

    for (var product in activeProductList) {
      if (product.listingId != null) {
        olxIds[product.listingId!] = product.listingId!;
      }
    }

    firebaseUploadedListings.forEach((key, value) {
      if (!olxIds.containsKey(value.listingId)) {
        deleteList.add(value);
      }
    });

    return deleteList;
  }

  List<String> checkDuplicatesActiveProductList() {
    Map<String, String> duplicates = {};
    Map<String, String> names = {};

    for (var product in activeProductList) {
      if (names.containsKey(product.name)) {
        duplicates[product.name] = product.listingId!;
        print(
            'product.name: ${product.name} product.listingId: ${product.listingId}');
      } else {
        names[product.name] = product.listingId!;
      }
    }

    return duplicates.values.toList();
  }
}
