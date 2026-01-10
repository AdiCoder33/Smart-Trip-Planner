import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  final String message;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    this.message = 'Offline mode: showing cached trips',
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.amber.shade200,
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
