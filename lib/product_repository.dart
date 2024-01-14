import 'dart:convert';

import 'package:robiko_shop/model/product.model.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  List<Product> products = [];

  void printFormattedJson() {
    JsonEncoder encoder = JsonEncoder.withIndent('  '); // Two-space indentation
    String prettyPrint =
        encoder.convert(products.map((e) => e.toJson()).toList());
    print(prettyPrint);
  }
}
