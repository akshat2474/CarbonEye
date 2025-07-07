import 'package:flutter/material.dart';
import 'package:carboneye/models/watchlist_item.dart';
import 'package:carboneye/models/annotation.dart';
import 'package:carboneye/utils/constants.dart';

class AnnotationScreen extends StatefulWidget {
  final WatchlistItem watchlistItem;

  const AnnotationScreen({super.key, required this.watchlistItem});

  @override
  _AnnotationScreenState createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  final TextEditingController _textController = TextEditingController();
  late List<Annotation> _annotations;

  @override
  void initState() {
    super.initState();
    _annotations = List.from(widget.watchlistItem.annotations);
  }

  void _addAnnotation() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _annotations.insert(
          0,
          Annotation(
            text: _textController.text,
            timestamp: DateTime.now(),
          ),
        );
        _textController.clear();
      });
    }
  }

  void _deleteAnnotation(Annotation annotation) {
    setState(() {
      _annotations.remove(annotation);
    });
  }

  Future<void> _showDeleteConfirmationDialog(Annotation annotation) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text('Delete Annotation?', style: kAppTitleStyle.copyWith(fontSize: 20)),
          content: Text(
            'Are you sure you want to permanently delete this note?',
            style: kSecondaryBodyTextStyle,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: kSecondaryBodyTextStyle),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () {
                _deleteAnnotation(annotation);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _annotations);
        return false;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: Text(widget.watchlistItem.name, style: kAppTitleStyle),
          backgroundColor: kBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: kWhiteColor),
            onPressed: () {
              Navigator.pop(context, _annotations);
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16.0),
                itemCount: _annotations.length,
                itemBuilder: (context, index) {
                  final annotation = _annotations[index];
                  return _buildAnnotationCard(annotation);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationCard(Annotation annotation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0, right: 8.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(annotation.text, style: kBodyTextStyle),
                const SizedBox(height: 8),
                Text(
                  '${annotation.timestamp.day}/${annotation.timestamp.month}/${annotation.timestamp.year}',
                  style: kSecondaryBodyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: kSecondaryTextColor.withOpacity(0.7)),
            onPressed: () {
              _showDeleteConfirmationDialog(annotation);
            },
            tooltip: 'Delete Annotation',
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: kCardColor,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: kBodyTextStyle,
                decoration: InputDecoration(
                  hintText: "Add a note...",
                  hintStyle: kSecondaryBodyTextStyle,
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: kAccentColor),
              onPressed: _addAnnotation,
            ),
          ],
        ),
      ),
    );
  }
}
