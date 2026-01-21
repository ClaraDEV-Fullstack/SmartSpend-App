import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../features/ai/ai_assistant_sheet.dart';

import '../screens/transactions/transaction_form_screen.dart';

class AiSpeedDial extends StatelessWidget {
  const AiSpeedDial({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Theme.of(context).primaryColor,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.receipt_long),
          label: 'Add Transaction',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionFormScreen(),
              ),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.smart_toy),
          label: 'AI Assistant',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const AiAssistantSheet(),
            );
          },
        ),
      ],
    );
  }
}
