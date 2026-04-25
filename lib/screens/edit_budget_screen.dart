import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';

class EditBudgetScreen extends StatefulWidget {
  final String token;
  const EditBudgetScreen({super.key, required this.token});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _api = ApiService();
  final _amountCtrl = TextEditingController();
  bool _applyToCurrentMonth = true;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid amount'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.updateUserBalance(
        widget.token,
        newBalance: amount,
        applyToCurrentMonth: _applyToCurrentMonth,
      );
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Budget updated successfully!'),
                backgroundColor: AppColors.success),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['error'] ?? 'Update failed'),
                backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.primaryDark, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter your new monthly budget. You can choose to apply it to the current month too.',
                    style:
                    TextStyle(fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),
            const Text('New Budget Amount',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider)),
              child: Row(children: [
                const Text('EGP ',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        contentPadding: EdgeInsets.zero),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider)),
              child: Row(children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apply to current month',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text("Update this month's budget immediately",
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _applyToCurrentMonth,
                  onChanged: (v) =>
                      setState(() => _applyToCurrentMonth = v),
                  activeColor: AppColors.primary,
                ),
              ]),
            ),
            const SizedBox(height: 40),
            CustomButton(
              label: 'Save Budget',
              isLoading: _loading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}