import 'package:flutter/material.dart';

import '../../domain/entities/trip.dart';

class TripDetailScreen extends StatelessWidget {
  final TripEntity trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _DetailRow(label: 'Destination', value: trip.destination ?? '—'),
            _DetailRow(
              label: 'Start Date',
              value: trip.startDate?.toIso8601String().split('T').first ?? '—',
            ),
            _DetailRow(
              label: 'End Date',
              value: trip.endDate?.toIso8601String().split('T').first ?? '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
