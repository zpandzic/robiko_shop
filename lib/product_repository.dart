import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/product.model.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();

  factory ProductRepository() => _instance;

  ProductRepository._internal();

  List<Product> products = [];
  List<Product> readyForPublishList = [];
  List<Product> activeProductList = [];

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
}
