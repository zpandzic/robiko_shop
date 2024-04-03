import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:robiko_shop/Widgets/products_list_widget.dart';
import 'package:robiko_shop/dialogs/upload_progress_dialog.dart';
import 'package:robiko_shop/exceptions/hourly_limit_exceeded_exception.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/services/dialog_service.dart';
import 'package:robiko_shop/services/firebase_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // final service = FlutterBackgroundService();
  // final StreamController<Map<String, dynamic>> _publishingStreamController =
  //     StreamController.broadcast();

  int totalProducts = 0;
  int successfulUploads = 0;
  int failedUploads = 0;
  String? nextPublishTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void refreshState() {
    setState(() {});
  }

  Future<void> objavi(Map<String, bool> selectedProductsReadyForUpload) async {
    print('Objavljivanje pokrenuto');
    List<Product> productsJson = ProductRepository()
        .readyForPublishList
        .where((element) =>
            selectedProductsReadyForUpload[element.catalogNumber] == true)
        .toList();

    if (productsJson.isEmpty) {
      DialogService()
          .showErrorDialog(context, 'Niste odabrali proizvode za objavu');
      return;
    }

    try {
      print('Ukupno proizvoda za objavu: ${productsJson.length}');

      var successfulUploads = await uploadListings(productsJson);

      // await ProductRepository().refreshUserListings();

      // if (mounted) Navigator.of(context).pop();

      print(jsonEncode(successfulUploads));
    } catch (e) {
      print('Greška prilikom objavljivanja proizvoda: $e');
      if (mounted) {
        DialogService().showWarningDialog(
          context,
          'Greška',
          e.toString(),
        );
      }
    }
  }

  Future<List<Product>> uploadListings(List<Product> products) async {
    bool isUploadCancelled = false;
    bool isUploadInProgress = true;

    List<Product> successfulUploads = [];
    List<Product> batchSuccessfulUploads = [];
    int minutesToWait = 15;

    int numberOfSuccessfulUploads = 0;
    failedUploads = 0;
    totalProducts = products.length;
    void Function(int, int, int, String?)? updateProgress;
    bool limitReached = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UploadProgressDialog(
          onUploadProgress: (update) {
            updateProgress = update;
          },
          onCancel: () {
            if (isUploadInProgress == false) {
              Navigator.of(context).pop();
              return;
            }

            DialogService().showConfirmDialog(context, 'Prekid',
                'Jeste li ste sigurni da želite prekinuti učitavanje?', () {
              Navigator.of(context).pop();
              isUploadCancelled = true;
            });
          },
        );
      },
    );

    bool lastIndexSuccessful = true;
    for (int currentIndex = 0; currentIndex < products.length; currentIndex++) {
      if (isUploadCancelled == true) {
        print('Upload cancelled');
        break;
      }

      Product product = products[currentIndex];
      limitReached = false;

      try {
        String listingId = await NetworkService()
            .uploadListing(product.toListing(), product.catalogNumber);

        product.listingId = listingId;
        // if (currentIndex > 0 &&
        //     currentIndex % 30 == 0 &&
        //     lastIndexSuccessful == true) {
        //   //remove
        //   throw Exception('Greška');
        // }
        // lastIndexSuccessful = true; //remove
        // await Future.delayed(const Duration(milliseconds: 300)); //remove

        successfulUploads.add(product);
        batchSuccessfulUploads.add(product);

        if (batchSuccessfulUploads.length == 20) {
          print('Spremanje batcha od 20 proizvoda');
          await FirebaseService().addProducts(
              batchSuccessfulUploads); // provjerit jel lokalno ostane listing id prazan ili se popuni
          batchSuccessfulUploads.clear();
          print('Batch spremljen');
        }

        ProductRepository().removeUploadedProducts([product]);

        setState(() {
          numberOfSuccessfulUploads = successfulUploads.length;
          // numberOfSuccessfulUploads++; //maknit
        });
      } on HourlyLimitExceededException catch (e) {
        print('Dosegnut limit objava: ${e.toString()}');
        limitReached = true;
        lastIndexSuccessful = false;
        currentIndex--;
      } catch (e) {
        print(
          'Greška prilikom objavljivanja proizvoda: $e, proizvod: ${product.toJson()}',
        );

        setState(() {
          failedUploads++;
        });
      }

      if (limitReached == true) {
        var time = DateTime.now().add(Duration(minutes: minutesToWait));
        nextPublishTime =
            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
        print('Objavljivanje zaustavljeno do $nextPublishTime');
      } else {
        nextPublishTime = null;
      }

      if (updateProgress != null) {
        updateProgress!(
          numberOfSuccessfulUploads,
          failedUploads,
          totalProducts,
          nextPublishTime,
        );
      }

      if (limitReached) {
        if (batchSuccessfulUploads.isNotEmpty) {
          print(
              'Spremanje batcha prije pauziranja, broj proizvoda: ${batchSuccessfulUploads.length}');
          await FirebaseService().addProducts(batchSuccessfulUploads);
          batchSuccessfulUploads.clear();
          print('Batch spremljen');
        }

        //zelim spremit podatke prije ovog
        print('[[Pauziranje]]');
        for (int i = 0; i < 1 * 60 * minutesToWait; i++) {
          await Future.delayed(
            const Duration(seconds: 1),
          );
          if (isUploadCancelled == true) break;
        }

        print('[[Nastavljanje]]');
        //sto ako se tu lupi prekid?
        limitReached = false;
      }
    }

    if (batchSuccessfulUploads.isNotEmpty) {
      print(
          'Spremanje batcha prije zavrsetka objavljivanja, broj proizvoda: ${batchSuccessfulUploads.length}');
      await FirebaseService().addProducts(batchSuccessfulUploads);
      batchSuccessfulUploads.clear();
      print('Batch spremljen');
    }

    isUploadInProgress = false;
    print('Upload finished');

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
