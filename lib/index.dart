import 'package:tapes/content.dart';
import 'package:tapes/home.dart';
import 'package:tapes/listtape.dart';
import 'package:flutter/material.dart';

class InderPage extends StatefulWidget {
  const InderPage({super.key});

  @override
  State<InderPage> createState() => _InderPageState();
}

class _InderPageState extends State<InderPage> {

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MainContent(),
    const ListTape(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Home page punya background sendiri (striped)
    final bgColor = _selectedIndex == 0 
        ? Colors.transparent 
        : const Color.fromRGBO(255, 245, 207, 1);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: ''),
          NavigationDestination(icon: Icon(Icons.add), label: ''),
          NavigationDestination(icon: Icon(Icons.bookmark), label: ''),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: const Color.fromRGBO(255, 252, 240, 1),
        indicatorColor: const Color.fromARGB(255, 255, 229, 136),
      ),
    );
  }
}