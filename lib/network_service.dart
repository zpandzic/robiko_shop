import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:robiko_shop/model/category_attribute.dart';

class NetworkService {
  final String baseUrl = 'https://api.olx.ba';
  final String authorizationToken =
      'Bearer 6992342|MZKjrtskpHnlW71Xc9pbtibtpuFrcIuNX7G3uLlh';

  // Constructor
  NetworkService();

  // Method to upload a listing
  Future<String> uploadListing(
      Map<String, dynamic> listingData, String catalogNumber) async {
    var url = Uri.parse('$baseUrl/listings');
    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationToken,
        },
        body: json.encode(listingData),
      );

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        String listingId = data['id'].toString();
        await addImage(listingId, catalogNumber);
        await publishListing(listingId);

        return listingId;
      } else {
        throw Exception(
          'Failed to upload listing : ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      print('Error in uploadListing: $e');
      rethrow;
    }
  }

  // Method to add an image to a listing
  Future<void> addImage(String id, String catalogNumber) async {
    var url = Uri.parse('$baseUrl/listings/$id/image-upload');
    String imageName = catalogNumber.replaceAll("/", "\$");

    // Assuming getImageFileFromAssets is a method that retrieves the image file
    File? imageFile = await getImageFileFromAssets(imageName);

    if (imageFile == null) {
      return;
    }

    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': authorizationToken,
      })
      ..files.add(await http.MultipartFile.fromPath(
        'images[]', // The field name in the form
        imageFile.path,
      ));
    try {
      var streamedResponse = await request.send();
      await http.Response.fromStream(streamedResponse);
      return;
    } catch (e) {
      if (kDebugMode) {
        print('Error in addImage: $e');
      }
      rethrow;
    }
  }

// Helper method to get image file from assets
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

// Method to publish a listing
  Future<http.Response> publishListing(String listingId) async {
    var url = Uri.parse('$baseUrl/listings/$listingId/publish');
    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationToken,
        },
      );

      print('Listing published: ${response.body}');

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in publishListing: $e');
      }
      rethrow;
    }
  }

// Method to fetch categories
  Future<List<dynamic>> fetchCategories(String query) async {
    var url = Uri.parse('$baseUrl/categories/find?name=$query');
    try {
      var response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': authorizationToken,
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchCategories: $e');
      }
      rethrow;
    }
  }

  Future<List<CategoryAttribute>> fetchCategoryAttributes(
    int categoryId,
  ) async {
    final url =
        Uri.parse('https://api.olx.ba/categories/$categoryId/attributes');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['data'];

      return data.map((json) => CategoryAttribute.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load category attributes');
    }
  }

  Future<void> modifyJsonOnDrive() async {
    // Step 1: Download the file from Google Drive
    final response = await http.get(Uri.parse(
        'https://drive.google.com/uc?export=download&id=1CmEdracvS4FulGxwqvt8JQxS7lI4eoGB'));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      // Step 2: Modify the file
      // This is where you'd modify the JSON object as needed
      jsonResponse['newKey'] = 'newValue';

      // Step 3: Upload the modified file to Google Drive
      // You'll need to replace 'yourOAuthToken' and 'fileId' with your actual OAuth token and file ID
      var request = http.MultipartRequest(
          'PATCH',
          Uri.parse(
              'https://www.googleapis.com/upload/drive/v3/files/1CmEdracvS4FulGxwqvt8JQxS7lI4eoGB?uploadType=multipart&fields=id&supportsAllDrives=true'))
        // ..headers['Authorization'] = 'Bearer yourOAuthToken'
        ..files.add(http.MultipartFile.fromString(
          'file',
          jsonEncode(jsonResponse),
          filename: 'katbroj_id.json',
        ));

      var res = await request.send();

      if (res.statusCode == 200) {
        print('File uploaded successfully');
      } else {
        print('Failed to upload file');
      }
    } else {
      throw Exception('Failed to load JSON');
    }
  }

  Future<void> fetchJsonFromDrive() async {
    final response = await http.get(Uri.parse(
        'https://drive.google.com/uc?export=download&id=1CmEdracvS4FulGxwqvt8JQxS7lI4eoGB'));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse.toString());
      return;
    } else {
      throw Exception('Failed to load JSON');
    }

    // var url = 'https://drive.google.com/file/d/1CmEdracvS4FulGxwqvt8JQxS7lI4eoGB/view?export=download';
    // var response = await http.get(Uri.parse(url));
    //
    // if (response.statusCode == 200) {
    //   var jsonResponse = jsonDecode(response.body);
    //   print(jsonResponse);
    // } else {
    //   throw Exception('Failed to load JSON from Google Drive');
    // }
  }
}
