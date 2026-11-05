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
    final bgColor = _selectedIndex == 0
        ? const Color(0xFFFFF1DA)
        : const Color(0xFFFFF1DA);

    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildTrapezoidNavBar(context),
    );
  }

  Widget _buildTrapezoidNavBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navHeight = 84.0 + bottomPadding;
    final surroundingBg = _selectedIndex == 0
        ? const Color(0xFF3F3F3F)
        : const Color(0xFFFFF1DA);

    return Container(
      color: surroundingBg,
      height: navHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ClipPath(
            clipper: const TrapezoidClipper(),
            child: Container(
              height: navHeight,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: 84.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavIcon(
                    index: 0,
                    icon: Icons.home,
                  ),
                  const SizedBox(width: 22),
                  _buildAddIcon(index: 1),
                  const SizedBox(width: 22),
                  _buildNavIcon(
                    index: 2,
                    icon: Icons.bookmark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon({required int index, required IconData icon}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  Widget _buildAddIcon({required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFF555555),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TrapezoidClipper extends CustomClipper<Path> {
  const TrapezoidClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final inset = size.width * 0.185;
    path.moveTo(0, size.height);
    path.lineTo(inset, 0);
    path.lineTo(size.width - inset, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}