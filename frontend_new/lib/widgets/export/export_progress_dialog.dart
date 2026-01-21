import 'package:flutter/material.dart';

class ExportProgressDialog extends StatelessWidget {
  final bool isExporting;
  final bool isSuccess;
  final String? filePath;
  final String? error;
  final VoidCallback? onShare;
  final VoidCallback? onDismiss;

  const ExportProgressDialog({
    Key? key,
    required this.isExporting,
    this.isSuccess = false,
    this.filePath,
    this.error,
    this.onShare,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExporting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Exporting transactions...',
                style: TextStyle(fontSize: 16),
              ),
            ] else if (isSuccess) ...[
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Export Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File saved to:\n${filePath ?? 'Unknown location'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onShare != null)
                    TextButton(
                      onPressed: onShare,
                      child: const Text('Share'),
                    ),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('OK'),
                  ),
                ],
              ),
            ] else if (error != null) ...[
              Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Export Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onDismiss,
                child: const Text('OK'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}