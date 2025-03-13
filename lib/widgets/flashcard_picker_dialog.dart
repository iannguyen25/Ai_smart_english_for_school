import 'package:base_flutter_framework/models/flashcard.dart';
import 'package:flutter/material.dart';

class FlashcardPickerDialog extends StatefulWidget {
  final List<Flashcard> flashcards;

  const FlashcardPickerDialog({
    Key? key,
    required this.flashcards,
  }) : super(key: key);

  @override
  _FlashcardPickerDialogState createState() => _FlashcardPickerDialogState();
}

class _FlashcardPickerDialogState extends State<FlashcardPickerDialog> {
  final Set<Flashcard> _selectedFlashcards = {};

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return AlertDialog(
        title: const Text('Chọn bộ thẻ'),
        content: const Center(
          child: Text('Bạn chưa có bộ thẻ nào'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Chọn bộ thẻ'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.flashcards.length,
          itemBuilder: (context, index) {
            final flashcard = widget.flashcards[index];
            return CheckboxListTile(
              title: Text(flashcard.title),
              subtitle: Text(
                '${flashcard.items?.length ?? 0} từ vựng',
                style: TextStyle(color: Colors.grey[600]),
              ),
              value: _selectedFlashcards.contains(flashcard),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedFlashcards.add(flashcard);
                  } else {
                    _selectedFlashcards.remove(flashcard);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: _selectedFlashcards.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedFlashcards.toList()),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
