import 'package:carboneye/models/annotation.dart';
import 'package:carboneye/models/watchlist_item.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Notes for ${widget.watchlistItem.name}'),
        backgroundColor: Colors.grey[850],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.watchlistItem.annotations.isEmpty
                ? const Center(
                    child: Text(
                      'No annotations yet. Add one below.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: widget.watchlistItem.annotations.length,
                    itemBuilder: (context, index) {
                      final annotation = widget.watchlistItem.annotations[index];
                      return Card(
                        color: Colors.grey[800],
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                        child: ListTile(
                          title: Text(annotation.text, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jms().format(annotation.timestamp),
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                            onPressed: () => _deleteAnnotation(annotation.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildAnnotationInput(),
        ],
      ),
    );
  }

  Widget _buildAnnotationInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a new note...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _addAnnotation,
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
