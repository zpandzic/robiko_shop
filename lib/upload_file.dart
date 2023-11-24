import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

class UploadFile extends StatelessWidget {
  const UploadFile({
    super.key,
  });

  // Function to pick and read CSV file
  void pickAndReadCsv() async {
    // Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      // Read the CSV file
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      // Print the contents of the CSV file
      for (final row in fields) {
        print(row.join(', ')); // Join each cell's content with a comma
      }
    } else {
      // User canceled the picker
      print('No file selected');
    }
  }

  // Function to read CSV file directly from a path
  void readCsvFromAssets() async {
    try {
      // Load the CSV file from assets
      final csvData = await rootBundle.loadString('assets/csv/test_excel.csv');

      // Convert the CSV data to a List, specifying ';' as the delimiter
      List<List<dynamic>> rows =
          const CsvToListConverter(eol: '\n', fieldDelimiter: ';')
              .convert(csvData);

      // Extract the keys from the second row
      List<String> keys = rows[1].cast<String>();

      // Create a list of maps, where each map represents a row with keys from the second row
      List<Map<String, dynamic>> dataObjects = rows.skip(2).map((row) {
        return Map.fromIterables(keys, row);
      }).toList();

      // Print the created objects
      for (var dataObject in dataObjects) {
        print(dataObject);
      }
    } catch (e) {
      // Handle the error
      print('Error reading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: readCsvFromAssets,
        child: const Text('Pick and Read CSV File'),
      ),
    );
  }
}
