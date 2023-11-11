import 'package:flutter/material.dart';
import 'package:robiko_shop/model/product.model.dart';

class ProductWidget extends StatelessWidget {
  const ProductWidget({
    super.key,
    required this.product,
    required this.onDelete,
    required this.onEdit,
  });

  final Product product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox(
            width: 100,
            height: 100,
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Šifra: ${product.code}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Prikazivanje dijaloga za potvrdu
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              // title: const Text('Potvrda Brisanja'),
                              content: const Text(
                                  'Jeste li sigurni da želite obrisati ovaj proizvod?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Odustani'),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Zatvara dijalog bez obavljanja akcije
                                  },
                                ),
                                TextButton(
                                  child: const Text('Obriši'),
                                  onPressed: () {
                                    onDelete();
                                    Navigator.of(context)
                                        .pop(); // Zatvara dijalog nakon obavljanja akcije
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
