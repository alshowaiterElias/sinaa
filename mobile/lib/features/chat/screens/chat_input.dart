import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Chat input widget with text field and send button
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<bool> onTypingChanged;
  final bool isSending;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTypingChanged,
    this.isSending = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      widget.onTypingChanged(hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button (optional)
          // IconButton(
          //   icon: const Icon(Icons.attach_file_rounded),
          //   onPressed: () {},
          //   color: AppColors.textSecondary,
          // ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  if (_hasText) widget.onSend();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _hasText ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _hasText && !widget.isSending ? widget.onSend : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: widget.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color:
                              _hasText ? Colors.white : AppColors.textTertiary,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
