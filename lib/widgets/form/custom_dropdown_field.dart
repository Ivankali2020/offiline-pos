import 'package:flutter/material.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final bool isRequired;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isDense;
  final Widget? hint;

  const CustomDropdownField({
    super.key,
    this.value,
    required this.label,
    required this.items,
    this.onChanged,
    this.isRequired = false,
    this.validator,
    this.isDense = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isDense: isDense,
      hint: hint,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
