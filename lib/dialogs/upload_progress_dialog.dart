import 'package:flutter/material.dart';

// class UploadProgressDialog extends StatelessWidget {
//   final int successfulUploads;
//   final int failedUploads;
//   final int totalProducts;
//   final String? nextPublishTime;
//   final VoidCallback onCancel;
//
//   const UploadProgressDialog({
//     Key? key,
//     required this.successfulUploads,
//     required this.failedUploads,
//     required this.totalProducts,
//     this.nextPublishTime,
//     required this.onCancel,
//   }) : super(key: key);
class UploadProgressDialog extends StatefulWidget {
  final void Function(void Function(int, int, int, String?)) onUploadProgress;

  final VoidCallback onCancel;

  const UploadProgressDialog({
    Key? key,
    required this.onUploadProgress,
    required this.onCancel,
  }) : super(key: key);

  @override
  UploadProgressDialogState createState() => UploadProgressDialogState();
}

class UploadProgressDialogState extends State<UploadProgressDialog> {
  int _successfulUploads = 0;
  int _failedUploads = 0;
  int _totalProducts = 0;
  String? _nextPublishTime;

  void _updateCounts(
      int successful, int failed, int totalProducts, String? nextPublishTime) {
    if (mounted == false) return;
    setState(() {
      _successfulUploads = successful;
      _failedUploads = failed;
      _totalProducts = totalProducts;
      _nextPublishTime = nextPublishTime;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.onUploadProgress(_updateCounts);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Objavljivanje proizvoda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: [
              LinearProgressIndicator(
                  value: (_successfulUploads + _failedUploads) /
                      (_totalProducts == 0 ? 1 : _totalProducts)),
              const SizedBox(height: 8),
              Text(
                '${_totalProducts == (_successfulUploads + _failedUploads) ? 'Objavljivanje završeno' : 'U tijeku'} ${_successfulUploads + _failedUploads} od ${_totalProducts}',
              ),
              if (_nextPublishTime != null)
                Text(
                  'Objavljivanje je zaustavljeno do $_nextPublishTime',
                )
            ],
          ),
          SizedBox(height: 20),
          Text('Uspješno: $_successfulUploads'),
          Text(
            'Neuspješno: $_failedUploads',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            widget.onCancel();
          },
          child: Text('Zaustavi objavljivanje'),
        ),
      ],
    );
  }
}
