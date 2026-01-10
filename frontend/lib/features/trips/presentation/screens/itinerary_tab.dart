import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
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
                IconButton(
                  onPressed: () => _exportCalendar(context),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
                FilledButton.icon(
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

  Future<void> _exportCalendar(BuildContext context) async {
    final authRepository = context.read<AuthRepositoryImpl>();
    final tokenStorage = context.read<TokenStorage>();
    try {
      await authRepository.getMe();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
      }
      return;
    }
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing access token. Please log in again.')),
      );
      return;
    }

    final base = Uri.parse(ApiConfig.baseUrl);
    final uri = base.replace(
      path: '/api/trips/${trip.id}/calendar',
      queryParameters: {'token': token},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open calendar export.')),
      );
    }
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
    final theme = Theme.of(context);
    final dateLabel = _buildDateLabel(item);
    final timeLabel = _buildTimeLabel(item);
    final location = item.location?.trim();
    final notes = item.notes?.trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 110,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.7),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (item.isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (dateLabel != null)
                        _MetaChip(
                          icon: Icons.calendar_month_outlined,
                          label: dateLabel,
                        ),
                      if (timeLabel != null)
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: timeLabel,
                        ),
                      if (location != null && location.isNotEmpty)
                        _MetaChip(
                          icon: Icons.place_outlined,
                          label: location,
                        ),
                    ],
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      notes,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionIcon(icon: Icons.edit_outlined, onPressed: onEdit),
                      _ActionIcon(icon: Icons.delete_outline, onPressed: onDelete),
                      ReorderableDragStartListener(
                        index: index,
                        child: const _ActionIcon(icon: Icons.drag_handle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _buildDateLabel(ItineraryItemEntity item) {
    if (item.date == null) {
      return null;
    }
    final date = item.date!;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _buildTimeLabel(ItineraryItemEntity item) {
    if (item.startTime == null && item.endTime == null) {
      return null;
    }
    final start = item.startTime ?? '--:--';
    final end = item.endTime ?? '--:--';
    return '$start - $end';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionIcon({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: theme.colorScheme.primary),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      splashRadius: 20,
    );
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
