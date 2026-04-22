
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/jwt_helper.dart';
import '../utils/app_colors.dart';
import '../utils/locale_provider.dart';
import '../widgets/custom_button.dart';
import 'AddIncomeScreen.dart';
import 'CategoriesScreen.dart';
import 'Change password screen.dart';
import 'account_info_screen.dart';
import 'biometric_screen.dart';
import 'currency_screen.dart';
import 'data_export_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showSettings = false;
  bool _emailNotif = true;
  bool _inAppNotif = true;
  bool _budgetAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_showSettings ? 'Settings' : 'Profile & Account'),
        leading: _showSettings
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => setState(() => _showSettings = false),
        )
            : null,
      ),
      body: _showSettings
          ? _SettingsView(
        token: widget.token,
        emailNotif: _emailNotif,
        inAppNotif: _inAppNotif,
        budgetAlerts: _budgetAlerts,
        onEmailToggle: (v) => setState(() => _emailNotif = v),
        onInAppToggle: (v) => setState(() => _inAppNotif = v),
        onBudgetToggle: (v) => setState(() => _budgetAlerts = v),
      )
          : _ProfileView(
        token: widget.token,
        onSettingsTap: () => setState(() => _showSettings = true),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final String token;
  final VoidCallback onSettingsTap;
  const _ProfileView({required this.token, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final name = JwtHelper.getName(token);
    final email = JwtHelper.getEmail(token);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Account Balance',
            color: AppColors.primaryLight,
            textColor: AppColors.primaryDark,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => AccountInfoScreen(token: token))),
          ),
          const SizedBox(height: 24),
          _MenuSection(children: [
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Account Info',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => AccountInfoScreen(token: token))),
            ),
            _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: onSettingsTap),
            _MenuItem(
              icon: Icons.devices_outlined,
              label: 'Linked Devices',
              onTap: () => _showLinkedDevices(context),
            ),
          ]),
          const SizedBox(height: 12),
          _MenuSection(children: [
            _MenuItem(
              icon: Icons.category_outlined,
              label: 'Manage Categories',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => CategoriesScreen(token: token))),
            ),
            _MenuItem(
              icon: Icons.add_circle_outline,
              label: 'Add Income',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => AddIncomeScreen(token: token))),
            ),
          ]),
          const SizedBox(height: 12),
          _MenuSection(children: [
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              iconColor: AppColors.error,
              textColor: AppColors.error,
              onTap: () => _confirmLogout(context),
              showArrow: false,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLinkedDevices(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Linked Devices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _DeviceTile(
              icon: Icons.phone_android,
              name: 'This Device',
              detail: 'Android • Active now',
              isActive: true,
            ),
            const Divider(color: AppColors.divider),
            _DeviceTile(
              icon: Icons.laptop_outlined,
              name: 'Web Browser',
              detail: 'Last seen 2 hours ago',
              isActive: false,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign Out All Other Devices'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();

              await prefs.setBool('logged_out', true);

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                );
              }
            },
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  final String token;
  final bool emailNotif;
  final bool inAppNotif;
  final bool budgetAlerts;
  final ValueChanged<bool> onEmailToggle;
  final ValueChanged<bool> onInAppToggle;
  final ValueChanged<bool> onBudgetToggle;

  const _SettingsView({
    required this.token,
    required this.emailNotif,
    required this.inAppNotif,
    required this.budgetAlerts,
    required this.onEmailToggle,
    required this.onInAppToggle,
    required this.onBudgetToggle,
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingSectionTitle(title: 'Notifications'),
          _MenuSection(children: [
            _SwitchMenuItem(
                icon: Icons.email_outlined,
                label: 'Email',
                value: emailNotif,
                onChanged: onEmailToggle),
            _SwitchMenuItem(
                icon: Icons.notifications_outlined,
                label: 'In-App',
                value: inAppNotif,
                onChanged: onInAppToggle),
            _SwitchMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Budget Alerts (80%)',
                value: budgetAlerts,
                onChanged: onBudgetToggle),
          ]),
          const SizedBox(height: 16),

          _SettingSectionTitle(title: 'General'),
          _MenuSection(children: [
            _MenuItem(
              icon: Icons.currency_exchange_outlined,
              label: 'Default Currency',
              trailing: FutureBuilder<String>(
                future: _getCurrency(),
                builder: (_, snap) => Text(
                  snap.data ?? 'EGP',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CurrencyScreen())),
            ),

            _MenuItem(
              icon: Icons.language_outlined,
              label: 'Language',
              trailing: Text(
                isArabic ? 'عربي' : 'English',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              onTap: () => _showLanguageDialog(context, localeProvider),
            ),

            _MenuItem(
              icon: Icons.repeat_outlined,
              label: 'Recurring Expenses',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const RecurringExpensesScreen())),
            ),

            _MenuItem(
              icon: Icons.download_outlined,
              label: 'Data Export',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ExportChip(label: 'CSV'),
                  const SizedBox(width: 6),
                  _ExportChip(label: 'JSON'),
                ],
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => DataExportScreen(token: token))),
            ),
          ]),
          const SizedBox(height: 16),

          _SettingSectionTitle(title: 'Security'),
          _MenuSection(children: [
            _MenuItem(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => ChangePasswordScreen(token: token))),
            ),
            _MenuItem(
              icon: Icons.fingerprint_outlined,
              label: 'Biometric',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BiometricScreen())),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<String> _getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? 'EGP';
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
              const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: provider.locale.languageCode == 'en'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
              const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: const Text('عربي'),
              trailing: provider.locale.languageCode == 'ar'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                provider.setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.repeat_outlined,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Recurring Expenses',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Set up automatic reminders for your regular expenses like rent, subscriptions, and utilities.',
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        color: AppColors.primaryDark),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Coming soon — this feature will be available in the next update.',
                        style: TextStyle(
                            color: AppColors.primaryDark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String detail;
  final bool isActive;
  const _DeviceTile(
      {required this.icon,
        required this.name,
        required this.detail,
        required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isActive ? AppColors.success : AppColors.textHint)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isActive ? AppColors.success : AppColors.textHint),
      ),
      title: Text(name,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(detail,
          style:
          const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: isActive
          ? Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Active',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.success,
                fontWeight: FontWeight.w600)),
      )
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SettingSectionTitle extends StatelessWidget {
  final String title;
  const _SettingSectionTitle({required this.title});

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
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool showArrow;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.showArrow = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? AppColors.textPrimary)),
      trailing: trailing ??
          (showArrow
              ? const Icon(Icons.chevron_right, color: AppColors.textHint)
              : null),
    );
  }
}

class _SwitchMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchMenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
      trailing: Switch(
          value: value, onChanged: onChanged, activeColor: AppColors.primary),
    );
  }
}

class _ExportChip extends StatelessWidget {
  final String label;
  const _ExportChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark)),
    );
  }
}