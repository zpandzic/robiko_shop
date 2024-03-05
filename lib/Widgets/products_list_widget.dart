import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/Widgets/product_widget.dart';
import 'package:robiko_shop/attribute_helper.dart';
import 'package:robiko_shop/dialogs/upload_progress_dialog.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/services/dialog_service.dart';

class ProductsListWidget extends StatefulWidget {
  final List<Product> productList;

  // final void Function() showActionSheet;
  final void Function(Map<String, bool>)? objavi;
  final void Function() refreshState;
  final bool? aktivni;
  final bool? obrisi;
  final bool? postaviKategoriju;

  const ProductsListWidget({
    required this.productList,
    this.objavi,
    required this.refreshState,
    this.aktivni,
    this.obrisi,
    this.postaviKategoriju,
    Key? key,
  }) : super(key: key);

  @override
  ProductsListWidgetState createState() => ProductsListWidgetState();
}

class ProductsListWidgetState extends State<ProductsListWidget> {
  final NetworkService networkService = NetworkService();
  final AttributeHelper attributeHelper = AttributeHelper();
  final DialogService dialogService = DialogService();

  TextEditingController searchController = TextEditingController();
  Map<int, String> attributeValues = {};
  late List<Product> filteredProducts = [];

  Map<String, bool> selectedProducts = {};

  late int? selectedCategoryId;
  late String? selectedCategoryName;

  // late List<AttributeValue>? attributesList;

  String getID(Product product) {
    return widget.aktivni == true
        ? product.listingId.toString()
        : product.catalogNumber;
  }

  @override
  void initState() {
    super.initState();
    filteredProducts = widget.productList;
    searchController.addListener(_filterProducts);

    for (var product in widget.productList) {
      selectedProducts[getID(product)] = false;
    }
  }

