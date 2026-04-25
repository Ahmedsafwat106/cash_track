import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/api_service.dart';
import '../features/auth/auth_cubit.dart';
import '../features/auth/auth_state.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // ✅ password requirements state
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;
  bool _hasMinLen = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String val) {
    setState(() {
      _hasUpper = val.contains(RegExp(r'[A-Z]'));
      _hasLower = val.contains(RegExp(r'[a-z]'));
      _hasDigit = val.contains(RegExp(r'[0-9]'));
      _hasSpecial = val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;~/`]'));
      _hasMinLen = val.length >= 8;
    });
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Enter a password';
    if (!_hasMinLen) return 'At least 8 characters required';
    if (!_hasUpper) return 'Add at least one uppercase letter (A-Z)';
    if (!_hasLower) return 'Add at least one lowercase letter (a-z)';
    if (!_hasDigit) return 'Add at least one number (0-9)';
    if (!_hasSpecial) return 'Add at least one special character (!@#\$...)';
    return null;
  }

  bool get _passwordValid =>
      _hasUpper && _hasLower && _hasDigit && _hasSpecial && _hasMinLen;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(ApiService()),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ??
                    'Registration successful! Check your email to confirm.'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.error),
                  backgroundColor: AppColors.error),
            );
          }
        },
        builder: (ctx, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 32),

                      _buildLabel('Full Name'),
                      CustomTextField(
                        hint: 'Full Name',
                        controller: _nameCtrl,
                        prefix: const Icon(Icons.person_outline,
                            color: AppColors.textHint),
                        validator: (v) =>
                        v!.isEmpty ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Email Address'),
                      CustomTextField(
                        hint: 'Email Address',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Icon(Icons.email_outlined,
                            color: AppColors.textHint),
                        validator: (v) {
                          if (v!.isEmpty) return 'Enter your email';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Password'),
                      CustomTextField(
                        hint: 'Password',
                        controller: _passCtrl,
                        obscure: _obscurePass,
                        prefix: const Icon(Icons.lock_outline,
                            color: AppColors.textHint),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        onChanged: _onPasswordChanged,
                        validator: _validatePassword,
                      ),

                      if (_passCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _PasswordStrengthWidget(
                          hasMinLen: _hasMinLen,
                          hasUpper: _hasUpper,
                          hasLower: _hasLower,
                          hasDigit: _hasDigit,
                          hasSpecial: _hasSpecial,
                        ),
                      ],
                      const SizedBox(height: 16),

                      _buildLabel('Confirm Password'),
                      CustomTextField(
                        hint: 'Confirm Password',
                        controller: _confirmCtrl,
                        obscure: _obscureConfirm,
                        prefix: const Icon(Icons.lock_outline,
                            color: AppColors.textHint),
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint,
                          ),
                          onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) => v != _passCtrl.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Monthly Budget (EGP)'),
                      CustomTextField(
                        hint: 'e.g. 5000',
                        controller: _budgetCtrl,
                        keyboardType: TextInputType.number,
                        prefix: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.textHint),
                        validator: (v) {
                          if (v!.isEmpty) return 'Enter your monthly budget';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      CustomButton(
                        label: 'Register',
                        isLoading: isLoading,
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            ctx.read<AuthCubit>().register(
                              _nameCtrl.text,
                              _emailCtrl.text,
                              _passCtrl.text,
                              double.parse(_budgetCtrl.text),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
  );
}

class _PasswordStrengthWidget extends StatelessWidget {
  final bool hasMinLen, hasUpper, hasLower, hasDigit, hasSpecial;
  const _PasswordStrengthWidget({
    required this.hasMinLen,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSpecial,
  });

  @override
  Widget build(BuildContext context) {
    final all = [hasMinLen, hasUpper, hasLower, hasDigit, hasSpecial];
    final count = all.where((e) => e).length;
    Color barColor = AppColors.error;
    String label = 'Weak';
    if (count >= 5) { barColor = AppColors.success; label = 'Strong'; }
    else if (count >= 3) { barColor = AppColors.warning; label = 'Medium'; }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Password strength',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: barColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / 5,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          _Req(met: hasMinLen, text: 'At least 8 characters'),
          _Req(met: hasUpper, text: 'One uppercase letter (A-Z)'),
          _Req(met: hasLower, text: 'One lowercase letter (a-z)'),
          _Req(met: hasDigit, text: 'One number (0-9)'),
          _Req(met: hasSpecial, text: 'One special character (!@#\$...)'),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final bool met;
  final String text;
  const _Req({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 11,
                color: met ? AppColors.success : AppColors.textHint)),
      ]),
    );
  }
}