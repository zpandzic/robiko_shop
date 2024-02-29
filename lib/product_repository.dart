import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:robiko_shop/model/json_saved_article.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();

  factory ProductRepository() => _instance;

  ProductRepository._internal();

  List<Product> products = [];
  List<Product> readyForPublishList = [];
  List<Product> activeProductList = [];
  Map<String, JsonSavedArticle> jsonSavedArticles = {};

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
    if (kDebugMode) {
      print(prettyPrint);
    }
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

  Future<void> initializeData() async {
    await refreshJson();
    await refreshUserListings();
  }

  //refresh json

  Future<void> refreshJson() async {
    jsonSavedArticles = await NetworkService().getKatbrojId();
  }


  Future<bool> refreshUserListings() async {
    try {
      var result = await NetworkService().fetchUserListings();
      List<Listing> listings = result['listings'];
      Map<String, bool> listingIds = result['listingIds'];
      activeProductList = listings.map((listing) {
        return Product.fromListing(listing);
      }).toList();
      await syncListings(listingIds);
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
      return false;
    }
  }

  Future<void> syncListings(Map<String, bool> listingIds) async {
    List<String> deleteList = [];

    jsonSavedArticles.forEach((key, value) {
      if (!listingIds.containsKey(value.listingId)) {
        deleteList.add(key);
      }
    });

    if (kDebugMode) {
      print('Delete list from JSON - not synced: $deleteList');
    }

    if (deleteList.isNotEmpty) {
      await NetworkService().deleteListingsFromJson(deleteList);
    }
  }
}