  void resetState() {
    setState(() {
      filteredProducts = widget.productList;
      searchController.clear();
      selectedProducts.clear();
      for (var product in widget.productList) {
        selectedProducts[getID(product)] = false;
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = widget.productList.where((product) {
        return product.name
                .toLowerCase()
                .contains(searchController.text.toLowerCase()) ||
            product.catalogNumber
                .toLowerCase()
                .contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  void _selectAllProducts() {
    setState(() {
      bool areAllSelected = filteredProducts.every(
        (product) => selectedProducts[getID(product)] ?? false,
      );

      for (var product in filteredProducts) {
        selectedProducts[getID(product)] = !areAllSelected;
      }
    });
  }

  void _deleteProduct(product) {
    setState(() {
      selectedProducts.remove(getID(product));
      widget.productList.remove(product);
      widget.refreshState();
    });
  }

  void _toggleProductSelection(String id) {
    setState(() {
      selectedProducts[id] = !(selectedProducts[id] ?? false);
    });
  }

  void _setCategoryForSelectedProducts() {
    dialogService.showSetCategoryDialog(
      context,
      (selectedCategoryId, selectedCategoryName, attributes) {
        dialogService.showAttributesDialog(
          context,
          attributes,
          {},
          (selectedAttributes) {
            setState(() {
              List<Product> productsToUpdate = filteredProducts
                  .where((element) => selectedProducts[getID(element)] == true)
                  .toList();

              for (var product in productsToUpdate) {
                product.category = selectedCategoryName;
                product.categoryId = selectedCategoryId;
                product.attributesList = selectedAttributes;
              }

              Navigator.of(context).pop();
              ProductRepository().moveProductsToReadyForPublishList(
                productsToUpdate,
              );
              widget.refreshState();
            });
          },
        );
      },
    );
  }

  void _deleteSelectedProducts() {
    setState(() {
      widget.productList
          .removeWhere((product) => selectedProducts[getID(product)] ?? false);
      selectedProducts.clear();

      for (var product in widget.productList) {
        selectedProducts[getID(product)] = false;
      }

      widget.refreshState();
    });
  }

  Future<void> reloadUserListings() async {
    await ProductRepository().refreshUserListings();

    widget.refreshState();
    resetState();
  }

  Future<void> checkLimitsAndRefreshProducts() async {
    bool isRefreshCancelled = false;
    bool isRefreshInProgress = true;
    int currentIndex = 0;

    List<Product> productsToRefresh = [];
    selectedProducts.forEach((id, isSelected) {
      if (isSelected) {
        // Pronađi proizvod po ID-u i dodaj ga u listu za osvježavanje
        var product =
            widget.productList.firstWhere((product) => getID(product) == id);
        productsToRefresh.add(product);
      }
    });

    int totalProducts = productsToRefresh.length;

    int successfulRefreshes = 0;
    int failedRefreshes = 0;

    void Function(int, bool)? updateProgress;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UploadProgressDialog(
          totalProducts: totalProducts,
          onUploadProgress: (update) {
            updateProgress = update;
          },
          onCancel: (callback) {
            if (!isRefreshInProgress) {
              Navigator.of(context).pop();
              return;
            }
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Prekid'),
                  content: const Text(
                      'Jeste li sigurni da želite prekinuti osvježavanje?'),
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
                        isRefreshCancelled = true;
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

    for (var product in productsToRefresh) {
      currentIndex++;
      if (isRefreshCancelled) break;

      try {
        // Logika za osvježavanje proizvoda
        await networkService.refreshListing(product.listingId!);
        successfulRefreshes++;
        updateProgress?.call(currentIndex, true);
      } catch (e) {
        failedRefreshes++;
        updateProgress?.call(currentIndex, false);
        if (kDebugMode) {
          print("Greška pri osvježavanju proizvoda: $e");
        }
      }
    }

    isRefreshInProgress = false;

    if (!isRefreshCancelled) {
      Navigator.of(context).pop(); // Zatvara UploadProgressDialog
      // Opcionalno: prikaži sažetak operacije
    }
  }

  // Future<void> checkLimitsAndRefreshProducts() async {
  //   try {
  //     // Dohvaćanje limita
  //     Map<String, dynamic> limits = await networkService.fetchListingRefreshLimits();
  //     print("Limiti: $limits");
  //
  //     // Ovdje možete dodati logiku za provjeru da li su dostupni limiti za osvježavanje
  //     // Na primjer, provjerite da li je 'free_limit' veći od 0
  //     // Ova logika će ovisiti o strukturi odgovora API-ja i vašim specifičnim potrebama
  //
  //     // Ako su limiti dostupni, osvježite artikle
  //     for (var listingId in selectedProducts.keys) {
  //       if (selectedProducts[listingId] ?? false) {
  //         // Osvježite artikal
  //         String message = await networkService.refreshListing(listingId);
  //         print("Osvježavanje artikla $listingId: $message");
  //       }
  //     }
  //
  //     // Nakon osvježavanja, možda ćete htjeti ažurirati stanje UI-a ili dohvatiti ažurirane podatke
  //     setState(() {
  //       // Ažuriranje UI-a ili podataka ako je potrebno
  //     });
  //   } catch (error) {
  //     print("Došlo je do greške: $error");
  //   }
  // }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (widget.obrisi == true)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Obriši odabrane artikle'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteSelectedProducts();
                  },
                ),
              if (widget.postaviKategoriju == true)
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Postavi kategoriju za odabrane artikle'),
                  onTap: () {
                    Navigator.pop(context);
                    _setCategoryForSelectedProducts();
                  },
                ),
              widget.objavi != null
                  ? ListTile(
                      leading: const Icon(Icons.warning),
                      title: const Text('Objavi'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.objavi!(selectedProducts);
                      },
                    )
                  : const SizedBox(),
              if (widget.aktivni == true)
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Osvjezi odabrane artikle'),
                  onTap: () {
                    checkLimitsAndRefreshProducts();
                  },
                )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // widget.showActionSheet();
            _showActionSheet();
          },
          child: const Icon(Icons.settings), // Use an appropriate icon
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, bottom: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Background color
                  borderRadius: BorderRadius.circular(30.0), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey
                          .withOpacity(0.5), // Shadow color with opacity
                      spreadRadius: 2, // Spread radius
                      blurRadius: 4, // Blur radius
                      offset: const Offset(0, 2), // Changes position of shadow
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Pretraži',
                    suffixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: _selectAllProducts,
                    child: Text('Označi sve (${filteredProducts.length})'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                  onRefresh: widget.aktivni == true
                      ? reloadUserListings
                      : () async {
                          // widget.refreshState();
                        },
                  child: ListView.separated(
                    dragStartBehavior: DragStartBehavior.down,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductWidget(
                        product: product,
                        onDelete: () {
                          _deleteProduct(product);
                        },
                        onEdit: () {
                          dialogService.showEditDialog(
                            product,
                            index,
                            context,
                            (updatedProduct) {
                              updatedProduct();
                              widget.refreshState();
                            },
                          );
                        },
                        isSelected: selectedProducts[getID(product)] ?? false,
                        onSelected: () {
                          _toggleProductSelection(getID(product));
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8.0),
                  )),
            ),
          ],
        ));
  }
}
