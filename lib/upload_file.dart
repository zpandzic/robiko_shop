import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

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
      print(filePath);
      setState(() {
        selectedFile = File(filePath);
      });
    } else {
      print('No file selected');
    }
  }

  // void loadCsvFile() async {
  //   if (selectedFile != null) {
  //     // Your logic to read and process the CSV file goes here
  //     final input = selectedFile!.openRead();
  //     List<List> rows = await input
  //         .transform(utf8.decoder)
  //         .transform(const CsvToListConverter(fieldDelimiter: ';'))
  //         .toList();

  //     mapRows(rows);
  //   } else {
  //     print('Please select a file first.');
  //   }
  // }

  void loadCsvFile() async {
    if (selectedFile != null) {
      final input = selectedFile!.openRead();
      int rowCount = 0;
      const int maxRowsForTesting = 3; // Number of rows to read for testing

      List<List<dynamic>> rows = [];

      Stream<List> csvStream = input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ';'));

      await for (List<dynamic> row in csvStream) {
        rows.add(row);
        rowCount++;
        if (rowCount >= maxRowsForTesting) break;
      }

      mapRows(rows);
    } else {
      print('Please select a file first.');
    }
  }

  void mapRows(List<List> rows) {
    if (rows.isEmpty) return;

    // Assuming header row is the first row of the CSV
    List<dynamic> headerRow = rows[1];

    // Create a map for column indexes
    Map<String, int> columnIndexes = {};
    for (int i = 0; i < headerRow.length; i++) {
      columnIndexes[headerRow[i].toString()] = i;
    }

    switch (dropdownValue) {
      case 'VisokaZalihe':
        // Skip the first row (header row) and map each row to a VisokaZalihe object
        List<VisokaZalihe> dataObjects = rows.skip(2).map((row) {
          return VisokaZalihe.fromCsvRow(row, columnIndexes);
        }).toList();

        ProductRepository().products =
            Product.fromVisokaZaliheList(dataObjects);

        ProductRepository().printFormattedJson();
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
          // ElevatedButton(
          //   onPressed: uploadListing,
          //   child: const Text('Objavi'),
          // ),
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

void uploadListings(List<Product> products) async {
  for (var product in products) {
    // printFormattedJson(product.toListing());

    // await addImage('58087762', '1457431703(PU1021X)');

    await uploadListing(product.toListing(), product.catalogNumber);
  }
}

void printFormattedJson(Map<String, dynamic> jsonData) {
  JsonEncoder encoder = JsonEncoder.withIndent('  '); // Two-space indentation
  String prettyPrint = encoder.convert(jsonData);
  print(prettyPrint);
}

Future<http.Response> uploadListing(
    Map<String, dynamic> listingData, String catalogNumber) async {
  printFormattedJson(listingData);

  var url = Uri.parse('https://api.olx.ba/listings');

  try {
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer 6992342|MZKjrtskpHnlW71Xc9pbtibtpuFrcIuNX7G3uLlh',
      },
      body: json.encode(listingData),
    );
    print('[uploadListing] Response status: ${response.statusCode}');
    print('[uploadListing] Response body: ${response.body}');

    if (response.statusCode == 201) {
      var data = json.decode(response.body);
      String listingId = data['id'].toString();
      await addImage(listingId, catalogNumber);
      await publishListing(listingId);
    }

    return response;
  } catch (e) {
    // Print error if the request fails
    print('Error occurred: $e');
    rethrow; // Rethrowing the exception to handle it at the calling place
  }
}

Future<File?> getImageFileFromAssets(String imageName) async {
  List<String> extensions = [
    '.jpg',
    '.png',
    // '.jpeg'
  ]; // List of possible extensions
  for (var ext in extensions) {
    try {
      final filePath = 'assets/slike/$imageName$ext';
      final byteData = await rootBundle.load(filePath);
      final file =
          File('${(await getTemporaryDirectory()).path}/$imageName$ext');
      await file.writeAsBytes(
        byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
      return file; // File found and written
    } catch (e) {
      // File with this extension not found, try next
    }
  }
  // No file found with any of the extensions
  return null;
}

Future<void> addImage(String id, String catalogNumber) async {
  var url = Uri.parse('https://api.olx.ba/listings/${id}/image-upload');

  String imageName = catalogNumber.replaceAll("/", "\$");

  File? imageFile = await getImageFileFromAssets(imageName);

  print(imageFile);
  if (imageFile == null) {
    return;
  }

  var request = http.MultipartRequest('POST', url)
    ..headers.addAll({
      'Authorization':
          'Bearer 6992342|MZKjrtskpHnlW71Xc9pbtibtpuFrcIuNX7G3uLlh',
    })
    ..files.add(await http.MultipartFile.fromPath(
      'images[]', // The field name in the form
      imageFile.path,
      filename:
          path.basename(imageFile.path), // Extracting the basename of the file
    ));

  try {
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return;
  } catch (e) {
    print('Error occurred: $e');
    rethrow; // Rethrow the exception to handle it in the calling function
  }
}

Future<http.Response> publishListing(String listingId) async {
  String token = '6992342|MZKjrtskpHnlW71Xc9pbtibtpuFrcIuNX7G3uLlh';
  var url = Uri.parse('https://api.olx.ba/listings/$listingId/publish');

  try {
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response;
  } catch (e) {
    print('Error occurred: $e');
    rethrow; // Rethrowing the exception to handle it at the calling place
  }
}
