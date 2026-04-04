import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../application/gam3as_provider.dart';
import '../domain/gam3a.dart';

class Gam3aFormScreen extends ConsumerStatefulWidget {
  const Gam3aFormScreen({super.key, required this.existing});
  final Gam3a? existing;

  @override
  ConsumerState<Gam3aFormScreen> createState() => _Gam3aFormScreenState();
}

class _Gam3aFormScreenState extends ConsumerState<Gam3aFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _totalPotController;
  late final TextEditingController _monthlyContributionController;
  late final TextEditingController _payoutMonthController;
  late final TextEditingController _startMonthController;
  late final TextEditingController _endMonthController;
  bool _payoutReceived = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameController = TextEditingController(text: g?.name ?? '');
    _totalPotController = TextEditingController(
      text: g != null ? (g.totalPotPiastres / 100).toStringAsFixed(2) : '',
    );
    _monthlyContributionController = TextEditingController(
      text: g != null
          ? (g.monthlyContributionPiastres / 100).toStringAsFixed(2)
          : '',
    );
    _payoutMonthController = TextEditingController(
      text: g != null ? g.payoutMonth.toString() : '',
    );
    _startMonthController = TextEditingController(
      text: g != null ? g.startMonth.toString() : '',
    );
    _endMonthController = TextEditingController(
      text: g != null ? g.endMonth.toString() : '',
    );
    _payoutReceived = g?.payoutReceived ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalPotController.dispose();
    _monthlyContributionController.dispose();
    _payoutMonthController.dispose();
    _startMonthController.dispose();
    _endMonthController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.textSecondary),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.blue),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.negative),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.negative),
      ),
    );
  }

  String? _requiredString(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length > 100) return 'Max 100 characters';
    return null;
  }

  String? _positiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be greater than 0';
    return null;
  }

  String? _month(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a whole number';
    if (n < 1 || n > 12) return 'Must be 1–12';
    return null;
  }

  String? _endMonthValidator(String? value) {
    final base = _month(value);
    if (base != null) return base;
    final start = int.tryParse(_startMonthController.text.trim());
    final end = int.tryParse(value!.trim());
    if (start != null && end != null && end < start) {
      return 'End month must be ≥ start month';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final gam3a = Gam3a(
      id: existing?.id ?? 0,
      name: _nameController.text.trim(),
      totalPotPiastres:
          (double.parse(_totalPotController.text.trim()) * 100).round(),
      monthlyContributionPiastres:
          (double.parse(_monthlyContributionController.text.trim()) * 100)
              .round(),
      payoutMonth: int.parse(_payoutMonthController.text.trim()),
      startMonth: int.parse(_startMonthController.text.trim()),
      endMonth: int.parse(_endMonthController.text.trim()),
      payoutReceived: _payoutReceived,
      active: existing?.active ?? true,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEdit) {
        await ref.read(gamAasNotifierProvider.notifier).edit(gam3a);
      } else {
        await ref.read(gamAasNotifierProvider.notifier).add(gam3a);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _isEdit ? 'Edit Gam3a' : 'Add Gam3a',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Name'),
                validator: _requiredString,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalPotController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Total Pot (EGP)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _positiveDouble,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlyContributionController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Monthly Contribution (EGP)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _positiveDouble,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _payoutMonthController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Payout Month (1–12)'),
                keyboardType: TextInputType.number,
                validator: _month,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startMonthController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Start Month (1–12)'),
                keyboardType: TextInputType.number,
                validator: _month,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endMonthController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('End Month (1–12)'),
                keyboardType: TextInputType.number,
                validator: _endMonthValidator,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Payout Received',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                value: _payoutReceived,
                activeThumbColor: AppColors.positive,
                onChanged: (v) => setState(() => _payoutReceived = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
