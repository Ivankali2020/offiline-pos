import 'package:abpos/controllers/cart_controller.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_bottom_action_bar.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SaleDetailsPage extends StatefulWidget {
  const SaleDetailsPage({super.key});

  @override
  State<SaleDetailsPage> createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends State<SaleDetailsPage> {
  final CartController controller = Get.find<CartController>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _invoiceController;
  late TextEditingController _dateController;
  late Worker _invoiceWorker;
  late Worker _saleDateWorker;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: controller.customerName.value,
    );
    _phoneController = TextEditingController(
      text: controller.customerPhone.value,
    );
    _invoiceController = TextEditingController(
      text: controller.invoiceNumber.value,
    );
    _dateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(controller.saleDate.value),
    );

    _nameController.addListener(() {
      controller.customerName.value = _nameController.text;
    });
    _phoneController.addListener(() {
      controller.customerPhone.value = _phoneController.text;
    });

    _invoiceWorker = ever(controller.invoiceNumber, (String val) {
      if (_invoiceController.text != val) {
        _invoiceController.text = val;
      }
    });

    _saleDateWorker = ever(controller.saleDate, (DateTime val) {
      final formatted = DateFormat('dd-MM-yyyy').format(val);
      if (_dateController.text != formatted) {
        _dateController.text = formatted;
      }
    });
  }

  @override
  void dispose() {
    _invoiceWorker.dispose();
    _saleDateWorker.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _invoiceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickSaleDate() async {
    final current = controller.saleDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    controller.saleDate.value = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
      current.second,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'pos_sale'.tr,
      appBar: CustomAppBar(
        title: 'pos_sale'.tr,
        subtitle: 'Enter invoice and customer details before adding items.',
      ),
      bottomNavigationBar: AppBottomActionBar(
        actionLabel: 'next_step'.tr,
        onPressed: () => Get.toNamed(AppRoutes.cart),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: _buildSaleHeaderCard(context),
      ),
    );
  }

  Widget _buildSaleHeaderCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.08),
              theme.colorScheme.primary,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sale details',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review invoice info, sale date, and customer details before checkout.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _buildInvoiceField(dark: true),
          const SizedBox(height: 14),
          _buildDateField(dark: true),
          const SizedBox(height: 14),
          _buildNameField(dark: true),
          const SizedBox(height: 14),
          _buildPhoneField(dark: true),
        ],
      ),
    );
  }

  Widget _buildInvoiceField({bool dark = false}) {
    return _buildCompactFieldTheme(
      dark: dark,
      child: CustomTextField(
        label: 'invoice_no'.tr,
        controller: _invoiceController,
        readOnly: true,
      ),
    );
  }

  Widget _buildDateField({bool dark = false}) {
    return _buildCompactFieldTheme(
      dark: dark,
      child: CustomTextField(
        label: 'date'.tr,
        controller: _dateController,
        readOnly: true,
        onTap: _pickSaleDate,
        suffixIcon: const Icon(LucideIcons.calendar, size: 16),
      ),
    );
  }

  Widget _buildNameField({bool dark = false}) {
    return _buildCompactFieldTheme(
      dark: dark,
      child: CustomTextField(
        label: 'customer_name'.tr,
        controller: _nameController,
      ),
    );
  }

  Widget _buildPhoneField({bool dark = false}) {
    return _buildCompactFieldTheme(
      dark: dark,
      child: CustomTextField(
        label: 'customer_phone'.tr,
        keyboardType: TextInputType.phone,
        controller: _phoneController,
      ),
    );
  }

  Widget _buildCompactFieldTheme({required bool dark, required Widget child}) {
    if (!dark) {
      return child;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
          bodyLarge: const TextStyle(color: Colors.white),
          titleMedium: const TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.14),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: const TextStyle(color: Colors.white),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 1.6),
          ),
        ),
      ),
      child: child,
    );
  }
}
