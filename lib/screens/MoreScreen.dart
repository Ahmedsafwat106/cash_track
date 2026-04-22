
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_colors.dart';
import 'AddIncomeScreen.dart';
import 'CategoriesScreen.dart';

class MoreScreen extends StatelessWidget {
  final String token;
  const MoreScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Tools'),
            _MenuSection(children: [
              _MenuItem(
                icon: Icons.category_outlined,
                label: 'Manage Categories',
                subtitle: 'Add & manage your expense/income categories',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => CategoriesScreen(token: token))),
              ),
              _MenuItem(
                icon: Icons.add_circle_outline,
                label: 'Add Income',
                subtitle: 'Record a new income entry',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => AddIncomeScreen(token: token))),
              ),
            ]),
            const SizedBox(height: 16),

            _SectionTitle('Support'),
            _MenuSection(children: [
              _MenuItem(
                icon: Icons.help_outline,
                label: 'Help & FAQ',
                subtitle: 'Get answers to common questions',
                onTap: () async {
                  final uri = Uri.parse('https://budgetapptry.runasp.net');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _MenuItem(
                icon: Icons.share_outlined,
                label: 'Share App',
                subtitle: 'Share BudgetApp with friends',
                onTap: () => Share.share(
                    'Check out BudgetApp — the smart way to manage your money!'),
              ),
              _MenuItem(
                icon: Icons.star_outline,
                label: 'Rate the App',
                subtitle: 'Leave us a review',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),

            _SectionTitle('About'),
            _MenuSection(children: [
              _MenuItem(
                icon: Icons.info_outline,
                label: 'App Version',
                subtitle: 'v1.0.0',
                onTap: () {},
                showArrow: false,
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                subtitle: 'Our terms and conditions',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5)),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

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
        children: children
            .asMap()
            .entries
            .map((e) => Column(children: [
          e.value,
          if (e.key < children.length - 1)
            const Divider(
                height: 1, indent: 56, color: AppColors.divider),
        ]))
            .toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: showArrow
          ? const Icon(Icons.chevron_right, color: AppColors.textHint)
          : null,
    );
  }
}