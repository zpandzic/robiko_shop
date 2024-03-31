// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
//
// class PublishingWidget extends StatefulWidget {
//   const PublishingWidget({super.key});
//
//   @override
//   PublishingWidgetState createState() => PublishingWidgetState();
// }
//
// class PublishingWidgetState extends State<PublishingWidget> {
//   final service = FlutterBackgroundService();
//   final StreamController<Map<String, dynamic>> _publishingStreamController =
//       StreamController.broadcast();
//
//   bool serviceIsRunning = false;
//
//   int currentProductIndex = 0;
//   int successfulUploads = 0;
//   int failedUploads = 0;
//   int totalProducts = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     service.on('update').listen((event) {
//       _publishingStreamController.add({
//         "successfulUploads": event?["successfulUploads"],
//         "failedUploads": event?["failedUploads"],
//         "totalProducts": event?["totalProducts"],
//         "isPaused": event?["isPaused"],
//         "nextPublishTime": event?["nextPublishTime"],
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   void showPublishingDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Objavljivanje proizvoda'),
//           content: StreamBuilder<Map<String, dynamic>>(
//             stream: _publishingStreamController.stream,
//             builder: (context, snapshot) {
//               final data = snapshot.data ?? {};
//               final successfulUploads = data["successfulUploads"] ?? 0;
//               final failedUploads = data["failedUploads"] ?? 0;
//               final totalProducts = data["totalProducts"] ?? 0;
//               final limitReached = data["limitReached"] ?? false;
//               String? nextPublishTime = data["nextPublishTime"];
//
//               print('nextPublishTime: $nextPublishTime');
//
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: <Widget>[
//                   Column(
//                     children: [
//                       LinearProgressIndicator(
//                           value: (successfulUploads + failedUploads) /
//                               (totalProducts == 0 ? 1 : totalProducts)),
//                       SizedBox(height: 8),
//                       Text(
//                           'U tijeku ${successfulUploads + failedUploads} od $totalProducts'),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                   Text('Uspješno: $successfulUploads'),
//                   Text('Neuspješno: $failedUploads',
//                       style: TextStyle(color: Colors.red)),
//                 ],
//               );
//             },
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 service.invoke('stopService');
//                 Navigator.of(context).pop();
//                 setState(() {
//                   serviceIsRunning = false;
//                 });
//               },
//               child: Text('Zaustavi objavljivanje'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         ElevatedButton(
//             onPressed: () {
//               if (!serviceIsRunning) {
//                 service.startService();
//                 setState(() {
//                   serviceIsRunning = true;
//                 });
//               }
//               showPublishingDialog(context);
//             },
//             child: const Text(
//               'Pokreni objavljivanje',
//             )),
//       ],
//     );
//   }
// }
