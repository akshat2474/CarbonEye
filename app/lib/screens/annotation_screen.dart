import 'package:carboneye/models/annotation.dart';
import 'package:carboneye/models/watchlist_item.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/neu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AnnotationScreen extends StatefulWidget {
  final WatchlistItem watchlistItem;

  const AnnotationScreen({
    super.key,
    required this.watchlistItem,
  });

  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addAnnotation() {
    if (_textController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      final newAnnotation = Annotation(
        id: DateTime.now().toIso8601String(),
        text: _textController.text.trim(),
        timestamp: DateTime.now(),
      );
      widget.watchlistItem.annotations.insert(0, newAnnotation);
      _textController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  void _deleteAnnotation(String id) {
    setState(() {
      widget.watchlistItem.annotations.removeWhere((ann) => ann.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Notes for ${widget.watchlistItem.name}'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.watchlistItem.annotations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.watchlistItem.annotations.length,
                    itemBuilder: (context, index) {
                      final annotation = widget.watchlistItem.annotations[index];
                      return NeuCard(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(annotation.text, style: kBodyTextStyle),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jms().format(annotation.timestamp),
                            style: kSecondaryBodyTextStyle.copyWith(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                            onPressed: () => _deleteAnnotation(annotation.id),
                          ),
                        ),
                      ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.5);
                    },
                  ),
          ),
          _buildAnnotationInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_add_outlined, size: 80, color: kSecondaryTextColor),
          const SizedBox(height: 16),
          Text(
            'No Notes Yet',
            style: kSectionTitleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first note below.',
            textAlign: TextAlign.center,
            style: kSecondaryBodyTextStyle,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildAnnotationInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: kBackgroundColor,
        border: Border(top: BorderSide(color: kCardColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: kBodyTextStyle,
              decoration: InputDecoration(
                hintText: 'Add a new note...',
                hintStyle: kSecondaryBodyTextStyle,
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _addAnnotation,
            style: IconButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: kBackgroundColor,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}