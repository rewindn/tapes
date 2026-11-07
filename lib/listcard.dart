import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListCard extends StatelessWidget {
  final String note;
  final DateTime date;

  const ListCard({super.key, required this.note, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 174, 93, 100),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat.yMMMd().format(date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat.EEEE().format(date),
            style: const TextStyle(
              color: Colors.white,
              height: 0.8,
              fontSize: 32,
              fontFamily: 'inter',
              fontWeight: FontWeight.bold,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              note,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'inter',
                // fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
