import 'package:flutter/material.dart';

class UploadProgressDialog extends StatefulWidget {
  final int totalProducts;
  final void Function(void Function(int, bool)) onUploadProgress;
  final void Function(void Function()) onCancel;

  const UploadProgressDialog({
    Key? key,
    required this.totalProducts,
    required this.onUploadProgress,
    required this.onCancel,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _UploadProgressDialogState createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  int currentProductIndex = 0;
  int successfulUploads = 0;
  int failedUploads = 0;

  void updateProgress(int index, bool isSuccess) {
    setState(() {
      currentProductIndex = index;
      if (isSuccess) {
        successfulUploads++;
      } else {
        failedUploads++;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Invoke the callback with the updateProgress function
    widget.onUploadProgress(updateProgress);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uploading Products'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: currentProductIndex / widget.totalProducts,
          ),
          const SizedBox(height: 20),
          Text(
              'Uploading product $currentProductIndex of ${widget.totalProducts}'),
          Text('Successful uploads: $successfulUploads'),
          Text('Failed uploads: $failedUploads'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => {
            widget.onCancel((){
              Navigator.of(context).pop();
            }),
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}