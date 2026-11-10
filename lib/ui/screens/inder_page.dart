import 'package:tapes/ui/screens/home_page.dart';
import 'package:tapes/ui/widgets/list_tape.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/viewmodels/notion_settings_controller.dart';
import 'package:tapes/ui/screens/note_editor_screen.dart';
import 'package:tapes/ui/screens/settings_screen.dart';
import 'package:tapes/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InderPage extends StatefulWidget {
  final Future<Note> Function(Note note)? onSyncNote;

  const InderPage({super.key, this.onSyncNote});

  @override
  State<InderPage> createState() => _InderPageState();
}

class _InderPageState extends State<InderPage> {

  int _selectedIndex = 0;
  Note? _editingNote;
  bool _readOnly = false;

  void _onNoteTap(Note note) {
    setState(() {
      _editingNote = note;
      _readOnly = true;
      _selectedIndex = 1;
    });
  }

  void _onSaved() {
    setState(() {
      _editingNote = null;
      _readOnly = false;
      _selectedIndex = 0;
    });
  }

  void _onClosed() {
    setState(() {
      _editingNote = null;
      _readOnly = false;
      _selectedIndex = 2;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 1 && _selectedIndex != 1) {
        _editingNote = null;
        _readOnly = false;
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<NotionSettingsController>();
    final pages = [
      const HomePage(),
      NoteEditorScreen(
        key: ValueKey(
          '${_editingNote?.id ?? 'new-note'}:'
          '${settings.databaseId}:${settings.isConnected}:$_readOnly',
        ),
        note: _editingNote,
        schemaService: settings.schemaService,
        databaseId: settings.isConfigured ? settings.databaseId : null,
        databaseName: settings.databaseName,
        isConnected: settings.isConnected,
        isReadOnly: _readOnly,
        onSync: widget.onSyncNote ?? settings.syncNote,
        onOpenNote: _onNoteTap,
        onSaved: _onSaved,
        onClose: _onClosed,
      ),
      ListTape(
        onNoteTap: _onNoteTap,
        isConnected: settings.isConnected,
        databaseName: settings.databaseName,
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: false,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _buildTrapezoidNavBar(context),
    );
  }

  Widget _buildTrapezoidNavBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navHeight = 84.0 + bottomPadding;
    final surroundingBg = _selectedIndex == 0
        ? AppColors.textDark
        : AppColors.background;

    return Container(
      color: surroundingBg,
      height: navHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomPadding,
            child: Container(color: AppColors.white),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: const TrapezoidClipper(),
              child: Container(color: AppColors.white),
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
                  _buildNavIcon(index: 1, icon: Icons.add_circle),
                  const SizedBox(width: 22),
                  _buildNavIcon(
                    index: 2,
                    icon: Icons.bookmark,
                  ),
                  const SizedBox(width: 22),
                  _buildNavIcon(
                    index: 3,
                    icon: Icons.settings,
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
            color: isSelected ? AppColors.textDark : AppColors.textMuted,
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