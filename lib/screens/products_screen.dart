import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/Widgets/products_list_widget.dart';
import 'package:robiko_shop/attribute_helper.dart';
import 'package:robiko_shop/dialog_service.dart';
import 'package:robiko_shop/dialogs/upload_progress_dialog.dart';
import 'package:robiko_shop/model/attribute_value.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/product_repository.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  final NetworkService networkService = NetworkService();
  final AttributeHelper attributeHelper = AttributeHelper();
  final DialogService dialogService = DialogService();
  late final TabController _tabController;
  Map<int, String> attributeValues = {};
  Map<String, bool> selectedProductsReadyForUpload = {};
  late int? selectedCategoryId;
  late String? selectedCategoryName;
  late List<AttributeValue>? attributesList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void refreshState() {
    setState(() {});
  }

  Future<void> objavi(BuildContext context,
      Map<String, bool> selectedProductsReadyForUpload) async {
    List<Product> productsJson = ProductRepository()
        .readyForPublishList
        .where((element) =>
            selectedProductsReadyForUpload[element.catalogNumber] == true)
        .toList();
    // .map((product) => product.toJson())
    // .toList();

    if (productsJson.isEmpty) {
      //show message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Niste odabrali proizvode za objavu'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      await uploadListings(productsJson, context);
      ProductRepository()
          .removeUploadedProducts(productsJson);
    } catch (e) {
      print(e);
    }

    if (kDebugMode) {
      print(jsonEncode(productsJson));
    }
  }

  void printFormattedJson(Map<String, dynamic> jsonData) {
    JsonEncoder encoder =
        const JsonEncoder.withIndent('  '); // Two-space indentation
    String prettyPrint = encoder.convert(jsonData);
    if (kDebugMode) {
      print(prettyPrint);
    }
  }

  Future<void> uploadListings(
      List<Product> products, BuildContext context) async {
    void Function(int, bool)? updateProgress;
    bool isUploadCancelled = false;
    bool isUploadInProgress = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UploadProgressDialog(
          totalProducts: products.length,
          onUploadProgress: (update) {
            updateProgress = update;
          },
          onCancel: (callback) {
            if (isUploadInProgress == false) {
              Navigator.of(context).pop();
              return;
            }

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Prekid'),
                  content: const Text(
                      'Da li ste sigurni da želite prekinuti upload?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Ne'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        callback();
                        isUploadCancelled = true;
                      },
                      child: const Text('Da'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    int currentIndex = 0;
    for (var product in products) {
      currentIndex++;

      if (isUploadCancelled == true) {
        break;
      }

      try {
        String listingId = await networkService.uploadListing(
            product.toListing(), product.catalogNumber);

        await Future.delayed(const Duration(milliseconds: 100));

        if (updateProgress != null) {
          updateProgress!(currentIndex, true);
        }
        product.listingId = listingId;
      } catch (e) {
        if (updateProgress != null) {
          updateProgress!(currentIndex, false);
        }
      }
    }

    isUploadInProgress = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            tabs: <Widget>[
              Tab(
                  text:
                      'Neobjavljeno (${ProductRepository().products.length})'),
              Tab(
                  text:
                      'Za objavu (${ProductRepository().readyForPublishList.length})'),
              Tab(
                  text:
                      'Aktivni (${ProductRepository().activeProductList.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                ProductsListWidget(
                  productList: ProductRepository().products,
                  refreshState: refreshState,

                  // showActionSheet: _showActionSheet,
                ),
                ProductsListWidget(
                  productList: ProductRepository().readyForPublishList,
                  refreshState: refreshState,
                  objavi: objavi,
                  // showActionSheet: _showActionSheet,
                ),
                ProductsListWidget(
                  productList: ProductRepository().activeProductList,
                  refreshState: refreshState,
                  // showActionSheet: _showActionSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
