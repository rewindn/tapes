import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tapes/listcard.dart';
import 'package:tapes/note.dart';

class ListTape extends StatefulWidget {
  const ListTape({super.key});

  @override
  State<ListTape> createState() => _ListTapeState();
}

class _ListTapeState extends State<ListTape> {
  late Box notebox;

  @override
  void initState() {
    super.initState();
    notebox = Hive.box('notebox');
  }

  List<Note> getNotes() {
    return notebox.values
        .map((data) => Note.fromMap(Map<String, dynamic>.from(data)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final notes = getNotes();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 101),
          Text(
            'Recorded Tape',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'there is no note',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                   itemCount: notes.length,
                    padding: EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final  note = notes[index];
                    
                    return  ListCard(note: note.note,date: note.createdAt,);
                       
                    
                  }
                  ),
          ),
        ],
      ),
    );
  }
}
