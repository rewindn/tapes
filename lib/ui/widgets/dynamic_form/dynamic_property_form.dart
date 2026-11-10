import 'package:flutter/material.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/viewmodels/dynamic_form_view_model.dart';
import 'package:tapes/ui/widgets/dynamic_form/property_field_builder.dart';

class DynamicPropertyForm extends StatefulWidget {
  final DynamicFormViewModel viewModel;
  final bool scrollable;
  final VoidCallback? onChanged;

  const DynamicPropertyForm({
    super.key,
    required this.viewModel,
    this.scrollable = true,
    this.onChanged,
  });

  @override
  State<DynamicPropertyForm> createState() => DynamicPropertyFormState();
}

class DynamicPropertyFormState extends State<DynamicPropertyForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, GlobalKey> _fieldKeys = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> scrollToField(String propertyName) async {
    final fieldContext = _fieldKeys[propertyName]?.currentContext;
    if (fieldContext == null) return;
    await Scrollable.ensureVisible(
      fieldContext,
      duration: const Duration(milliseconds: 250),
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final viewModel = widget.viewModel;

    if (viewModel.loadState == DynamicFormLoadState.idle) {
      return const SizedBox.shrink();
    }
    if (viewModel.loadState == DynamicFormLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.loadState == DynamicFormLoadState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage ?? 'Gagal memuat skema'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: viewModel.refresh,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final properties = viewModel.visibleProperties;
    _dropStaleResources({
      for (final property in properties) property.name,
    });

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (viewModel.loadState == DynamicFormLoadState.stale)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Skema mungkin sudah usang. Muat ulang untuk memperbarui.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (final property in properties) ...[
          KeyedSubtree(
            key: _fieldKeyFor(property.name),
            child: _fieldFor(context, property),
          ),
          const SizedBox(height: 12),
        ],
        if (viewModel.loadState == DynamicFormLoadState.stale)
          OutlinedButton(
            onPressed: viewModel.refresh,
            child: const Text('Muat ulang skema'),
          ),
      ],
    );

    if (!widget.scrollable) return content;

    return PopScope(
      canPop: !viewModel.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
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
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _fieldFor(BuildContext context, NotionPropertySchema property) {
    final viewModel = widget.viewModel;
    final isTitle = property.tapesType == TapesPropertyType.title;
    final value = isTitle
        ? viewModel.title
        : viewModel.formValues[property.name];
    final isText = _isTextType(property.tapesType);

    return PropertyFieldBuilder.build(
      context: context,
      schema: property,
      value: value,
      controller: isText
          ? _controllerFor(property.name, value is String ? value : '')
          : null,
      focusNode: isText ? _focusNodeFor(property.name) : null,
      errorText: viewModel.errors[property.name],
      onChanged: (newValue) {
        viewModel.updateField(
          property.name,
          newValue,
          shouldNotify: !isText,
        );
        widget.onChanged?.call();
      },
    );
  }

  GlobalKey _fieldKeyFor(String name) {
    return _fieldKeys.putIfAbsent(name, GlobalKey.new);
  }

  TextEditingController _controllerFor(String name, String text) {
    final existing = _controllers[name];
    if (existing == null) {
      final controller = TextEditingController(text: text);
      _controllers[name] = controller;
      return controller;
    }
    if (existing.text != text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncController(existing, text);
      });
    }
    return existing;
  }

  FocusNode _focusNodeFor(String name) {
    return _focusNodes.putIfAbsent(name, FocusNode.new);
  }

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _dropStaleResources(Set<String> names) {
    final staleControllers = _controllers.keys
        .where((name) => !names.contains(name))
        .toList();
    for (final name in staleControllers) {
      _controllers.remove(name)?.dispose();
    }

    final staleNodes = _focusNodes.keys
        .where((name) => !names.contains(name))
        .toList();
    for (final name in staleNodes) {
      _focusNodes.remove(name)?.dispose();
    }

    final staleKeys = _fieldKeys.keys
        .where((name) => !names.contains(name))
        .toList();
    for (final name in staleKeys) {
      _fieldKeys.remove(name);
    }
  }

  bool _isTextType(TapesPropertyType type) {
    return switch (type) {
      TapesPropertyType.title ||
      TapesPropertyType.richText ||
      TapesPropertyType.number ||
      TapesPropertyType.url ||
      TapesPropertyType.email ||
      TapesPropertyType.phone => true,
      _ => false,
    };
  }
}
