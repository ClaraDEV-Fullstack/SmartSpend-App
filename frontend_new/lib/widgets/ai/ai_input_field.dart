// lib/widgets/ai/ai_input_field.dart

import 'package:flutter/material.dart';

class AiInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;
  final List<String> suggestions;

  const AiInputField({
    super.key,
    required this.onSend,
    this.isLoading = false,
    this.suggestions = const [],
  });

  @override
  State<AiInputField> createState() => _AiInputFieldState();
}

class _AiInputFieldState extends State<AiInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _controller.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
      setState(() => _showSuggestions = false);
    }
  }

  void _handleSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    setState(() => _showSuggestions = false);
    _handleSend();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Suggestions
        if (_showSuggestions && widget.suggestions.isNotEmpty)
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      widget.suggestions[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _handleSuggestionTap(widget.suggestions[index]),
                    backgroundColor: Colors.grey.shade100,
                  ),
                );
              },
            ),
          ),

        // Input field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _showSuggestions = value.isEmpty && _focusNode.hasFocus;
                      });
                    },
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: widget.isLoading ? null : _handleSend,
                    icon: widget.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}