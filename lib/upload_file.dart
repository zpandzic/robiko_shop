import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/network_service.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/services/csv_processing_service.dart';
import 'package:robiko_shop/services/dialog_service.dart';
import 'package:robiko_shop/services/firebase_service.dart';

const List<String> list = <String>[
  'VisokaZalihe',
  'NUIĆ',
];

class UploadFile extends StatefulWidget {
  const UploadFile({super.key});

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile>
    with AutomaticKeepAliveClientMixin<UploadFile> {
  bool testing = false;

  @override
  bool get wantKeepAlive => true;

//   Future<void> checkactiveimages() async {
//     // ProductRepository().activeProductList.forEach((element) {
//     //   if (element.imageUrl == null) {
//     //     ProductRepository().firebaseUploadedListings.forEach((key, value) {
//     //       if (element.listingId == value.listingId) {
//     //         data[element.listingId!] = value.slika!;
//     //
//     //
//     //       }
//     //     });
//     //   }
//     // });
//
//     var activeProducts = ProductRepository().activeProductList;
//     var uploadedListings = ProductRepository().firebaseUploadedListings;
//     var bezslike = activeProducts.where((product) => product.imageUrl == null);
//
//     print('bezslike: ${bezslike.length}');
//     var data = {};
//
//     var aimajusliku = [];
//     for (var product in bezslike) {
//       var prod = uploadedListings.values
//           .where((element) => element.listingId == product.listingId)
//           .firstOrNull;
//       if(prod?.listingId == '59341538'){
//         print(prod);
//       }
//
//       if (prod != null && prod.slika != null) {
//         // print(prod.listingId);
//
//         data[product.listingId] = prod.slika;
//       }
//       //     product.listingId
//       // : uploadedListings[product.listingId]!.slika
//     }
//
//     print('aimajusliku: ${aimajusliku.length}');
//
//     print(data.values.length);
//
//     // for (var i in data) {
//     //   print(i);
//     //   // NetworkService().addImage(id, '',)
//     // }
// //59340517, value: https://digital-assets.tecalliance.services/images/400/82c16fe6ab83791060c6d5376eca2d93ca45cba0.jpg
//
//     data.forEach((key, value) async {
//       print('key: $key, value: $value');
//       await NetworkService().addImage(key, '', value);
//     });
//   }

  void syncFunction() {
    var deleteList = ProductRepository().getListToDeleteFromFirebase();
    if (deleteList.isNotEmpty) {
      try {
        DialogService().showConfirmDialog(context, 'Potvrda brisanja',
            'Pronađen/o je ${deleteList.length} proizvoda koji su obrisani s OLX-a. Povrdite za brisanje za sinkroniziranje',
            () async {
          FirebaseService().deleteProducts(deleteList);
          DialogService().showLoadingDialog(context);

          await ProductRepository().initializeData();

          Navigator.of(context).pop();
        });
      } catch (error) {
        Navigator.of(context).pop();

        DialogService().showErrorDialog(context, error.toString());
      }
    }

    DialogService()
        .showSuccessDialog(context, 'Svi proizvodi su sinkronizirani', null);
  }

  void checkDuplicates() {
    var duplicates = ProductRepository().checkDuplicatesActiveProductList();
    if (duplicates.isNotEmpty) {
      DialogService().showConfirmDialog(
          context,
          'Pronađeno je ${duplicates.length} duplikata',
          'Želite li ih obrisati s OLX-a?', () async {
        try {
          NetworkService().deleteDuplicates(duplicates);
          DialogService().showLoadingDialog(context);
          await ProductRepository().initializeData();
          Navigator.of(context).pop();
        } catch (error) {
          Navigator.of(context).pop();
          DialogService().showErrorDialog(context, error.toString());
        }
        syncFunction();
      });
    } else {
      DialogService()
          .showSuccessDialog(context, 'Nema duplikata', () => syncFunction());
    }
  }

  void pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final filePath = result.files.single.path!;
      if (kDebugMode) {
        print(filePath);
      }
      setState(() {
        ProductRepository().selectedFile = File(filePath);
      });
    } else {
      if (kDebugMode) {
        print('No file selected');
      }
    }
  }

  void loadCsvFile() async {
    if (ProductRepository().selectedFile != null) {
      try {
        DialogService().showLoadingDialog(context);
        var products = await CsvProcessingService().processCsv(
            ProductRepository().selectedFile!,
            ProductRepository().dropdownValue!);

        await ProductRepository().setProducts(products);
        Navigator.of(context).pop();

        DialogService().showSuccessDialog(
            context, 'Uspješno učitano ${products.length} proizvod/a', null);
      } catch (error) {
        Navigator.of(context).pop();

        DialogService().showErrorDialog(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: ProductRepository().dropdownValue ?? list[0],
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? value) {
              setState(() {
                ProductRepository().dropdownValue = value;
                ProductRepository().selectedFile = null;
              });
            },
            items: list.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed:
                ProductRepository().dropdownValue != null ? pickCsvFile : null,
            child: const Text('Odaberi CSV'),
          ),
          ElevatedButton(
            onPressed:
                ProductRepository().selectedFile != null ? loadCsvFile : null,
            child: const Text('Učitaj CSV'),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: checkDuplicates,
            child: const Text('Sinkroniziraj proizvode'),
          ),
          // ElevatedButton(
          //   onPressed: checkactiveimages,
          //   child: const Text('provjeri slike aktivnih'),
          // ),
        ],
      ),
    );
  }
}
