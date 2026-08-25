import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../providers/customer_job_providers.dart';
import '../../../providers/theme_provider.dart';

class AddItemsSummaryScreen extends ConsumerStatefulWidget {
  const AddItemsSummaryScreen({
    required this.pickupAddress,
    required this.destinationAddress,
    required this.moveDate,
    required this.startTime,
    required this.instructions,
    super.key,
  });

  final String pickupAddress;
  final String destinationAddress;
  final DateTime moveDate;
  final String startTime;
  final String instructions;

  @override
  ConsumerState<AddItemsSummaryScreen> createState() =>
      _AddItemsSummaryScreenState();
}

class _AddItemsSummaryScreenState extends ConsumerState<AddItemsSummaryScreen> {
  final _itemNameController = TextEditingController();

  final _quantityController = TextEditingController(text: '1');

  final List<_DraftItem> _items = [];

  bool _submitting = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemNameController.text.trim();

    final quantity = int.tryParse(_quantityController.text.trim());

    if (name.isEmpty) {
      _showMessage('Enter an item name.');
      return;
    }

    if (quantity == null || quantity <= 0) {
      _showMessage('Quantity must be greater than zero.');
      return;
    }

    setState(() {
      _items.add(_DraftItem(name: name, quantity: quantity));

      _itemNameController.clear();

      _quantityController.text = '1';
    });

    FocusScope.of(context).unfocus();
  }

  void _increaseQuantity(int index) {
    setState(() {
      final item = _items[index];

      _items[index] = item.copyWith(quantity: item.quantity + 1);
    });
  }

  void _decreaseQuantity(int index) {
    final item = _items[index];

    if (item.quantity <= 1) {
      return;
    }

    setState(() {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      _showMessage('Add at least one moving item.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submit move request?'),
          content: Text(
            'You are about to submit '
            '${_items.length} item type'
            '${_items.length == 1 ? '' : 's'} '
            'for this move.\n\n'
            'The request will be sent '
            'to MoveCrew for approval.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final result = await ref
          .read(customerJobRepositoryProvider)
          .createMoveRequest(
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            moveDate: widget.moveDate,
            startTime: widget.startTime,
            instructions: widget.instructions,
            items: _items
                .map((item) => {'name': item.name, 'quantity': item.quantity})
                .toList(),
          );

      ref.invalidate(myJobsProvider);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Color(0xFF0F9D58),
            ),
            title: const Text('Request Submitted'),
            content: Text(
              'Your moving request '
              '${result.jobCode} '
              'was submitted successfully.\n\n'
              'Status: REQUESTED',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Could not submit request: $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Items',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Text(
              'Moving Items',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1E23),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add the items that MoveCrew needs to move.',
              style: TextStyle(color: Color(0xFF5C6470)),
            ),
            const SizedBox(height: 20),

            _buildAddItemCard(),

            const SizedBox(height: 20),

            Text(
              'Items (${_items.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            if (_items.isEmpty)
              _buildEmptyItems()
            else
              ...List.generate(_items.length, (index) => _buildItemCard(index)),

            const SizedBox(height: 24),

            const Text(
              'Request Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            _buildSummaryCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tealPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Submitting...' : 'Submit Request'),
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _itemNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g. Bed, Chair, Table',
              prefixIcon: Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(Icons.numbers_rounded),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItems() {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF9AA5B1)),
          SizedBox(height: 8),
          Text(
            'No items added yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed: () => _decreaseQuantity(index),
            icon: const Icon(Icons.remove_circle_outline),
          ),

          Text(
            '${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),

          IconButton(
            onPressed: () => _increaseQuantity(index),
            icon: const Icon(Icons.add_circle_outline),
          ),

          IconButton(
            tooltip: 'Remove item',
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFD64545)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow('Pickup', widget.pickupAddress),
          const Divider(height: 24),
          _summaryRow('Destination', widget.destinationAddress),
          const Divider(height: 24),
          _summaryRow('Move Date', _formatDate(widget.moveDate)),
          const Divider(height: 24),
          _summaryRow('Start Time', _formatTime(widget.startTime)),

          if (widget.instructions.isNotEmpty) ...[
            const Divider(height: 24),
            _summaryRow('Instructions', widget.instructions),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5C6470)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
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

  String _formatTime(String time) {
    final parts = time.split(':');

    if (parts.length < 2) {
      return time;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return time;
    }

    final suffix = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$displayHour:'
        '${minute.toString().padLeft(2, '0')} '
        '$suffix';
  }
}

class _DraftItem {
  const _DraftItem({required this.name, required this.quantity});

  final String name;
  final int quantity;

  _DraftItem copyWith({int? quantity}) {
    return _DraftItem(name: name, quantity: quantity ?? this.quantity);
  }
}
