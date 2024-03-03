import 'package:flutter/material.dart';
import 'package:robiko_shop/attribute_helper.dart';
import 'package:robiko_shop/model/attribute_value.dart';
import 'package:robiko_shop/model/category_attribute.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/product_repository.dart';

class DialogService {
  Future<void> showEditDialog(Product product, int index, BuildContext context,
      Function callBack) async {
    NetworkService networkService = NetworkService();

    TextEditingController nameController =
        TextEditingController(text: product.name);
    TextEditingController priceController =
        TextEditingController(text: product.price.toString());
    TextEditingController descriptionController =
        TextEditingController(text: product.description);

    List<CategoryAttribute> categoryAttributes = product.categoryId != null
        ? await networkService.fetchCategoryAttributes(product.categoryId!)
        : [];

    Map<int, String> attributeValues = {};
    for (var attributeValue in product.attributesList ?? []) {
      attributeValues[attributeValue.id] = attributeValue.value;
    }

    if (!context.mounted) return; // Exit if no longer mounted

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Uredi proizvod'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Naziv proizvoda'),
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Cijena (KM)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Opis'),
                  ),
                  TextFormField(
                    controller: TextEditingController(
                        text: product.category ?? "Nije odabrana kategorija"),
                    decoration: InputDecoration(
                      labelText: 'Kategorija',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: () {
                          showSetCategoryDialog(
                            context,
                            (int? categoryId, String? categoryName,
                                List<CategoryAttribute> attributes) {
                              setStateDialog(() {
                                product.categoryId = categoryId;
                                product.category = categoryName;
                                categoryAttributes = attributes;
                                Navigator.of(context).pop();
                              });
                            },
                          );
                        },
                      ),
                    ),
                    readOnly: true,
                  ),
                  categoryAttributes.isEmpty
                      ? const SizedBox()
                      : const Padding(
                          padding: EdgeInsets.only(top: 26.0, bottom: 8.0),
                          child: Row(
                            children: [
                              Text(
                                'Atributi kategorije',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ...categoryAttributes.map((attribute) {
                    return AttributeHelper().buildAttributeWidget(
                      attribute,
                      setStateDialog,
                      attributeValues,
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  if (product.categoryId == null) {
                    return;
                  }

                  var requiredAttributes = categoryAttributes
                      .where((attribute) => attribute.required ?? false)
                      .toList();

                  bool areAllRequiredFilled =
                      requiredAttributes.every((attribute) {
                    return attributeValues.containsKey(attribute.id) &&
                        attributeValues[attribute.id] != null;
                  });

                  if (areAllRequiredFilled) {
                    callBack(() {
                      Product currentProduct = product;

                      currentProduct.name = nameController.text;
                      currentProduct.description = descriptionController.text;
                      currentProduct.price =
                          double.tryParse(priceController.text) ??
                              currentProduct.price;
                      currentProduct.attributesList = attributeValues.entries
                          .map((entry) =>
                              AttributeValue(id: entry.key, value: entry.value))
                          .toList();

                      ProductRepository().moveProductsToReadyForPublishList(
                        [currentProduct],
                      );
                    });

                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> showSetCategoryDialog(
    BuildContext context,
    Function(
      int? categoryId,
      String? categoryName,
      List<CategoryAttribute> attributes,
    ) onCategorySelected,
  ) async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> searchCategories = [];
    NetworkService networkService = NetworkService();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Kategorije'),
              content: SizedBox(
                height: 300.0,
                width: 300.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Pretraži kategorije',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            var results = await networkService
                                .fetchCategories(searchController.text);
                            setStateDialog(() {
                              searchCategories = results;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchCategories.length,
                        itemBuilder: (context, index) {
                          var category = searchCategories[index];
                          return ListTile(
                            title:
                                Text(category['name'] + ' (${category['id']})'),
                            subtitle: Text(category['path']),
                            onTap: () async {
                              networkService
                                  .fetchCategoryAttributes(category['id'])
                                  .then((attributes) {
                                onCategorySelected(
                                  category['id'],
                                  category['name'],
                                  attributes,
                                );
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Odustani'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showAttributesDialog(
    BuildContext context,
    List<CategoryAttribute> attributes,
    Map<int, String> attributeValues,
    Function(List<AttributeValue>) onAttributesSelected,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Postavi polja'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: attributes.map((attribute) {
                    return AttributeHelper().buildAttributeWidget(
                      attribute,
                      setStateDialog,
                      attributeValues,
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Odustani'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Spremi'),
                  onPressed: () {
                    var requiredAttributes = attributes
                        .where((attribute) => attribute.required ?? false)
                        .toList();

                    bool areAllRequiredFilled =
                        requiredAttributes.every((attribute) {
                      return attributeValues.containsKey(attribute.id) &&
                          attributeValues[attribute.id] != null;
                    });

                    if (areAllRequiredFilled) {
                      List<AttributeValue> selectedAttributes = attributeValues
                          .entries
                          .map((entry) =>
                              AttributeValue(id: entry.key, value: entry.value))
                          .toList();

                      onAttributesSelected(selectedAttributes);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showWarningDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
