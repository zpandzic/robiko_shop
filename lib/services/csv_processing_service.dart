import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:robiko_shop/model/nuic_csv.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/model/visokaZaliheData.model.dart';

class CsvProcessingService {
  Future<List<Product>> processCsv(File file, String csvType) async {
    List<List<dynamic>> rows = [];

    if (kIsWeb) {
      // var rowsAsListOfValues = const CsvToListConverter(
      //   fieldDelimiter: ';',
      // ).convert(file.path);

      List<String> rowsSA = const LineSplitter().convert(file.path);
      List<List<dynamic>> rowsAsListOfValues =
          rowsSA.map((e) => e.split(';')).toList();
      for (var row in rowsAsListOfValues) {
        rows.add(row);
      }
    } else {
      final input = file.openRead();

      Stream<List> csvStream = input
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((line) => line.split(';'));

      await for (List<dynamic> row in csvStream) {
        rows.add(row);
      }
    }

    // var j = 0;
    // await for (List<dynamic> row2 in csvStream2) {
    //   if (j == 4070) {
    //     print('Row : ${row2[0]}');
    //   }
    //
    //   if ((row2[0].toString()) != (rows[j][0]).toString()) {
    //     print('Row2 : ${row2[0]} != ${rows[j][0]}');
    //     kriviCatalogId
    //         .add('${rows[j][2]} ${rows[j][0]}');
    //   }
    //   j++;
    //
    //   rows2.add(row2);
    // }
    //
    // print('Krivi catalogId: $kriviCatalogId');
    //
    // print('Krivi catalogId: ${kriviCatalogId.length}');
    //
    // // NetworkService().deleteDuplicates()
    //
    // List<String> kriviListings = [];
    //
    // ProductRepository().activeProductList.forEach((element) {
    //   if (kriviCatalogId.contains(element.name)) {
    //     print(
    //       'Krivi catalogId: ${element.name}, ${element.listingId}',
    //     );
    //     kriviListings.add(element.listingId!);
    //   }
    // });
    //
    // print('Krivi Listings: ${kriviListings.length}');

    // NetworkService().deleteDuplicates(kriviListings);

    return mapRows(rows, csvType);
  }

  List<Product> mapRows(List<List> rows, String dropdownValue) {
    // return [];
    if (rows.isEmpty) return [];

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

        return Product.fromVisokaZaliheList(dataObjects);

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

        return Product.fromNuicList(dataObjects);

      default:
        return [];
    }
  }
}

enum CsvType { visokaZalihe, nuic }
