import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/db_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({Key? key, this.note}) : super(key: key);

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late DateTime _creationDate;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _creationDate = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didLoad && widget.note != null) {
      _didLoad = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.note!.isLocked) {
          _showUnlockDialog();
        } else {
          _titleController.text = widget.note!.title;
          _contentController.text = widget.note!.content;
        }
      });
    }
  }

  void _showUnlockDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter PIN to Unlock'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (pinController.text == widget.note!.pin &&
                    pinController.text.length == 4) {
                  setState(() {
                    _titleController.text = widget.note!.title;
                    _contentController.text = widget.note!.content;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect PIN')),
                  );
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty')),
      );
      return;
    }

    final note = Note(
      id: widget.note?.id,
      title: _titleController.text,
      content: _contentController.text,
      isLocked: widget.note?.isLocked ?? false,
      pin: widget.note?.pin,
    );

    final db = DatabaseService.instance;
    if (widget.note == null) {
      await db.insertNote(note);
    } else {
      await db.updateNote(note);
    }

    Navigator.pop(context);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM h:mm a').format(dateTime);
  }

  int _calculateCharacterCount() {
    return (_titleController.text + _contentController.text).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatDateTime(_creationDate)} | ${_calculateCharacterCount()} characters',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Start typing',
                  border: InputBorder.none,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
