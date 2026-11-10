import 'package:flutter/material.dart';
import 'package:tapes/services/notion/sanitizer.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/ui/widgets/dynamic_form/option_picker_sheet.dart';

class PropertyFieldBuilder {
  static Widget build({
    required BuildContext context,
    required NotionPropertySchema schema,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? errorText,
  }) {
    if (!schema.isWritable) return const SizedBox.shrink();

    return switch (schema.tapesType) {
      TapesPropertyType.title => _textField(
        schema: schema,
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        errorText: errorText,
      ),
      TapesPropertyType.richText => _textField(
        schema: schema,
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        errorText: errorText,
        maxLines: null,
        minLines: 3,
      ),
      TapesPropertyType.number => _textField(
        schema: schema,
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        errorText: errorText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      TapesPropertyType.checkbox => _checkbox(
        context: context,
        schema: schema,
        value: value,
        onChanged: onChanged,
        errorText: errorText,
      ),
      TapesPropertyType.select || TapesPropertyType.status => _optionField(
        context: context,
        schema: schema,
        value: value,
        onChanged: onChanged,
        errorText: errorText,
      ),
      TapesPropertyType.multiSelect => _multiSelectField(
        context: context,
        schema: schema,
        value: value,
        onChanged: onChanged,
        errorText: errorText,
      ),
      TapesPropertyType.date => _dateField(
        context: context,
        schema: schema,
        value: value,
        onChanged: onChanged,
        errorText: errorText,
      ),
      TapesPropertyType.url => _textField(
        schema: schema,
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        errorText: errorText,
        keyboardType: TextInputType.url,
      ),
      TapesPropertyType.email => _textField(
        schema: schema,
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        errorText: errorText,
        keyboardType: TextInputType.emailAddress,
      ),
      TapesPropertyType.phone => _textField(
        schema: schema,
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        errorText: errorText,
        keyboardType: TextInputType.phone,
      ),
      TapesPropertyType.unsupported => const SizedBox.shrink(),
    };
  }

  static Widget _textField({
    required NotionPropertySchema schema,
    required ValueChanged<Object?> onChanged,
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String? errorText,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? minLines,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: schema.name,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _checkbox({
    required BuildContext context,
    required NotionPropertySchema schema,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    required String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: value == true,
          title: Text(schema.name),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        _errorText(context, errorText),
      ],
    );
  }

  static Widget _optionField({
    required BuildContext context,
    required NotionPropertySchema schema,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    required String? errorText,
  }) {
    final selected = value is String ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(schema.name),
          subtitle: Text(selected ?? 'Pilih...'),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () async {
            final result = await OptionPickerSheet.showSelect(
              context,
              title: schema.name,
              options: schema.options,
              selected: selected,
            );
            if (result is OptionPicked) onChanged(result.name);
            if (result is OptionCleared) onChanged(null);
          },
        ),
        _errorText(context, errorText),
      ],
    );
  }

  static Widget _multiSelectField({
    required BuildContext context,
    required NotionPropertySchema schema,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    required String? errorText,
  }) {
    final selected = value is List
        ? value.whereType<String>().toList()
        : const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(schema.name),
          subtitle: Text(selected.isEmpty ? 'Pilih...' : selected.join(', ')),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () async {
            final result = await OptionPickerSheet.showMulti(
              context,
              title: schema.name,
              options: schema.options,
              selected: selected,
            );
            if (result != null) onChanged(result);
          },
        ),
        _errorText(context, errorText),
      ],
    );
  }

  static Widget _dateField({
    required BuildContext context,
    required NotionPropertySchema schema,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    required String? errorText,
  }) {
    final date = value is String ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(schema.name),
          subtitle: Text(date ?? 'Pilih tanggal'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final initial = date == null ? null : DateTime.tryParse(date);
            final picked = await showDatePicker(
              context: context,
              initialDate: initial ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onChanged(HivePropertySanitizer.formatDate(picked));
            }
          },
        ),
        _errorText(context, errorText),
      ],
    );
  }

  static Widget _errorText(BuildContext context, String? errorText) {
    if (errorText == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        errorText,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}
