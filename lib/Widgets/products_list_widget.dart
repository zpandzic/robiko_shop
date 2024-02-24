import 'package:flutter/material.dart';
import 'package:robiko_shop/Widgets/product_widget.dart';
import 'package:robiko_shop/attribute_helper.dart';
import 'package:robiko_shop/dialog_service.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/product_repository.dart';

class ProductsListWidget extends StatefulWidget {
  final List<Product> productList;

  // final void Function() showActionSheet;
  final void Function(BuildContext, Map<String, bool>)? objavi;
  final void Function() refreshState;

  const ProductsListWidget({
    required this.productList,
    this.objavi,
    required this.refreshState,
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

  @override
  void initState() {
    super.initState();
    filteredProducts = widget.productList;
    searchController.addListener(_filterProducts);
    for (var product in widget.productList) {
      selectedProducts[product.catalogNumber] = false;
    }
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
            .contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  void _selectAllProducts() {
    setState(() {
      bool areAllSelected = filteredProducts.every(
        (product) => selectedProducts[product.catalogNumber] ?? false,
      );

      for (var product in filteredProducts) {
        selectedProducts[product.catalogNumber] = !areAllSelected;
      }
    });
  }

  void _deleteProduct(String catalogNumber) {
    // setState(() {
    //   ProductRepository().deleteProduct(catalogNumber);
    // });
  }

  void _toggleProductSelection(String catalogNumber) {
    setState(() {
      selectedProducts[catalogNumber] =
          !(selectedProducts[catalogNumber] ?? false);
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
                  .where((element) =>
                      selectedProducts[element.catalogNumber] == true)
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
      widget.productList.removeWhere(
          (product) => selectedProducts[product.catalogNumber] ?? false);
      selectedProducts.clear();

      for (var product in widget.productList) {
        selectedProducts[product.catalogNumber] = false;
      }

      widget.refreshState();
    });
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Obriši odabrane artikle'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteSelectedProducts();
                },
              ),
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
                        widget.objavi!(context, selectedProducts);
                      },
                    )
                  : const SizedBox(),
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
                    labelText: 'Pretraži po nazivu',
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
                children: <Widget>[
                  TextButton(
                    onPressed: _selectAllProducts,
                    child: const Text('Označi sve'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Card(
                child: ListView.separated(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductWidget(
                      product: product,
                      onDelete: () {
                        _deleteProduct(product.catalogNumber);
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
                      isSelected:
                          selectedProducts[product.catalogNumber] ?? false,
                      onSelected: () {
                        _toggleProductSelection(product.catalogNumber);
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8.0),
                ),
              ),
            ),
          ],
        ));
  }
}
