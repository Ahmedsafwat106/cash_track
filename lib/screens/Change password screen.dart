import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../features/auth/auth_cubit.dart';
import '../features/auth/auth_state.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'login_screen.dart';


class ChangePasswordScreen extends StatefulWidget {
  final String token;
  const ChangePasswordScreen({super.key, required this.token});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _emailSent = false;

  late AuthCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AuthCubit(ApiService());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) async {
          if (state is AuthPasswordResetSent) {
            setState(() => _emailSent = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reset link sent! Check your email.'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is AuthPasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed successfully!'),
                backgroundColor: AppColors.success,
              ),
            );

            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            }
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (ctx, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Change Password'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      _StepChip(number: '1', label: 'Send Email', active: true),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Divider(
                              color: _emailSent
                                  ? AppColors.primary
                                  : AppColors.divider)),
                      const SizedBox(width: 8),
                      _StepChip(number: '2', label: 'Reset', active: _emailSent),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (!_emailSent) ...[
                    const Text('Step 1: Enter Your Email',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                      "We'll send a reset code to your email address.",
                      style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            hint: 'Your email address',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefix: const Icon(Icons.email_outlined,
                                color: AppColors.textHint),
                            validator: (v) =>
                            v!.isEmpty ? 'Enter your email' : null,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: 'Send Reset Link',
                            isLoading: isLoading,
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                _cubit.forgotPassword(_emailCtrl.text.trim());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_emailSent) ...[
                    const Text('Step 2: Enter Reset Code & New Password',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      'Code sent to ${_emailCtrl.text}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _resetFormKey,
                      child: Column(
                        children: [
                          // Reset Token
                          _buildLabel('Reset Code (from email)'),
                          CustomTextField(
                            hint: 'Paste code here',
                            controller: _tokenCtrl,
                            prefix: const Icon(Icons.vpn_key_outlined,
                                color: AppColors.textHint),
                            validator: (v) =>
                            v!.isEmpty ? 'Enter the reset code' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('New Password'),
                          CustomTextField(
                            hint: 'New Password',
                            controller: _newPassCtrl,
                            obscure: _obscureNew,
                            prefix: const Icon(Icons.lock_outline,
                                color: AppColors.textHint),
                            suffix: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            validator: (v) => v!.length < 6
                                ? 'At least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Confirm New Password'),
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
                            validator: (v) => v != _newPassCtrl.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 32),

                          CustomButton(
                            label: 'Change Password',
                            isLoading: isLoading,
                            onTap: () {
                              if (_resetFormKey.currentState!.validate()) {
                                _cubit.resetPassword(
                                  _emailCtrl.text.trim(),
                                  _tokenCtrl.text.trim(),
                                  _newPassCtrl.text,
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              _cubit.forgotPassword(
                                  _emailCtrl.text.trim());
                            },
                            child: const Text('Resend Code',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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

class _StepChip extends StatelessWidget {
  final String number;
  final String label;
  final bool active;
  const _StepChip(
      {required this.number, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: TextStyle(
                    color: active ? Colors.white : AppColors.textHint,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.primary : AppColors.textHint)),
      ],
    );
  }
}