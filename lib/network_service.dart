import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:robiko_shop/model/category_attribute.dart';
import 'package:robiko_shop/model/json_saved_article.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/product.model.dart';

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
      if (kDebugMode) {
        print('Error in uploadListing: $e');
      }
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
      '.gif',
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

      if (kDebugMode) {
        print('Listing published: ${response.body}');
      }

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

  Future<Map<String, JsonSavedArticle>> getKatbrojId() async {
    try {
      Map<String, dynamic> data = await fetchCurrentJson();

      Map<String, JsonSavedArticle> catalogMap = {};
      data.forEach((key, value) {
        catalogMap[key] = JsonSavedArticle.fromJson(value);
      });

      if (kDebugMode) {
        print('Loaded katbroj_id.json from Firebase Storage');
      }

      return catalogMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getKatbrojId: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchCurrentJson() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    String downloadURL = await storage.ref('katbroj_id.json').getDownloadURL();
    var response = await http.get(Uri.parse(downloadURL));
    return jsonDecode(response.body);
  }

  Future<bool> modifyAndUploadJson(List<Product> successfulUploads) async {
    try {
      // Step 1: Fetch the current JSON from Firebase
      Map<String, dynamic> currentData = await fetchCurrentJson();

      // Step 2: Merge new data with the fetched JSON
      for (var product in successfulUploads) {
        currentData[product.catalogNumber] = product.toJsonSavedArticle();
      }

      // Step 3: Convert merged data to JSON and upload it back
      FirebaseStorage storage = FirebaseStorage.instance;
      var modifiedJson = jsonEncode(currentData);
      Uint8List bytes = Uint8List.fromList(utf8.encode(modifiedJson));

      await storage.ref('katbroj_id.json').putData(
            bytes,
            SettableMetadata(contentType: 'application/json; charset=UTF-8'),
          );

      if (kDebugMode) {
        print('Successfully updated and uploaded JSON.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in modifyAndUploadJson: $e');
      }
      return false;
    }
    return true;
  }

  Future<bool> deleteListingsFromJson(List<String> deleteList) async {
    try {
      // Step 1: Fetch the current JSON from Firebase
      Map<String, dynamic> currentData = await fetchCurrentJson();

      // Step 2: Remove listings from the fetched JSON
      for (var catalogNumber in deleteList) {
        currentData.remove(catalogNumber);
      }

      // Step 3: Convert updated data to JSON and upload it back
      FirebaseStorage storage = FirebaseStorage.instance;
      var encoder = const JsonEncoder.withIndent('  ');
      var modifiedJson = encoder.convert(currentData);
      Uint8List bytes = Uint8List.fromList(modifiedJson.codeUnits);
      await storage.ref('katbroj_id.json').putData(bytes);

      if (kDebugMode) {
        print('Successfully updated and uploaded JSON. Deleted: $deleteList');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteListingsFromJson: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchUserListings() async {
    // var url = Uri.parse('https://api.olx.ba/users/RobikoShop/listings');
    List<Listing> listings = [];
    Map<String, bool> listingIds = {};
    int currentPage = 1;
    bool hasMore = true;

    while (hasMore) {
      var url = Uri.parse(
          'https://api.olx.ba/users/RobikoShop/listings?per_page=1000&page=$currentPage');

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
              listingIds[listing.id.toString()] = true;
              if (kDebugMode) {
                // print(listing);
              } // Print each listing object
            }
          }
          // return listings;
          if (data['meta']['last_page'] == currentPage) {
            hasMore = false;
          }
          currentPage++;
        } else {
          // Handle the case where the server does not return a 200 OK response
          if (kDebugMode) {
            print(
                'Failed to load listings. Status code: ${response.statusCode}');
          }
          hasMore = false;
          return {
            'listings': [],
            'listingIds': [],
          };
        }
      } catch (e) {
        // Handle any errors that occur during the request
        if (kDebugMode) {
          print('Error: $e');
        }
        hasMore = false;
        return {
          'listings': [],
          'listingIds': [],
        };
      }
    }

    return {
      'listings': listings,
      'listingIds': listingIds,
    };
  }

  Future<Map<String, dynamic>> fetchListingRefreshLimits() async {
    var url = Uri.parse('$baseUrl/listing/refresh/limits');
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
            'Failed to fetch listing refresh limits: ${response.statusCode}, ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error in fetchListingRefreshLimits: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchListingLimits() async {
    var url = Uri.parse('$baseUrl/listing-limits');
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationToken,
        },
      );

      print(response);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
            'Failed to fetch listing limits: ${response.statusCode}, ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error in fetchListingLimits: $e');
      return {};
    }
  }

  Future<String> refreshListing(String listingId) async {
    var url = Uri.parse('$baseUrl/listings/$listingId/refresh');
    try {
      var response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['message'];
      } else {
        print(
            'Failed to refresh listing: ${response.statusCode}, ${response.body}');
        return 'Failed to refresh listing.';
      }
    } catch (e) {
      print('Error in refreshListing: $e');
      return 'Error occurred while refreshing listing.';
    }
  }
}
