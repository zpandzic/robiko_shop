import 'package:flutter/material.dart';
import 'package:robiko_shop/model/product.model.dart';

class ProductWidget extends StatelessWidget {
  const ProductWidget({
    Key? key,
    required this.product,
    required this.onDelete,
    required this.onEdit,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  final Product product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min, // Important to avoid layout errors
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                onSelected();
              },
            ),
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(8.0),
            //   child: Image.network(
            //     product.imageUrl,
            //     width: 50, // Adjust the size as needed
            //     height: 50,
            //     fit: BoxFit.cover,
            //   ),
            // ),
          ],
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategorija: ${product.category}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Kat broj: ${product.catalogNumber}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Cijena: ${product.price.toStringAsFixed(2)} KM',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Šifра: ${product.code}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Dialog for delete confirmation
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: const Text(
                                  'Jeste li sigurni da želite obrisati ovaj proizvod?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Odustani'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Obriši'),
                                  onPressed: () {
                                    onDelete();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
