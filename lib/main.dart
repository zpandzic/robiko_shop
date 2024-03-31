import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/firebase_options.dart';
import 'package:robiko_shop/model/product.model.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/screens/products_screen.dart';
import 'package:robiko_shop/services/dialog_service.dart';
import 'package:robiko_shop/services/firebase_service.dart';
import 'package:robiko_shop/upload_file.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ProductRepository().initializeData();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  // final service = FlutterBackgroundService();
  //
  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart,
  //     autoStart: false,
  //     isForegroundMode: false,
  //   ),
  //   iosConfiguration: IosConfiguration(),
  // );
}

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   print('Service started');
//   DartPluginRegistrant.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   await ProductRepository().getUploadedData();
//
//   SharedPreferences preferences = await SharedPreferences.getInstance();
//
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//
//   service.on('stopService').listen((event) {
//     preferences.clear();
//     service.stopSelf();
//   });
//
//   handleUploadProducts(service);
// }

// void handleUploadProducts(ServiceInstance service) async {
//   SharedPreferences preferences = await SharedPreferences.getInstance();
//   String? productsJsonString = await preferences.getString("productsForUpload");
//   List<Product> productsForUpload = [];
//   if (productsJsonString != null) {
//     productsForUpload = List<Product>.from(json
//         .decode(productsJsonString)
//         .map((model) => Product.fromJson(model)));
//     print(productsForUpload);
//   }
//
//   try {
//     var successfulUploads = await uploadListings(productsForUpload, service);
//     // ProductRepository().removeUploadedProducts(successfulUploads);
//     // DialogService().showLoadingDialog(context);
//
//     // await ProductRepository().refreshUserListings().then(
//     //       (value) => setState(() {
//     //         ProductRepository().removeUploadedProducts(successfulUploads);
//     //       }),
//     //     );
//
//     // Navigator.of(context).pop();
//
//       print(jsonEncode(successfulUploads));
//   } catch (e) {
//       print(e);
//   }
//
//   preferences.clear();
//
//     print('service.stopSelf();');
//   service.stopSelf();
// }
//
// Future<List<Product>> uploadListings(List<Product> productsForUpload,
//     ServiceInstance service,) async {
//   bool isUploadCancelled = false;
//   List<Product> successfulUploads = [];
//   List<Product> firebaseList = [];
//
//   int totalProducts = productsForUpload.length;
//   int failedUploads = 0;
//   bool limitReached = false;
//   String? nextPublishTime;
//
//   for (int currentIndex = 0;
//   currentIndex < productsForUpload.length;
//   currentIndex++) {
//     limitReached = false;
//
//     Product product = productsForUpload[currentIndex];
//
//     if (isUploadCancelled == true) {
//       break;
//     }
//
//     try {
//       String listingId = await NetworkService()
//           .uploadListing(product.toListing(), product.catalogNumber);
//       product.listingId = listingId;
//
//       await Future.delayed(const Duration(milliseconds: 50));
//
//       successfulUploads.add(product);
//       firebaseList.add(product);
//     } catch (e) {
//       if (true) {
//         limitReached = true; //provjeriti response
//         currentIndex--;
//       } else {
//         failedUploads++;
//       }
//     }
//
//     if (firebaseList.length >= 10) {
//       firebaseUploadListings(firebaseList);
//     }
//
//     if (limitReached == true) {
//       var time = DateTime.now().add(const Duration(minutes: 30));
//       nextPublishTime =
//       "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(
//           2, '0')}";
//     } else {
//       nextPublishTime = null;
//     }
//
//     service.invoke('update', {
//       "successfulUploads": successfulUploads.length,
//       "failedUploads": failedUploads,
//       "totalProducts": totalProducts,
//       "limitReached": limitReached,
//       "nextPublishTime": nextPublishTime
//     });
//
//     if (limitReached) {
//       await Future.delayed(const Duration(seconds: 1));
//       limitReached = false;
//     }
//   }
//
//   firebaseUploadListings(firebaseList);
//
//   return successfulUploads;
// }

Future<void> firebaseUploadListings(List<Product> firebaseList) async {
  // return;
  if (firebaseList.isNotEmpty) {
    try {
      await FirebaseService().addProducts(firebaseList);
      firebaseList.clear();
    } catch (e) {
      print(e);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      color: Colors.white,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        DialogService().showLoadingDialog(context);

        await ProductRepository().initializeData();
        if (mounted) Navigator.of(context).pop();

        if (ProductRepository().firebaseUploadedListings.isEmpty && mounted) {
          DialogService().showWarningDialog(
            context,
            'Greška',
            'Dogodila se greška pri učitavanju podataka.',
          );
        }
      } catch (e) {
        if (mounted) {
          DialogService().showWarningDialog(context, 'Greška',
              'Dogodila se greška pri učitavanju podataka.$e');
        }
      }
    });
  }

  static const List<Widget> _widgetOptions = <Widget>[
    UploadFile(),
    ProductsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 50),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Ucitaj',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Proizvodi',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
