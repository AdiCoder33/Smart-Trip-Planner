import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/entities/trip.dart';
import '../bloc/itinerary_bloc.dart';

class ItineraryTab extends StatelessWidget {
  final TripEntity trip;

  const ItineraryTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItineraryBloc, ItineraryState>(
      listenWhen: (prev, next) => prev.message != next.message && next.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: Column(
        children: [
          BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              return OfflineBanner(
                isOnline: connectivityState.isOnline,
                message: 'Offline mode: showing cached itinerary',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Itinerary', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => context.read<ItineraryBloc>().add(
                        ItineraryRefreshed(tripId: trip.id),
                      ),
                  icon: const Icon(Icons.refresh),
                ),
                TextButton.icon(
                  onPressed: () => _showFormSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ItineraryBloc, ItineraryState>(
              builder: (context, state) {
                if (state.status == ItineraryStatus.loading && state.items.isEmpty) {
                  return const SkeletonLoader();
                }

                if (state.items.isEmpty) {
                  return Center(
                    child: Text(
                      'No itinerary items yet.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (state.items.any((item) => item.isPending)) {
                      _showPendingMessage(context);
                      return;
                    }
                    final items = List<ItineraryItemEntity>.from(state.items);
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    final reordered = items
                        .asMap()
                        .entries
                        .map((entry) => entry.value.copyWith(sortOrder: entry.key))
                        .toList();
                    context.read<ItineraryBloc>().add(
                          ItineraryReordered(tripId: trip.id, items: reordered),
                        );
                  },
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _ItineraryCard(
                      key: ValueKey(item.id),
                      item: item,
                      index: index,
                      onEdit: () {
                        if (item.isPending) {
                          _showPendingMessage(context);
                          return;
                        }
                        _showFormSheet(context, item: item);
                      },
                      onDelete: () {
                        if (item.isPending) {
                          _showPendingMessage(context);
                          return;
                        }
                        _confirmDelete(context, item);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFormSheet(BuildContext context, {ItineraryItemEntity? item}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ItineraryFormSheet(
        item: item,
        onSubmit: (data) {
          if (item == null) {
            context.read<ItineraryBloc>().add(
                  ItineraryItemCreated(
                    tripId: trip.id,
                    title: data.title,
                    notes: data.notes,
                    location: data.location,
                    startTime: data.startTime,
                    endTime: data.endTime,
                    date: data.date,
                  ),
                );
          } else {
            context.read<ItineraryBloc>().add(
                  ItineraryItemUpdated(
                    tripId: trip.id,
                    itemId: item.id,
                    title: data.title,
                    notes: data.notes,
                    location: data.location,
                    startTime: data.startTime,
                    endTime: data.endTime,
                    date: data.date,
                  ),
                );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ItineraryItemEntity item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ItineraryBloc>().add(ItineraryItemDeleted(itemId: item.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPendingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pending sync. Try again after reconnection.')),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final ItineraryItemEntity item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItineraryCard({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle(item);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(item.title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isPending)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Pending', style: TextStyle(fontSize: 11, color: Colors.orange)),
              ),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(ItineraryItemEntity item) {
    final details = <String>[];
    if (item.date != null) {
      details.add('Date: ${item.date!.toIso8601String().split('T').first}');
    }
    if (item.startTime != null || item.endTime != null) {
      final start = item.startTime ?? '--:--';
      final end = item.endTime ?? '--:--';
      details.add('Time: $start - $end');
    }
    if (item.location != null && item.location!.trim().isNotEmpty) {
      details.add('Location: ${item.location}');
    }
    if (item.notes != null && item.notes!.trim().isNotEmpty) {
      details.add(item.notes!);
    }
    return details.join('\n');
  }
}

class ItineraryFormData {
  final String title;
  final String? notes;
  final String? location;
  final String? startTime;
  final String? endTime;
  final DateTime? date;

  const ItineraryFormData({
    required this.title,
    this.notes,
    this.location,
    this.startTime,
    this.endTime,
    this.date,
  });
}

class ItineraryFormSheet extends StatefulWidget {
  final ItineraryItemEntity? item;
  final ValueChanged<ItineraryFormData> onSubmit;

  const ItineraryFormSheet({super.key, this.item, required this.onSubmit});

  @override
  State<ItineraryFormSheet> createState() => _ItineraryFormSheetState();
}

class _ItineraryFormSheetState extends State<ItineraryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _locationController;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _locationController = TextEditingController(text: widget.item?.location ?? '');
    _startTime = _parseTime(widget.item?.startTime);
    _endTime = _parseTime(widget.item?.endTime);
    _date = widget.item?.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
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
            Text(isEditing ? 'Edit item' : 'Add item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Start time',
                    value: _startTime,
                    onSelected: (value) => setState(() => _startTime = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'End time',
                    value: _endTime,
                    onSelected: (value) => setState(() => _endTime = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Date (optional)',
              value: _date,
              onSelected: (value) => setState(() => _date = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Save' : 'Create'),
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
    final startTime = _startTime != null ? _formatTime(_startTime!) : null;
    final endTime = _endTime != null ? _formatTime(_endTime!) : null;

    widget.onSubmit(
      ItineraryFormData(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        date: _date,
      ),
    );
    Navigator.of(context).pop();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onSelected;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = TimeOfDay.now();
        final selected = await showTimePicker(
          context: context,
          initialTime: value ?? now,
        );
        if (selected != null) {
          onSelected(selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value != null ? value!.format(context) : 'Select'),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onSelected;

  const _DateField({
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
