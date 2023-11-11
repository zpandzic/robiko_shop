import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  // Function to pick and read Excel file
  void pickAndReadExcel() async {
    // Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      // Read the Excel file
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      // Print the contents of the Excel file
      for (var table in excel.tables.keys) {
        print(table); //sheet Name
        // print(excel.tables[table]?.maxCols);
        print(excel.tables[table]?.maxRows);
        for (var row in excel.tables[table]!.rows) {
          print("$row");
        }
      }
    } else {
      // User canceled the picker
      print('No file selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Excel Importer'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: pickAndReadExcel,
          child: Text('Pick and Read Excel File'),
        ),
      ),
    );
  }
}
