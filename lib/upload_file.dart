import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/model/visokaZaliheData.model.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/product_repository.dart';

const List<String> list = <String>[
  'VisokaZalihe',
  'NUIĆ',
];

class UploadFile extends StatefulWidget {
  const UploadFile({super.key});

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile> {
  String? dropdownValue = list[0];
  File? selectedFile;
  bool testing = true;

  void pickCsvFile() async {
    if (testing) {
      const filePath =
          '/data/user/0/com.example.robiko_shop/cache/file_picker/test_excel.csv';
      setState(() {
        selectedFile = File(filePath);
      });
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final filePath = result.files.single.path!;
      print(filePath);
      setState(() {
        selectedFile = File(filePath);
      });
    } else {
      print('No file selected');
    }
  }

  void loadCsvFile() async {
    if (selectedFile != null) {
      // Your logic to read and process the CSV file goes here
      final input = selectedFile!.openRead();
      List<List> rows = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ';'))
          .toList();

      mapRows(rows);
    } else {
      print('Please select a file first.');
    }
  }

  void mapRows(List<List> rows) {
    switch (dropdownValue) {
      case 'VisokaZalihe':
        // Skip the first two rows (header rows) and map each row to an Ak2Data object
        List<VisokaZalihe> dataObjects = rows.skip(2).map((row) {
          return VisokaZalihe.fromCsvRow(row);
        }).toList();

        ProductRepository().products =
            Product.fromVisokaZaliheList(dataObjects);

        break;

      case 'NUIĆ':
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: dropdownValue,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? value) {
              setState(() {
                dropdownValue = value;
                selectedFile = null;
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
            onPressed: dropdownValue != null ? pickCsvFile : null,
            child: const Text('Odaberi CSV'),
          ),
          ElevatedButton(
            onPressed: selectedFile != null ? loadCsvFile : null,
            child: const Text('Učitaj'),
          ),
          ElevatedButton(
            onPressed: fetchUserListings,
            child: const Text('Listings'),
          ),
        ],
      ),
    );
  }
}

Future<List<Listing>> fetchUserListings() async {
  // var url = Uri.parse('https://api.olx.ba/users/RobikoShop/listings');
  List<Listing> listings = [];
  int currentPage = 1;
  bool hasMore = true;

  while (hasMore) {
    var url = Uri.parse(
        'https://api.olx.ba/users/RobikoShop/listings?page=$currentPage');

    try {
      var response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer 6992342|MZKjrtskpHnlW71Xc9pbtibtpuFrcIuNX7G3uLlh',
      });

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['data'] != null) {
          for (var item in data['data']) {
            Listing listing = Listing.fromJson(item);
            listings.add(listing);
            print(listing); // Print each listing object
          }
        }
        // return listings;
        if (data['meta']['last_page'] == currentPage) {
          hasMore = false;
        }
        currentPage++;
      } else {
        // Handle the case where the server does not return a 200 OK response
        print('Failed to load listings. Status code: ${response.statusCode}');
        hasMore = false;
        return [];
      }
    } catch (e) {
      // Handle any errors that occur during the request
      print('Error: $e');
      hasMore = false;
      return [];
    }
  }
  return listings;
}
