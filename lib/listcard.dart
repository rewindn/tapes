import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListCard extends StatelessWidget {
  final String note;
  final DateTime date;

  const ListCard({super.key, required this.note, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            DateFormat.yMMMd().format(date),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat.EEEE().format(date),
            style: TextStyle(
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
              style: TextStyle(
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
