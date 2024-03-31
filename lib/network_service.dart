import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:robiko_shop/model/category_attribute.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/services/firebase_service.dart';

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

    File? imageFile = await getImageFileFromUrl(
      FirebaseService().getImageFromProduct(catalogNumber),
      id,
    );

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
      print('Error in addImage: $e');
      rethrow;
    }
  }

  Future<File?> getImageFileFromUrl(String? imageUrl, String imageName) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    try {
      // Preuzmi sliku s URL-a
      var response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Dohvati privremeni direktorij
        var tempDir = await getTemporaryDirectory();
        String filePath = '${tempDir.path}/$imageName';
        File file = File(filePath);

        // Spremi preuzete podatke kao datoteku
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        // Neuspješan odgovor
        print('Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Uhvati i obradi iznimke
      print('Error in getImageFileFromUrl: $e');
      return null;
    }
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
      print('Error in publishListing: $e');

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
      print('Error in fetchCategories: $e');

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

  Future<List<Listing>> fetchUserListings() async {
    // var url = Uri.parse('https://api.olx.ba/users/RobikoShop/listings');
    List<Listing> listings = [];
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
              // Print each listing object
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

  Future<void> deleteListing(String listingId) async {
    var url = Uri.parse('$baseUrl/listings/$listingId');
    try {
      var response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationToken,
        },
      );

      if (response.statusCode == 200) {
        print('Listing successfully deleted: $listingId');
      } else {
        throw Exception(
          'Failed to delete listing: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      print('Error in deleteListing: $e');
      rethrow;
    }
  }

  void deleteDuplicates(List<String> duplicates) {
    for (var listingId in duplicates) {
      deleteListing(listingId);
    }
  }
}
