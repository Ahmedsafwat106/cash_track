
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_colors.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  String _selected = 'EGP';

  static const _currencies = [
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'ج.م', 'flag': '🇪🇬'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'ر.س', 'flag': '🇸🇦'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ', 'flag': '🇦🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selected = prefs.getString('currency') ?? 'EGP');
  }

  Future<void> _select(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', code);
    setState(() => _selected = code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Currency changed to $code'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Default Currency'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _currencies.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) {
          final c = _currencies[i];
          final isSelected = _selected == c['code'];
          return ListTile(
            tileColor: AppColors.surface,
            shape: i == 0
                ? const RoundedRectangleBorder(
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)))
                : i == _currencies.length - 1
                ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16)))
                : null,
            leading: Text(c['flag']!, style: const TextStyle(fontSize: 28)),
            title: Text(c['name']!,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text('${c['code']} • ${c['symbol']}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () => _select(c['code']!),
          );
        },
      ),
    );
  }
}