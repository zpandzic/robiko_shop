import 'package:robiko_shop/model/product.model.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  List<Product> products = [];
}
