
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_service.dart';
import '../core/jwt_helper.dart';
import '../utils/app_colors.dart';
import '../widgets/loading_indicator.dart';

class AccountInfoScreen extends StatefulWidget {
  final String token;
  const AccountInfoScreen({super.key, required this.token});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  bool _loading = true;
  double _totalBalance = 0;
  double _totalExpenses = 0;
  double _remainingBudget = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService().getUserCurrentData(widget.token);
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          _totalBalance = (data['totalBalance'] as num?)?.toDouble() ?? 0;
          _totalExpenses = (data['totalExpenses'] as num?)?.toDouble() ?? 0;
          _remainingBudget = (data['remainigBudget'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = JwtHelper.getName(widget.token);
    final email = JwtHelper.getEmail(widget.token);
    final role = JwtHelper.getRole(widget.token);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(role,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Financial Overview',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    'EGP ${NumberFormat('#,##0.00').format(_totalBalance)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                        label: 'Expenses',
                        value: 'EGP ${NumberFormat('#,##0').format(_totalExpenses)}',
                        icon: Icons.arrow_upward,
                        iconColor: Colors.redAccent,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'Remaining',
                        value: 'EGP ${NumberFormat('#,##0').format(_remainingBudget)}',
                        icon: Icons.savings_outlined,
                        iconColor: Colors.greenAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _InfoCard(items: [
              _InfoItem(
                  icon: Icons.person_outline, label: 'Full Name', value: name),
              _InfoItem(
                  icon: Icons.email_outlined, label: 'Email', value: email),
              _InfoItem(
                  icon: Icons.verified_user_outlined, label: 'Role', value: role),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatChip(
      {required this.label,
        required this.value,
        required this.icon,
        required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Column(
          children: [
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(e.value.icon,
                    size: 18, color: AppColors.primary),
              ),
              title: Text(e.value.label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              subtitle: Text(e.value.value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
            if (e.key < items.length - 1)
              const Divider(
                  height: 1, indent: 56, color: AppColors.divider),
          ],
        ))
            .toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}