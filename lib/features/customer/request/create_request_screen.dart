import 'package:flutter/material.dart';

import 'add_items_summary_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
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
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Create Request',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Move Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1E23),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us where and when you are moving.',
                style: TextStyle(fontSize: 14, color: Color(0xFF5C6470)),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _pickupController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Pickup Address',
                  hint: 'Enter pickup address',
                  icon: Icons.trip_origin,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pickup address is required.';
                  }

                  if (value.trim().length < 5) {
                    return 'Enter a valid pickup address.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _destinationController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Destination Address',
                  hint: 'Enter destination address',
                  icon: Icons.location_on_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Destination address is required.';
                  }

                  if (value.trim().length < 5) {
                    return 'Enter a valid destination address.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              _SelectionCard(
                label: 'Move Date',
                value: _moveDate == null
                    ? 'Select date'
                    : _formatDate(_moveDate!),
                icon: Icons.calendar_today_outlined,
                onTap: _selectDate,
              ),

              const SizedBox(height: 16),

              _SelectionCard(
                label: 'Start Time',
                value: _startTime == null
                    ? 'Select time'
                    : _startTime!.format(context),
                icon: Icons.access_time_rounded,
                onTap: _selectTime,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _instructionsController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: _inputDecoration(
                  label: 'Instructions (Optional)',
                  hint: 'Parking, elevator, access instructions, etc.',
                  icon: Icons.notes_rounded,
                ),
              ),

              const SizedBox(height: 8),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56A0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _continue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Continue to Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),
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
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E5EA)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E56A0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5C6470),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1E23),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA5B1)),
          ],
        ),
      ),
    );
  }
}
