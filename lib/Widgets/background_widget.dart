import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceWidget extends StatefulWidget {
  const BackgroundServiceWidget({Key? key}) : super(key: key);

  @override
  BackgroundServiceWidgetState createState() =>
      BackgroundServiceWidgetState();
}

class BackgroundServiceWidgetState extends State<BackgroundServiceWidget> {
  String text = "Start Service";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        StreamBuilder<Map<String, dynamic>?>(
          stream: FlutterBackgroundService().on('update'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data = snapshot.data!;
            String? device = data["device"];
            DateTime? date = DateTime.tryParse(data["current_date"]);
            return Column(
              children: [
                Text(device ?? 'Unknown'),
                Text(date.toString()),
              ],
            );
          },
        ),
        ElevatedButton(
          child: const Text("Foreground Mode"),
          onPressed: () {
            FlutterBackgroundService().invoke("setAsForeground");
          },
        ),
        ElevatedButton(
          child: const Text("Background Mode"),
          onPressed: () {
            FlutterBackgroundService().invoke("setAsBackground");
          },
        ),
        ElevatedButton(
          child: Text(text),
          onPressed: () async {
            final service = FlutterBackgroundService();
            var isRunning = await service.isRunning();
            if (isRunning) {
              service.invoke("stopService");
            } else {
              service.startService();
            }

            if (!isRunning) {
              text = 'Stop Service';
            } else {
              text = 'Start Service';
            }
            setState(() {});
          },
        ),
      ],
    );
  }
}
