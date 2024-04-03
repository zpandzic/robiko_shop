import 'package:robiko_shop/model/attribute_value.dart';
import 'package:robiko_shop/model/listing.model.dart';
import 'package:robiko_shop/model/nuic_csv.dart';
import 'package:robiko_shop/model/visokaZaliheData.model.dart';
import 'package:robiko_shop/product_repository.dart';
import 'package:robiko_shop/services/firebase_service.dart';

class Product {
  String? imageUrl;
  String name;
  String? code;
  String catalogNumber;
  String description;
  late List<AttributeValue>? attributesList;
  String? category;
  int? categoryId;
  double price;
  String? listingId;

  Product({
    required this.imageUrl,
    required this.name,
    required this.code,
    required this.catalogNumber,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.price,
    required this.attributesList,
    this.listingId,
  });

  // Static method to map VisokaZalihe to Product
  static List<Product> fromVisokaZaliheList(
      List<VisokaZalihe> visokaZaliheList) {
    return visokaZaliheList.fold<List<Product>>([],
        (List<Product> list, VisokaZalihe visokaZalihe) {
      //todo compare prices also
      if (!ProductRepository()
          .firebaseUploadedListings
          .containsKey(FirebaseService().sanitizeKey(visokaZalihe.katBroj))) {
        list.add(Product(
          imageUrl: null,
          name: visokaZalihe.nazivRobe,
          code: visokaZalihe.sifraRobe,
          catalogNumber: visokaZalihe.katBroj,
          description: '',
          category: null,
          categoryId: null,
          attributesList: null,
          price: visokaZalihe.mpc,
        ));
      }
      return list;
    });
  }

