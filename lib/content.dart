import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapes/note.dart';
import 'package:tapes/note_repository.dart';
import 'package:uuid/uuid.dart';

class MainContent extends StatefulWidget {
  const MainContent({super.key});

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  final date = DateFormat.yMMMd().format(DateTime.now());
  final day = DateFormat.EEEE().format(DateTime.now());

  final noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();

    super.dispose();
  }

  void _addNote() {
    if (noteController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field!')));
      return;
    }

    final note = Note(
      id: const Uuid().v4(),
      content: noteController.text,
      createdAt: DateTime.now(),
    );

    context.read<NoteRepository>().saveNote(note);

    noteController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('User ${note.content} ditambahkan! ✅')));

    // Kembali ke home
  
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 28),
            Text(
              'Record Your Day',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 586),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 24),
                  padding: EdgeInsets.only(left: 20, right: 20, top: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 174, 93, 100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'in $date',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        day,
                        style: TextStyle(
                          color: Colors.white,
                          height: 0.8,
                          fontSize: 32,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Apa 1 masalah yang kamu selesaikan hari ini? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.multiline,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          controller: noteController,
                          style: TextStyle(),
                          decoration: InputDecoration(
                            hintText: 'Tape In Here...',
                            hintStyle: TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Color.fromRGBO(255, 249, 228, 100),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(width: 0),

                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton(
                            onPressed: () {
                              _addNote();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                const Color.fromARGB(255, 255, 229, 136),
                              ),
                              elevation: WidgetStatePropertyAll(2),
                            ),
                            child: Icon(Icons.add),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
