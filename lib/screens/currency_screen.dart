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
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _allCurrencies = [
    {'code': 'EGP', 'name': 'Egyptian Pound',       'symbol': 'ج.م',  'flag': '🇪🇬'},
    {'code': 'USD', 'name': 'US Dollar',             'symbol': '\$',   'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro',                  'symbol': '€',    'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound',         'symbol': '£',    'flag': '🇬🇧'},
    {'code': 'SAR', 'name': 'Saudi Riyal',           'symbol': 'ر.س', 'flag': '🇸🇦'},
    {'code': 'AED', 'name': 'UAE Dirham',            'symbol': 'د.إ', 'flag': '🇦🇪'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar',         'symbol': 'د.ك', 'flag': '🇰🇼'},
    {'code': 'QAR', 'name': 'Qatari Riyal',          'symbol': 'ر.ق', 'flag': '🇶🇦'},
    {'code': 'BHD', 'name': 'Bahraini Dinar',        'symbol': 'د.ب', 'flag': '🇧🇭'},
    {'code': 'OMR', 'name': 'Omani Rial',            'symbol': 'ر.ع', 'flag': '🇴🇲'},
    {'code': 'JOD', 'name': 'Jordanian Dinar',       'symbol': 'د.ا', 'flag': '🇯🇴'},
    {'code': 'LBP', 'name': 'Lebanese Pound',        'symbol': 'ل.ل', 'flag': '🇱🇧'},
    {'code': 'TRY', 'name': 'Turkish Lira',          'symbol': '₺',   'flag': '🇹🇷'},
    {'code': 'CAD', 'name': 'Canadian Dollar',       'symbol': 'CA\$','flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'Australian Dollar',     'symbol': 'A\$', 'flag': '🇦🇺'},
    {'code': 'CHF', 'name': 'Swiss Franc',           'symbol': 'Fr',  'flag': '🇨🇭'},
    {'code': 'JPY', 'name': 'Japanese Yen',          'symbol': '¥',   'flag': '🇯🇵'},
    {'code': 'CNY', 'name': 'Chinese Yuan',          'symbol': '¥',   'flag': '🇨🇳'},
    {'code': 'INR', 'name': 'Indian Rupee',          'symbol': '₹',   'flag': '🇮🇳'},
    {'code': 'NGN', 'name': 'Nigerian Naira',        'symbol': '₦',   'flag': '🇳🇬'},
    {'code': 'ZAR', 'name': 'South African Rand',    'symbol': 'R',   'flag': '🇿🇦'},
    {'code': 'MAD', 'name': 'Moroccan Dirham',       'symbol': 'د.م', 'flag': '🇲🇦'},
    {'code': 'TND', 'name': 'Tunisian Dinar',        'symbol': 'د.ت', 'flag': '🇹🇳'},
    {'code': 'DZD', 'name': 'Algerian Dinar',        'symbol': 'د.ج', 'flag': '🇩🇿'},
    {'code': 'SDG', 'name': 'Sudanese Pound',        'symbol': 'ج.س', 'flag': '🇸🇩'},
    {'code': 'IQD', 'name': 'Iraqi Dinar',           'symbol': 'ع.د', 'flag': '🇮🇶'},
    {'code': 'SYP', 'name': 'Syrian Pound',          'symbol': 'ل.س', 'flag': '🇸🇾'},
    {'code': 'YER', 'name': 'Yemeni Rial',           'symbol': '﷼',  'flag': '🇾🇪'},
    {'code': 'LYD', 'name': 'Libyan Dinar',          'symbol': 'ل.د', 'flag': '🇱🇾'},
    {'code': 'MXN', 'name': 'Mexican Peso',          'symbol': 'MX\$','flag': '🇲🇽'},
    {'code': 'BRL', 'name': 'Brazilian Real',        'symbol': 'R\$', 'flag': '🇧🇷'},
    {'code': 'KRW', 'name': 'South Korean Won',      'symbol': '₩',   'flag': '🇰🇷'},
    {'code': 'SGD', 'name': 'Singapore Dollar',      'symbol': 'S\$', 'flag': '🇸🇬'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar',      'symbol': 'HK\$','flag': '🇭🇰'},
    {'code': 'SEK', 'name': 'Swedish Krona',         'symbol': 'kr',  'flag': '🇸🇪'},
    {'code': 'NOK', 'name': 'Norwegian Krone',       'symbol': 'kr',  'flag': '🇳🇴'},
    {'code': 'DKK', 'name': 'Danish Krone',          'symbol': 'kr',  'flag': '🇩🇰'},
    {'code': 'PKR', 'name': 'Pakistani Rupee',       'symbol': '₨',   'flag': '🇵🇰'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka',      'symbol': '৳',   'flag': '🇧🇩'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah',     'symbol': 'Rp',  'flag': '🇮🇩'},
  ];

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return _allCurrencies.cast();
    final q = _query.toLowerCase();
    return _allCurrencies
        .where((c) =>
    c['name']!.toLowerCase().contains(q) ||
        c['code']!.toLowerCase().contains(q))
        .toList()
        .cast();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Default Currency'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search currency...',
                  hintStyle: const TextStyle(
                      color: AppColors.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textHint, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textHint, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      })
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final c = list[i];
                final isSelected = _selected == c['code'];
                return ListTile(
                  tileColor: AppColors.surface,
                  shape: i == 0
                      ? const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16)))
                      : i == list.length - 1
                      ? const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16)))
                      : null,
                  leading: Text(c['flag']!,
                      style: const TextStyle(fontSize: 26)),
                  title: Text(c['name']!,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('${c['code']} • ${c['symbol']}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                      color: AppColors.primary)
                      : null,
                  onTap: () => _select(c['code']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}