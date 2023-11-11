import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: pickAndReadCsv,
        child: const Text('Pick and Read CSV File'),
      ),
    );
  }
}
