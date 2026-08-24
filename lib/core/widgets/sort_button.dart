import 'package:flutter/material.dart';

enum SortOrder { ascending, descending }

class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.currentOrder,
    required this.onChanged,
  });

  final SortOrder currentOrder;
  final ValueChanged<SortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDesc = currentOrder == SortOrder.descending;

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5C6470),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        onChanged(isDesc ? SortOrder.ascending : SortOrder.descending);
      },
      icon: Icon(
        isDesc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        size: 16,
      ),
      label: Text(isDesc ? 'Newest First' : 'Oldest First'),
    );
  }
}
