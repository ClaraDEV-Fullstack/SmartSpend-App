import 'package:flutter/material.dart';
import 'ai_bottom_sheet.dart';

class AiFab extends StatelessWidget {
  const AiFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const AiBottomSheet(),
        );
      },
      child: const Icon(Icons.auto_awesome),
    );
  }
}
