import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/Widgets/products_list_widget.dart';
import 'package:robiko_shop/dialogs/upload_progress_dialog.dart';
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
  late final TabController _tabController;

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
      var successfulUploads = await uploadListings(productsJson, context);
      ProductRepository().removeUploadedProducts(successfulUploads);
      ProductRepository()
          .refreshUserListings()
          .then((value) => setState(() {}));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
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

  Future<List<Product>> uploadListings(
      List<Product> products, BuildContext context) async {
    void Function(int, bool)? updateProgress;
    bool isUploadCancelled = false;
    bool isUploadInProgress = true;

    List<Product> successfulUploads = [];

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
                      'Jeste li ste sigurni da želite prekinuti učitavanje?'),
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
        String listingId = await NetworkService()
            .uploadListing(product.toListing(), product.catalogNumber);

        // await Future.delayed(const Duration(milliseconds: 100));

        if (updateProgress != null) {
          updateProgress!(currentIndex, true);
        }
        product.listingId = listingId;
        successfulUploads.add(product);
      } catch (e) {
        if (updateProgress != null) {
          updateProgress!(currentIndex, false);
        }
      }
    }

    if (successfulUploads.isNotEmpty) {
          await NetworkService().modifyAndUploadJson(successfulUploads);
    }

    isUploadInProgress = false;

    return successfulUploads;
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
                text: 'Uvezeno (${ProductRepository().products.length})',
              ),
              Tab(
                text:
                    'Za objavu (${ProductRepository().readyForPublishList.length})',
              ),
              Tab(
                text:
                    'Aktivni (${ProductRepository().activeProductList.length})',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                ProductsListWidget(
                  productList: ProductRepository().products,
                  refreshState: refreshState,
                  obrisi: true,
                  postaviKategoriju: true,

                  // showActionSheet: _showActionSheet,
                ),
                ProductsListWidget(
                  productList: ProductRepository().readyForPublishList,
                  refreshState: refreshState,
                  objavi: objavi,
                  obrisi: true,
                  postaviKategoriju: true,
                  // showActionSheet: _showActionSheet,
                ),
                ProductsListWidget(
                  productList: ProductRepository().activeProductList,
                  refreshState: refreshState,
                  aktivni: true,

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
