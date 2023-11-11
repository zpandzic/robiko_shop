import 'package:flutter/material.dart';
import 'package:robiko_shop/model/product.model.dart';

import 'package:robiko_shop/Widgets/product_widget.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  ProductsScreenState createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = List.generate(
    10,
    (index) => Product(
      imageUrl: 'https://via.placeholder.com/150',
      name: 'Naziv proizvoda $index',
      code: '3211312',
      catalogNumber: '123123123',
      price: 99.99,
      description: 'Opis proizvoda',
      category: 'Kategorija',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductWidget(
        product: products[index],
        onDelete: () {
          _deleteProduct(index);
        },
        onEdit: () {
          _showEditDialog(products[index], index);
        },
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 8.0),
    );
  }

  void _deleteProduct(int index) {
    setState(() {
      products.removeAt(index);
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Naziv proizvoda'),
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
}
