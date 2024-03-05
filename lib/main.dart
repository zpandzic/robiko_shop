import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/screens/products_screen.dart';
import 'package:robiko_shop/services/dialog_service.dart';
import 'package:robiko_shop/upload_file.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ProductRepository().initializeData();

  runApp(const MyApp());
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        DialogService().showLoadingDialog(context);

        await ProductRepository().initializeData();
        Navigator.of(context).pop();

        if (ProductRepository().firebaseUploadedListings.isEmpty) {
          DialogService().showWarningDialog(
            context,
            'Greška',
            'Dogodila se greška pri učitavanju podataka.',
          );
        }
      } catch (e) {
        DialogService().showWarningDialog(
            context, 'Greška', 'Dogodila se greška pri učitavanju podataka.$e');
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
