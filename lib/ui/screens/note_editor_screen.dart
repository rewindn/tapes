import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapes/constants/app_colors.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/viewmodels/dynamic_form_view_model.dart';
import 'package:tapes/ui/theme/app_theme.dart';
import 'package:tapes/ui/widgets/retro_screen_header.dart';
import 'package:uuid/uuid.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final NotionSchemaService? schemaService;
  final String? databaseId;
  final String? databaseName;
  final bool isConnected;
  final bool isReadOnly;
  final Future<Note> Function(Note note)? onSync;
  final ValueChanged<Note>? onOpenNote;
  final VoidCallback? onSaved;
  final VoidCallback? onClose;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.schemaService,
    this.databaseId,
    this.databaseName,
    this.isConnected = true,
    this.isReadOnly = false,
    this.onSync,
    this.onOpenNote,
    this.onSaved,
    this.onClose,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final String _initialTitle;
  late final String _initialContent;
  late final Listenable _dirtyListenable;

  final Map<String, TextEditingController> _fieldControllers = {};
  DynamicFormViewModel? _formViewModel;
  bool _isSubmitting = false;
  bool _forceNewSession = false;

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  bool get _isDirty {
    final vm = _formViewModel;
    if (vm != null) return vm.isDirty;
    return _titleController.text != _initialTitle ||
        _contentController.text != _initialContent;
  }

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.note?.title ?? '';
    _initialContent = _readContent(widget.note);
    _titleController = TextEditingController(text: _initialTitle);
    _contentController = TextEditingController(text: _initialContent);

    final schemaService = widget.schemaService;
    final databaseId = widget.databaseId;
    if (schemaService != null && databaseId != null) {
      final formViewModel = DynamicFormViewModel(
        repository: context.read<NoteRepository>(),
        schemaService: schemaService,
      );
      _formViewModel = formViewModel;
      formViewModel.load(databaseId, note: widget.note).then((_) {
        _applyDateDefaults(formViewModel);
      });
    }

    _dirtyListenable = Listenable.merge([
      _titleController,
      _contentController,
      if (_formViewModel != null) _formViewModel!,
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    _formViewModel?.dispose();
    super.dispose();
  }

  String _readContent(Note? note) {
    if (note == null) return '';
    if (note.content.isNotEmpty) return note.content;
    return note.blocks
        .map((block) => block.text)
        .where((text) => text.isNotEmpty)
        .join('\n');
  }

  void _applyDateDefaults(DynamicFormViewModel vm) {
    if (!mounted) return;
    final schema = vm.schema;
    if (schema == null) return;
    final fallback = widget.note?.createdAt ?? DateTime.now();
    var changed = false;
    for (final property in schema.properties.values) {
      if (property.tapesType != TapesPropertyType.date ||
          !property.isWritable ||
          vm.formValues[property.name] != null) {
        continue;
      }
      vm.updateField(
        property.name,
        DateFormat('yyyy-MM-dd').format(fallback),
        shouldNotify: true,
      );
      changed = true;
    }
    if (changed) vm.markClean();
  }

  Future<void> _pickDate(
    DynamicFormViewModel vm,
    NotionPropertySchema property,
    DateTime initial,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.tapeGold,
              onPrimary: AppColors.textDark,
              onSurface: AppColors.textDark,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.tapeInset,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    vm.updateField(
      property.name,
      DateFormat('yyyy-MM-dd').format(picked),
      shouldNotify: true,
    );
  }

  void _applyAutoTitle(DynamicFormViewModel vm) {
    final titleProperty = vm.schema?.titleProperty;
    if (titleProperty == null) return;
    final date =
        _datePropertyValue(vm) ?? widget.note?.createdAt ?? DateTime.now();
    final day = _dayNames[date.weekday - 1];
    final focus = vm.formValues['Dominant Focus'];
    final focusText = focus is String ? focus.trim() : '';
    vm.updateField(
      titleProperty.name,
      focusText.isEmpty ? day : '$day - $focusText',
      shouldNotify: true,
    );
  }

  DateTime? _datePropertyValue(DynamicFormViewModel vm) {
    final schema = vm.schema;
    if (schema == null) return null;
    for (final property in schema.properties.values) {
      if (property.tapesType != TapesPropertyType.date) continue;
      final value = vm.formValues[property.name];
      if (value is String) return DateTime.tryParse(value);
    }
    return null;
  }

  Note? _findTodayNote() {
    final now = DateTime.now();
    for (final note in context.read<NoteRepository>().getAllNotes()) {
      final date = _noteDate(note);
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return note;
      }
    }
    return null;
  }

  DateTime _noteDate(Note note) {
    final raw = note.properties['Date'];
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return note.createdAt;
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    final repository = context.read<NoteRepository>();

    final vm = _formViewModel;
    if (vm != null) {
      _applyAutoTitle(vm);
      if (!vm.validate()) return;
      setState(() => _isSubmitting = true);
      try {
        final saved = await vm.saveNote(blocks: const []);
        if (saved == null || !mounted) return;

        final sync = widget.onSync;
        if (sync != null) {
          final synced = await sync(saved);
          if (synced.notionPageId != saved.notionPageId) {
            await repository.saveNote(synced);
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sync == null
                  ? 'Catatan berhasil disimpan!'
                  : 'Catatan hari ini berhasil direkam!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _finishSave();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul wajib diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final blocks = [
        TapeBlock(type: BlockType.text, text: _contentController.text),
      ];
      final note = widget.note == null
          ? Note(
              id: const Uuid().v4(),
              title: title,
              blocks: blocks,
              createdAt: DateTime.now(),
            )
          : widget.note!.copyWith(
              title: title,
              blocks: blocks,
              properties: const {},
            );

      await repository.saveNote(note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      _finishSave();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _finishSave() {
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      onSaved();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }
    _finishSave();
  }

  Future<void> _confirmDiscard(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan yang belum disimpan akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    if (discard != true) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final todayNote = widget.note == null && !_forceNewSession
        ? _findTodayNote()
        : null;
    return ListenableBuilder(
      listenable: _dirtyListenable,
      builder: (context, _) => PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: _confirmDiscard,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RetroScreenHeader(title: 'Record Your Day'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.isConnected)
                          _buildDisconnectedPlaceholder()
                        else if (todayNote != null)
                          _buildAlreadyRecorded(todayNote)
                        else if (_formViewModel != null)
                          _buildSchemaCassettes(_formViewModel!)
                        else
                          _buildFallbackCassette(),
                        const SizedBox(height: 140.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedPlaceholder() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Belum Terhubung ke Notion, atur koneksi di Settings',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildAlreadyRecorded(Note note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tapeGold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hari Ini Terekam',
                style: TextStyle(
                  fontFamily: AppTheme.headingFont,
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tapeInset,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Anda sudah merekam hari ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tekan tombol Play untuk melihat detail catatan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: _SavePlayButton(
                  saving: false,
                  onTap: () => widget.onOpenNote?.call(note),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _forceNewSession = true),
            child: const Text(
              'Rekam Ulang / Tambah Sesi Lain',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchemaCassettes(DynamicFormViewModel vm) {
    if (vm.loadState == DynamicFormLoadState.loading ||
        vm.loadState == DynamicFormLoadState.idle) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (vm.loadState == DynamicFormLoadState.error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(vm.errorMessage ?? 'Gagal memuat skema'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final property in vm.visibleProperties)
          if (property.tapesType == TapesPropertyType.date)
            _dateCassette(vm, property)
          else if (property.tapesType != TapesPropertyType.title)
            _schemaCassette(vm, property),
        const SizedBox(height: 8),
        _buildSubmitDeck(),
      ],
    );
  }

  Widget _cassetteShell(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.tapeGold,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.all(14), child: child),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.textDark.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitDeck() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tapeInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tapeGold.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: widget.isReadOnly
            ? _CloseButton(onTap: _close)
            : _SavePlayButton(
                saving: _isSubmitting,
                onTap: _save,
                color: AppColors.tapeGold,
              ),
      ),
    );
  }

  Widget _schemaCassette(
    DynamicFormViewModel vm,
    NotionPropertySchema property,
  ) {
    final isTitle = property.tapesType == TapesPropertyType.title;
    final value = isTitle ? vm.title : vm.formValues[property.name];

    return _cassetteShell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.databaseName ?? 'Tapes',
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              property.name,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.tapeInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _schemaField(vm, property, value),
          ),
          if (vm.errors[property.name] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                vm.errors[property.name]!,
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateCassette(
    DynamicFormViewModel vm,
    NotionPropertySchema property,
  ) {
    final raw = vm.formValues[property.name];
    final date = raw is String ? DateTime.tryParse(raw) : null;

    return _cassetteShell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.databaseName ?? 'Tapes',
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              property.name,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.isReadOnly
                ? null
                : () => _pickDate(vm, property, date ?? DateTime.now()),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tapeInset,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                date == null
                    ? 'Pilih tanggal'
                    : DateFormat('MMMM d, yyyy').format(date),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemaField(
    DynamicFormViewModel vm,
    NotionPropertySchema property,
    Object? value,
  ) {
    final name = property.name;
    switch (property.tapesType) {
      case TapesPropertyType.title:
        return _textField(
          name,
          value,
          hint: 'Title',
          onChanged: (text) => vm.updateField(name, text),
        );
      case TapesPropertyType.number:
        return _textField(
          name,
          value,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (text) => vm.updateField(name, text),
        );
      case TapesPropertyType.richText:
        return _textField(
          name,
          value,
          hint: 'Tape in here ...........',
          multiline: true,
          onChanged: (text) => vm.updateField(name, text),
        );
      case TapesPropertyType.url:
      case TapesPropertyType.email:
      case TapesPropertyType.phone:
        return _textField(
          name,
          value,
          hint: name,
          onChanged: (text) => vm.updateField(name, text),
        );
      case TapesPropertyType.date:
        return _textField(
          name,
          value,
          hint: 'YYYY-MM-DD',
          onChanged: (text) => vm.updateField(name, text),
        );
      case TapesPropertyType.select:
      case TapesPropertyType.status:
        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            for (final option in property.options)
              ChoiceChip(
                label: Text(option.name),
                selected: value == option.name,
                selectedColor: AppColors.tapeGold,
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: value == option.name
                      ? AppColors.white
                      : AppColors.textDark,
                ),
                side: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                visualDensity: VisualDensity.compact,
                onSelected: widget.isReadOnly
                    ? null
                    : (_) =>
                          vm.updateField(name, option.name, shouldNotify: true),
              ),
          ],
        );
      case TapesPropertyType.multiSelect:
        final selected = value is List
            ? value.whereType<String>().toList()
            : <String>[];
        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            for (final option in property.options)
              FilterChip(
                label: Text(option.name),
                selected: selected.contains(option.name),
                selectedColor: AppColors.tapeGold,
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: selected.contains(option.name)
                      ? AppColors.white
                      : AppColors.textDark,
                ),
                side: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                visualDensity: VisualDensity.compact,
                onSelected: widget.isReadOnly
                    ? null
                    : (isSelected) {
                        final next = [...selected];
                        if (isSelected) {
                          next.add(option.name);
                        } else {
                          next.remove(option.name);
                        }
                        vm.updateField(name, next, shouldNotify: true);
                      },
              ),
          ],
        );
      case TapesPropertyType.checkbox:
        final done = value == true;
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegmentButton(
                label: '✕ Belum',
                selected: !done,
                onTap: widget.isReadOnly
                    ? null
                    : () => vm.updateField(name, false, shouldNotify: true),
              ),
              const SizedBox(width: 8),
              _SegmentButton(
                label: '✓ Selesai',
                selected: done,
                selectedColor: AppColors.accentGreen,
                onTap: widget.isReadOnly
                    ? null
                    : () => vm.updateField(name, true, shouldNotify: true),
              ),
            ],
          ),
        );
      case TapesPropertyType.unsupported:
        return const SizedBox.shrink();
    }
  }

  Widget _textField(
    String name,
    Object? value, {
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool multiline = false,
  }) {
    final controller = _controllerFor(name, value is String ? value : '');
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: multiline ? null : 1,
      minLines: multiline ? 3 : null,
      enabled: !widget.isReadOnly,
      readOnly: widget.isReadOnly,
      style: const TextStyle(color: AppColors.textDark, fontSize: 16),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }

  TextEditingController _controllerFor(String name, String text) {
    final existing = _fieldControllers[name];
    if (existing == null) {
      final controller = TextEditingController(text: text);
      _fieldControllers[name] = controller;
      return controller;
    }
    if (existing.text != text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (existing.text == text) return;
        existing.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });
    }
    return existing;
  }

  Widget _buildFallbackCassette() {
    final databaseName = widget.databaseName ?? 'Tapes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cassetteShell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  databaseName,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTheme.headingFont,
                    color: AppColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                maxLines: 1,
                enabled: !widget.isReadOnly,
                readOnly: widget.isReadOnly,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: AppColors.white,
                decoration: const InputDecoration(
                  hintText: 'Title / What problem did you solve?',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 280),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tapeInset,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 10,
                  enabled: !widget.isReadOnly,
                  readOnly: widget.isReadOnly,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tape in here ...........',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildSubmitDeck(),
      ],
    );
  }
}

class _SavePlayButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  final Color color;

  const _SavePlayButton({
    required this.saving,
    required this.onTap,
    this.color = AppColors.actionOrange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: SizedBox(
        width: 96,
        height: 46,
        child: CustomPaint(
          painter: _TrapezoidPainter(color: color),
          child: Center(
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textDark,
                    ),
                  )
                : const Icon(
                    Icons.play_arrow,
                    color: AppColors.textDark,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback? onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    this.selectedColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (selectedColor ?? AppColors.background)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textDark : AppColors.textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const SizedBox(
        width: 120,
        height: 46,
        child: CustomPaint(
          painter: _TrapezoidPainter(color: AppColors.textMuted),
          child: Center(
            child: Text(
              'Tutup',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrapezoidPainter extends CustomPainter {
  final Color color;

  const _TrapezoidPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, 0)
      ..lineTo(size.width * 0.88, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrapezoidPainter oldDelegate) =>
      oldDelegate.color != color;
}
