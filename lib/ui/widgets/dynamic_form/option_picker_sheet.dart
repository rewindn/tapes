import 'package:flutter/material.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';

sealed class OptionPickerResult {
  const OptionPickerResult();
}

final class OptionPicked extends OptionPickerResult {
  final String name;

  const OptionPicked(this.name);
}

final class OptionCleared extends OptionPickerResult {
  const OptionCleared();
}

class OptionPickerSheet extends StatefulWidget {
  final String title;
  final List<NotionPropertyOption> options;
  final bool multiSelect;
  final String? selected;
  final List<String> selectedValues;

  const OptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.multiSelect,
    this.selected,
    this.selectedValues = const [],
  });

  static Future<OptionPickerResult?> showSelect(
    BuildContext context, {
    required String title,
    required List<NotionPropertyOption> options,
    String? selected,
  }) {
    return showModalBottomSheet<OptionPickerResult>(
      context: context,
      builder: (_) => OptionPickerSheet(
        title: title,
        options: options,
        multiSelect: false,
        selected: selected,
      ),
    );
  }

  static Future<List<String>?> showMulti(
    BuildContext context, {
    required String title,
    required List<NotionPropertyOption> options,
    List<String> selected = const [],
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      builder: (_) => OptionPickerSheet(
        title: title,
        options: options,
        multiSelect: true,
        selectedValues: selected,
      ),
    );
  }

  @override
  State<OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<OptionPickerSheet> {
  late final Set<String> _selected = {...widget.selectedValues};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(widget.title),
            trailing: widget.multiSelect
                ? TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selected.toList()),
                    child: const Text('Simpan'),
                  )
                : null,
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (!widget.multiSelect)
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: const Text('Kosongkan Pilihan'),
                    onTap: () =>
                        Navigator.of(context).pop(const OptionCleared()),
                  ),
                for (final option in widget.options)
                  if (widget.multiSelect)
                    CheckboxListTile(
                      value: _selected.contains(option.name),
                      title: Text(option.name),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(option.name);
                          } else {
                            _selected.remove(option.name);
                          }
                        });
                      },
                    )
                  else
                    ListTile(
                      title: Text(option.name),
                      trailing: option.name == widget.selected
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () =>
                          Navigator.of(context).pop(OptionPicked(option.name)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
