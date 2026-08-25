import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../providers/theme_provider.dart';
import 'add_items_summary_screen.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _pickupController = TextEditingController();

  final _destinationController = TextEditingController();

  final _instructionsController = TextEditingController();

  DateTime? _moveDate;
  TimeOfDay? _startTime;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _moveDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _moveDate = selected;
    });
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _startTime = selected;
    });
  }

  void _continue() {
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      return;
    }

    if (_moveDate == null) {
      _showMessage('Please select a move date.');
      return;
    }

    if (_startTime == null) {
      _showMessage('Please select a start time.');
      return;
    }

    final pickup = _pickupController.text.trim();

    final destination = _destinationController.text.trim();

    if (pickup.toLowerCase() == destination.toLowerCase()) {
      _showMessage('Pickup and destination addresses must be different.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddItemsSummaryScreen(
          pickupAddress: pickup,
          destinationAddress: destination,
          moveDate: _moveDate!,
          startTime: _databaseTime(_startTime!),
          instructions: _instructionsController.text.trim(),
        ),
      ),
    );
  }

  String _databaseTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.crimsonRed));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Request', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 12),
              Text(
                'MOVE DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).hintColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s plan your move.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _pickupController,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontWeight: FontWeight.w600),
                decoration: _inputDecoration(
                  label: 'Pickup Address',
                  hint: 'Street, City, Zip',
                  icon: Icons.trip_origin_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (value.trim().length < 5) return 'Too short';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _destinationController,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontWeight: FontWeight.w600),
                decoration: _inputDecoration(
                  label: 'Destination Address',
                  hint: 'Street, City, Zip',
                  icon: Icons.location_on_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (value.trim().length < 5) return 'Too short';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _SelectionItem(
                      label: 'DATE',
                      value: _moveDate == null ? 'Select' : _formatDate(_moveDate!),
                      icon: Icons.calendar_today_rounded,
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SelectionItem(
                      label: 'TIME',
                      value: _startTime == null ? 'Select' : _startTime!.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _instructionsController,
                minLines: 3,
                maxLines: 4,
                maxLength: 500,
                decoration: _inputDecoration(
                  label: 'Special Instructions',
                  hint: 'Elevator access, narrow stairs, etc.',
                  icon: Icons.notes_rounded,
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text('CONTINUE TO ITEMS'),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.tealPrimary),
      contentPadding: const EdgeInsets.all(20),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SelectionItem extends StatelessWidget {
  const _SelectionItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tealPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).hintColor)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
