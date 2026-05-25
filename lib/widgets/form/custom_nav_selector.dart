import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class CustomNavSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isRequired;
  final String? Function(String?)? validator;

  const CustomNavSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.isRequired = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: IgnorePointer(
        child: CustomTextField(
          label: label,
          controller: TextEditingController(text: value),
          isRequired: isRequired,
          validator: validator,
          readOnly: true,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }
}
