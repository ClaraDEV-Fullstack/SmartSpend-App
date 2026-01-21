import 'package:flutter/material.dart';
import '../empty_state.dart';

class SearchEmptyState extends StatelessWidget {
  final String query;

  const SearchEmptyState({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No results found',
      subtitle: query.isEmpty
          ? 'Start typing to search transactions.'
          : 'No transactions match "$query".\nTry a different search term.',
    );
  }
}