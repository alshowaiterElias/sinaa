import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/projects_provider.dart';

class WorkingHoursEditor extends ConsumerStatefulWidget {
  final Map<String, String>? initialValue;
  final bool isSelectionMode;

  const WorkingHoursEditor({
    super.key,
    this.initialValue,
    this.isSelectionMode = false,
  });

  @override
  ConsumerState<WorkingHoursEditor> createState() => _WorkingHoursEditorState();
}

class _WorkingHoursEditorState extends ConsumerState<WorkingHoursEditor> {
  // Structure: { "monday": "09:00-17:00", ... } or { "monday": "closed" }
  late Map<String, String> _workingHours;
  bool _hasChanges = false;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _workingHours = Map<String, String>.from(widget.initialValue!);
    } else {
      final project = ref.read(myProjectProvider).project;
      // Initialize with existing hours or default to 9-5 for all days
      _workingHours = Map<String, String>.from(
          project?.workingHours?.map((k, v) => MapEntry(k, v.toString())) ??
              {});
    }

    // Ensure all days exist
    for (final day in _days) {
      if (!_workingHours.containsKey(day)) {
        _workingHours[day] = '09:00-17:00';
      }
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (widget.isSelectionMode) {
      navigator.pop(_workingHours);
      return;
    }

    try {
      await ref.read(myProjectProvider.notifier).updateProject({
        'workingHours': _workingHours,
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.tr('project.updateSuccess'))),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _updateDay(String day, String value) {
    setState(() {
      _workingHours[day] = value;
      _hasChanges = true;
    });
  }

  Future<void> _pickTime(String day, bool isStart) async {
    final current = _workingHours[day]!;
    if (current == 'closed') return;

    final parts = current.split('-');
    final timeStr = isStart ? parts[0] : parts[1];
    final timeParts = timeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final newTimeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final newRange =
          isStart ? '$newTimeStr-${parts[1]}' : '${parts[0]}-$newTimeStr';
      _updateDay(day, newRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(myProjectProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('project.workingHours')),
        actions: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _hasChanges ? _save : null,
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _days.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final day = _days[index];
          final value = _workingHours[day]!;
          final isClosed = value == 'closed';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tr('days.$day'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: !isClosed,
                      onChanged: (enabled) {
                        _updateDay(day, enabled ? '09:00-17:00' : 'closed');
                      },
                    ),
                  ],
                ),
                if (!isClosed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(day, true),
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(value.split('-')[0]),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('-'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(day, false),
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(value.split('-')[1]),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    l10n.tr('project.closed'),
                    style: TextStyle(color: AppColors.error),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
