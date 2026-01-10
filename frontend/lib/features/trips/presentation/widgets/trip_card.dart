import 'package:flutter/material.dart';

import '../../domain/entities/trip.dart';

class TripCard extends StatelessWidget {
  final TripEntity trip;
  final VoidCallback? onTap;

  const TripCard({super.key, required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (trip.destination?.isNotEmpty == true) trip.destination,
            if (trip.startDate != null) trip.startDate!.toIso8601String().split('T').first
          ].whereType<String>().join(' - '),
        ),
        trailing: trip.isPending
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Syncing', style: TextStyle(fontSize: 11)),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
