import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Odaberi i učitaj Excel'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['xlsx', 'xls'],
              );
              print(result!.files.first.name);

              if (result != null) {
                var bytes = result.files.first.bytes;
                print(result.files.first.bytes);
                var excel = Excel.decodeBytes(bytes!);

                for (var table in excel.tables.keys) {
                  print(table); // Ime sheet-a
                  // print(excel.tables[table]?.maxCols);
                  print(excel.tables[table]?.maxRows);
                  for (var row in excel.tables[table]!.rows) {
                    print("$row");
                  }
                }
              } else {
                // Korisnik je odustao od biranja datoteke
                print("Odabir datoteke otkazan.");
              }
            },
            child: Text('Odaberi Excel Datoteku'),
          ),
        ),
      ),
    );
  }
}