  static List<Product> fromNuicList(List<NuicCsv> nuicList) {
    return nuicList.fold<List<Product>>([], (List<Product> list, NuicCsv nuic) {
      //todo compare prices also

      if (!ProductRepository()
          .firebaseUploadedListings
          .containsKey(FirebaseService().sanitizeKey(nuic.katBroj))) {
        list.add(Product(
          imageUrl: null,
          name: nuic.nazivRobe,
          code: null,
          catalogNumber: nuic.katBroj,
          description: '',
          category: null,
          categoryId: null,
          attributesList: null,
          price: nuic.mpc,
        ));
      }
      return list;
    });
  }

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      imageUrl: json['imageUrl'],
      name: json['name'],
      code: json['code'],
      catalogNumber: json['catalogNumber'],
      description: json['description'],
      category: json['category'],
      categoryId: json['categoryId'],
      price: json['price']?.toDouble() ?? 0.0,
      // Pretpostavka ukoliko je price tipa String u JSON-u
      attributesList: json['attributesList'] != null
          ? List<AttributeValue>.from(
              json['attributesList'].map((x) => AttributeValue.fromJson(x)))
          : null,
      listingId: json['listingId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'imageUrl': imageUrl,
      'name': name,
      'catalogNumber': catalogNumber,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'attributesList': attributesList?.map((e) => e.toJson()).toList(),
    };
  }

  // Convert a Product to a Listing Map
  // Map<String, dynamic> toListing() {
  //   return {
  //     'title': '$name $catalogNumber',
  //     'listing_type': 'sell', // Assuming 'sell' as default
  //     'description': description,
  //     'price': price,
  //     'category_id': categoryId,
  //     'attributes': attributesList
  //             ?.where((attr) => attr.value.isNotEmpty)
  //             .map((attr) => attr.toJson())
  //             .toList() ??
  //         [],
  //     'available': true, // Assuming always true
  //     'state': 'new', // Assuming 'new' as default
  //     'country_id': 49, // Set default or dynamic value
  //     'city_id': 16, // Set default or dynamic value
  //   };
  // }

  Map<String, dynamic> toListing() {
    // Uključujemo katalog broj u opis, osiguravamo da je uvijek prisutan
    String fullName = '$name $catalogNumber';

    // Ako je ukupna dužina veća od 55, smanjujemo ime, ali zadržavamo katalog broj
    if (fullName.length > 55) {
      int nameLength = 55 - catalogNumber.length - 1; // 1 za razmak
      name = name.substring(0, nameLength > 0 ? nameLength : 0).trim();
      fullName = '$name $catalogNumber';
    }

    String description = this.description.isNotEmpty
        ? "${this.description.split(";").map((item) => "<p>$item</p>").join("")}<p><br></p>"
        : "";

    description += "<p>Naziv: $name</p><p>Kataloški broj: $catalogNumber</p><p></p>";

    description += """
          <p><strong>Dobrodošli u RobikoShop - Vaš partner za autodijelove, ulja i usluge servisa i optike trapa!</strong></p>
          <p>Robiko d.o.o. je pouzdana destinacija za sve vaše potrebe u vezi s automobilima. Od osnivanja, posvećeni smo pružanju vrhunskih proizvoda i usluga našim klijentima diljem [lokacija].</p>
          <p><strong>Naša ponuda:</strong></p>
          <ul>
              <li><strong>Autodijelovi:</strong> Ponosno nudimo širok asortiman novih autodijelova za različite marke i modele vozila. Bez obzira jeste li u potrazi za dijelovima za motor, kočnice, ovjes ili nešto drugo, u našoj ponudi ćete pronaći sve što vam je potrebno za održavanje i popravak vašeg vozila.</li>
              <li><strong>Ulja:</strong> Kvalitetno ulje je ključno za optimalno funkcioniranje vašeg vozila. U našoj trgovini možete pronaći širok izbor ulja različitih viskoznosti i specifikacija, kako biste osigurali dugotrajnost i pouzdanost vašeg motora.</li>
              <li><strong>Servis:</strong> Naš stručni tim mehaničara posvećen je pružanju vrhunskih usluga održavanja i popravaka vozila. Bez obzira jeste li u potrebi za redovitim servisom, popravkom ili dijagnostikom, možete računati na nas za brzu, pouzdanu i profesionalnu uslugu.</li>
              <li><strong>Optika trapa:</strong> Precizno podešen ovjes ključan je za udobnost, sigurnost i stabilnost vašeg vozila. Naš tim stručnjaka opremljen je najnovijom opremom i znanjem kako bi osigurao da je vaša optika trapa u savršenom stanju.</li>
          </ul>
          <p>Uzimajući u obzir našu stručnost, predanost kvaliteti i izvrsnu uslugu, Robiko d.o.o. je vaša prvotna destinacija za sve vaše potrebe u vezi s automobilima. Kontaktirajte nas danas i dopustite nam da vam pružimo vrhunsku podršku koja vam je potrebna!</p>
          <p><br></p>
          <p><strong>Kontakt broj: 00387 63 885 439 / 00387 39 670 959</strong></p>
          """;

    final Map<String, dynamic> listing = {
      'title': fullName,
      'listing_type': 'sell',
      'description': description,
      'price': price,
      'category_id': categoryId,
      'available': true,
      'state': 'new', // Assuming 'new' as default
      'country_id': 49, // Set default or dynamic value
      'city_id': 16, // Set default or dynamic value
    };

    if (attributesList != null && attributesList!.isNotEmpty) {
      listing['attributes'] = attributesList!
          .where((attr) => attr.value.isNotEmpty)
          .map((attr) => attr.toJson())
          .toList();
    }

    return listing;
  }

  static Product fromListing(Listing listing) {
    return Product(
      imageUrl: listing.image,
      name: listing.title,
      code: null,
      listingId: listing.id.toString(),
      catalogNumber: '',
      description: 'Opis nije dostupan',
      category: null,
      categoryId: listing.categoryId,
      price: listing.price,
      attributesList: [], // Ovisno o `Listing`, možda ćete trebati implementirati logiku za mapiranje atributa
    );
  }
}
