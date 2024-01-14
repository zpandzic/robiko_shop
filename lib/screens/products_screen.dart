import 'package:flutter/material.dart';
import 'package:robiko_shop/Widgets/product_widget.dart';
import 'package:robiko_shop/model/category_attribute.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:robiko_shop/upload_file.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late List<Product> products;
  late List<Product> filteredProducts;
  TextEditingController searchController = TextEditingController();
  Map<String, bool> selectedProducts = {};
  Map<int, String> attributeValues = {}; //kad se zatvori dialog vrati na {}

  late int? selectedCategoryId;
  late String? selectedCategotyName;
  late List<AttributeValue>? attributesList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    products = ProductRepository().products;
    filteredProducts = products;
    searchController.addListener(_filterProducts);
    for (var product in products) {
      selectedProducts[product.catalogNumber] = false;
    }
  }

  void _filterProducts() {
    String searchQuery = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return product.name.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  void _toggleProductSelection(String catalogNumber) {
    setState(() {
      selectedProducts[catalogNumber] =
          !(selectedProducts[catalogNumber] ?? false);
    });
  }

  void _deleteProduct(String catalogNumber) {
    setState(() {
      products.removeWhere((product) => product.catalogNumber == catalogNumber);
      selectedProducts.remove(catalogNumber);
    });
  }

  void _showEditDialog(Product product, int index) {
    TextEditingController nameController =
        TextEditingController(text: product.name);
    TextEditingController priceController =
        TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Uredi Proizvod'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Naziv proizvoda'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Cijena'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                // Dodajte ostale TextField widgete za uređivanje ostalih svojstava proizvoda
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
            TextButton(
              child: const Text('Sačuvaj'),
              onPressed: () {
                // Ažurirajte proizvod sa novim informacijama
                setState(() {
                  products[index] = Product(
                    imageUrl: product.imageUrl, // Zadržite isti URL
                    name: nameController.text,
                    code: product.code, // Zadržite isti kod
                    catalogNumber:
                        product.catalogNumber, // Zadržite isti kataloški broj
                    price: double.parse(priceController.text),
                    description: product.description, // Zadržite isti opis
                    category: product.category, // Zadržite istu kategoriju
                    categoryId: product.categoryId,
                    attributesList: product.attributesList,
                  );
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void objavi() {
    List<Product> productsJson = products
        .where((element) => selectedProducts[element.catalogNumber] == true)
        .toList();
    // .map((product) => product.toJson())
    // .toList();
    String jsonStr = jsonEncode(productsJson);

    uploadListings(productsJson);

    print(jsonStr);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
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
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('Objavi'),
                onTap: () {
                  Navigator.pop(context);
                  objavi();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteSelectedProducts() {
    // setState(() {
    //   products.removeWhere(
    //       (product) => selectedProducts[product.catalogNumber] ?? false);
    //   // Reset the selection state as well
    //   selectedProducts.clear();
    //   products.forEach((product) {
    //     selectedProducts[product.catalogNumber] = false;
    //   });
    // });
  }

  Future<List<dynamic>> fetchCategories(String query) async {
    var response = await http.get(
        Uri.parse('https://api.olx.ba/categories/find?name=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer 6992342|MZKjrtskpHnlW71Xc9pbtibtpuFrcIuNX7G3uLlh',
        });

    if (response.statusCode == 200) {
      print(json.decode(response.body));
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  void _setCategoryForSelectedProducts() async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> searchCategories = [];

    selectedCategoryId = null;
    selectedCategotyName = null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Uredi Proizvod'),
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
                            var results =
                                await fetchCategories(searchController.text);
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
                            onTap: () {
                              fetchCategoryAttributes(category['id'])
                                  .then((attributes) {
                                selectedCategoryId = category['id'];
                                selectedCategotyName = category['name'];
                                showAttributesDialog(context, attributes);
                              });
                              // _updateSelectedProductsCategory(
                              //     category['path'], category['id']);
                              // Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<CategoryAttribute>> fetchCategoryAttributes(
    int categoryId,
  ) async {
    final url =
        Uri.parse('https://api.olx.ba/categories/$categoryId/attributes');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['data'];

      return data.map((json) => CategoryAttribute.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load category attributes');
    }
  }

  void showAttributesDialog(
    BuildContext context,
    List<CategoryAttribute> attributes,
  ) {
    showDialog(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Set Attributes'),
            content: SingleChildScrollView(
              child: ListBody(
                children: attributes
                    .map((attribute) =>
                        _buildAttributeWidget(attribute, setStateDialog))
                    .toList(),
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
                  var requiredAttributes = attributes
                      .where((attribute) => attribute.required ?? false)
                      .toList();

                  bool areAllRequiredFilled =
                      requiredAttributes.every((attribute) {
                    return attributeValues.containsKey(attribute.id) &&
                        attributeValues[attribute.id] != null;
                  });

                  if (areAllRequiredFilled) {
                    attributesList = attributeValues.entries.map((entry) {
                      return AttributeValue(id: entry.key, value: entry.value);
                    }).toList();

                    _updateSelectedProductsCategory();

                    Navigator.of(context).pop();
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

  void _updateSelectedProductsCategory() {
    setState(() {
      for (var product in products) {
        if (selectedProducts[product.catalogNumber] == true) {
          product.category = selectedCategotyName;
          product.categoryId = selectedCategoryId;
          product.attributesList = attributesList;
        }
      }
    });
  }

  Widget _buildAttributeWidget(
      CategoryAttribute attribute, StateSetter setStateDialog) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: attribute.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black, // Change color if needed
              ),
              children: [
                if (attribute.required != false)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Red color for the asterisk
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          _getField(attribute, setStateDialog),
        ],
      ),
    );
  }

  Widget _getField(CategoryAttribute attribute, StateSetter setStateDialog) {
    switch (attribute.inputType) {
      case 'select':
        return _buildDropdown(attribute, setStateDialog);
      case 'text-range':
        return _buildTextField(attribute, setStateDialog);
      case 'checkbox':
        return _buildCheckbox(attribute, setStateDialog);
      default:
        return Container();
    }
  }

  Widget _buildDropdown(
      CategoryAttribute attribute, StateSetter setStateDialog) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      value: attributeValues[attribute.id],
      // onChanged: (String? newValue) {
      //   setState(() {
      //     selectedValue = newValue;
      //   });
      // },
      onChanged: (String? newValue) {
        if (newValue != null) {
          setStateDialog(() {
            attributeValues[attribute.id] = newValue;
          });
        }
      },
      items: attribute.options?.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
      CategoryAttribute attribute, StateSetter setStateDialog) {
    return TextFormField(
      onChanged: (String? newValue) {
        if (newValue != null) {
          setStateDialog(() {
            attributeValues[attribute.id] = newValue;
          });
        }
      },
      decoration: const InputDecoration(
        // labelText: attribute.displayName,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCheckbox(
      CategoryAttribute attribute, StateSetter setStateDialog) {
    return CheckboxListTile(
      title: Text(attribute.displayName ?? ''),
      value: attributeValues[attribute.id] == 'true' ? true : false,
      onChanged: (bool? newValue) {
        if (newValue != null) {
          setStateDialog(() {
            attributeValues[attribute.id] = newValue.toString();
          });
        }
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void printProductsAsJson() {
    List<Map<String, dynamic>> productsJson =
        products.map((product) => product.toJson()).toList();
    String jsonStr = jsonEncode(productsJson);
    print(jsonStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActionSheet();
        },
        child: const Icon(Icons.settings), // Use an appropriate icon
      ),
      body: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            tabs: const <Widget>[
              Tab(text: 'Neobjavljeno'),
              Tab(text: 'Objavljeno'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          borderRadius:
                              BorderRadius.circular(30.0), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                  0.5), // Shadow color with opacity
                              spreadRadius: 2, // Spread radius
                              blurRadius: 4, // Blur radius
                              offset:
                                  const Offset(0, 2), // Changes position of shadow
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
                                _showEditDialog(product, index);
                              },
                              isSelected:
                                  selectedProducts[product.catalogNumber] ??
                                      false,
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
                ),
                Card(
                  child: Center(
                    child: TextButton(
                      child: const Text('sta ima'),
                      onPressed: () {
                        for (var product in products) {
                          print(product.toJson());
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttributeValue {
  final int id;
  String value;

  AttributeValue({required this.id, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}
