import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trips_bloc.dart';
import 'package:smart_trip_planner/features/trips/presentation/widgets/trip_card.dart';
import 'trip_detail_screen.dart';

class TripsListScreen extends StatefulWidget {
  const TripsListScreen({super.key});

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TripsBloc>().add(const TripsStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripsBloc, TripsState>(
      listenWhen: (prev, next) => prev.message != next.message && next.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.travel_explore, size: 22),
              SizedBox(width: 8),
              Text('My Trips'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              onPressed: () => context.read<TripsBloc>().add(const TripsRefreshed()),
              icon: const Icon(Icons.refresh),
            )
          ],
        ),
        floatingActionButton: BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, connectivityState) {
            return FloatingActionButton(
              onPressed: () {
                if (!connectivityState.isOnline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are offline. Trip creation is disabled.')),
                  );
                  return;
                }
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _TripFormSheet(
                    title: 'Create Trip',
                    submitLabel: 'Create',
                    onSubmit: (title, destination, startDate, endDate) {
                      context.read<TripsBloc>().add(
                            TripCreated(
                              title: title,
                              destination: destination,
                              startDate: startDate,
                              endDate: endDate,
                            ),
                          );
                    },
                  ),
                );
              },
              child: const Icon(Icons.add),
            );
          },
        ),
        body: Column(
          children: [
            BlocBuilder<ConnectivityCubit, ConnectivityState>(
              builder: (context, connectivityState) {
                return OfflineBanner(isOnline: connectivityState.isOnline);
              },
            ),
            const _TripsHeader(),
            Expanded(
              child: BlocBuilder<TripsBloc, TripsState>(
                builder: (context, state) {
                  if (state.status == TripsStatus.loading && state.trips.isEmpty) {
                    return const SkeletonLoader();
                  }

                  if (state.trips.isEmpty) {
                    return Center(
                      child: Text(
                        'No trips yet. Create your first one.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TripsBloc>().add(const TripsRefreshed());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.trips.length,
                      itemBuilder: (context, index) {
                        final trip = state.trips[index];
                        return TripCard(
                          trip: trip,
                          onTap: () => _openDetail(context, trip),
                          onMenu: () => _showTripActions(context, trip),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, TripEntity trip) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
    );
  }

  void _showTripActions(BuildContext context, TripEntity trip) {
    if (trip.isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip is syncing. Please wait.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit trip'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditTrip(context, trip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete trip'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(context, trip);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTrip(BuildContext context, TripEntity trip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TripFormSheet(
        title: 'Edit Trip',
        submitLabel: 'Save',
        initialTitle: trip.title,
        initialDestination: trip.destination,
        initialStartDate: trip.startDate,
        initialEndDate: trip.endDate,
        onSubmit: (title, destination, startDate, endDate) {
          context.read<TripsBloc>().add(
                TripUpdated(
                  tripId: trip.id,
                  title: title,
                  destination: destination,
                  startDate: startDate,
                  endDate: endDate,
                ),
              );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, TripEntity trip) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TripsBloc>().add(TripDeleted(tripId: trip.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsBloc, TripsState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B6E4F), Color(0xFF1B8A6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan your next escape',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${state.trips.length} trips in your travel board',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_road, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TripFormSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String? initialTitle;
  final String? initialDestination;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final void Function(
    String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  ) onSubmit;

  const _TripFormSheet({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialTitle,
    this.initialDestination,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_TripFormSheet> createState() => _TripFormSheetState();
}

class _TripFormSheetState extends State<_TripFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _destinationController =
        TextEditingController(text: widget.initialDestination ?? '');
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination (optional)'),
            ),
            const SizedBox(height: 12),
            _DatePickerField(
              label: 'Start Date (optional)',
              value: _startDate,
              onSelected: (value) => setState(() => _startDate = value),
            ),
            const SizedBox(height: 12),
            _DatePickerField(
              label: 'End Date (optional)',
              value: _endDate,
              onSelected: (value) => setState(() => _endDate = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(widget.submitLabel),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final destination = _destinationController.text.trim();
    widget.onSubmit(
      _titleController.text.trim(),
      destination.isEmpty ? null : destination,
      _startDate,
      _endDate,
    );

    Navigator.of(context).pop();
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onSelected;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (selected != null) {
          onSelected(selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value?.toIso8601String().split('T').first ?? 'Select'),
      ),
    );
  }
}
