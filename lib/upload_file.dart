import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/model/nuic_csv.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/model/visokaZaliheData.model.dart';
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
  bool testing = false;

  void pickCsvFile() async {
    if (testing) {
      const filePath =
          '/data/user/0/com.example.robiko_shop/cache/file_picker/ak2-finalno.csv';
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
      if (kDebugMode) {
        print(filePath);
      }
      setState(() {
        selectedFile = File(filePath);
      });
    } else {
      if (kDebugMode) {
        print('No file selected');
      }
    }
  }

  void loadCsvFile() async {
    if (selectedFile != null) {
      final input = selectedFile!.openRead();
      int rowCount = 0;
      const int maxRowsForTesting = 2 + 5; // Number of rows to read for testing

      List<List<dynamic>> rows = [];

      Stream<List> csvStream = input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ';'));

      await for (List<dynamic> row in csvStream) {
        rows.add(row);
        rowCount++;
        // if (rowCount >= maxRowsForTesting) break;
      }

      mapRows(rows);
    } else {
      if (kDebugMode) {
        print('Please select a file first.');
      }
    }
  }

  void mapRows(List<List> rows) {
    if (rows.isEmpty) return;

    switch (dropdownValue) {
      case 'VisokaZalihe':
        List<dynamic> headerRow = rows[1];

        // Create a map for column indexes
        Map<String, int> columnIndexes = {};
        for (int i = 0; i < headerRow.length; i++) {
          columnIndexes[headerRow[i].toString()] = i;
        }

        List<VisokaZalihe> dataObjects = rows.skip(2).map((row) {
          return VisokaZalihe.fromCsvRow(row, columnIndexes);
        }).toList();

        ProductRepository().products =
            Product.fromVisokaZaliheList(dataObjects);

        ProductRepository().printFormattedJson();
        break;

      case 'NUIĆ':
        // Assuming header row is the first row of the CSV
        List<dynamic> headerRow = rows[0];
        Map<String, int> columnIndexes = {};
        for (int i = 0; i < headerRow.length; i++) {
          columnIndexes[headerRow[i].toString()] = i;
        }

        List<NuicCsv> dataObjects = rows.skip(1).map((row) {
          // Assuming the first row is the header
          return NuicCsv.fromCsvRow(row, columnIndexes);
        }).toList();

        ProductRepository().products = Product.fromNuicList(dataObjects);

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
            child: const Text('Učitaj CSV'),
          ),
        ],
      ),
    );
  }
}
