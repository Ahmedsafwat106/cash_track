import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../features/auth/auth_cubit.dart';
import '../features/auth/auth_state.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'ForgotPasswordScreen.dart';
import 'MainLayout.dart';
import 'RegisterScreen.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;


  Future<void> _checkBiometricOnStart() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (token == null || !biometricEnabled) return;

    final auth = LocalAuthentication();

    try {
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return;

      final authenticated = await auth.authenticate(
        localizedReason: 'Login with biometrics',
        options: const AuthenticationOptions(
          biometricOnly: false, // مهم
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainLayout(token: token)),
        );
      }
    } catch (e) {
      print("Biometric error: $e");
    }
  }
  Future<void> _askBiometricAfterLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    final loggedOut = prefs.getBool('logged_out') ?? false;

    if (token == null || !biometricEnabled || !loggedOut) return;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Biometric Login"),
        content: const Text("Do you want to login with biometrics?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await prefs.setBool('logged_out', false);
              await _checkBiometricOnStart();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricOnStart();
    _askBiometricAfterLogout();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(ApiService()),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) async {
          if (state is AuthSuccess && state.token != null) {

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', state.token!);
            await prefs.setBool('biometric_enabled', true);
            if (!mounted) return;
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => MainLayout(token: state.token!)));
          } else if (state is AuthEmailNotConfirmed) {
            _showEmailNotConfirmedDialog(ctx);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
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
                      const SizedBox(height: 60),
                      Center(
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.account_balance_wallet_rounded,
                              color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Login',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 32),
                      const Text('Email Address',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: 'Email Address', controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Icon(Icons.email_outlined, color: AppColors.textHint),
                        validator: (v) => v!.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: 'Password', controller: _passCtrl, obscure: _obscure,
                        prefix: const Icon(Icons.lock_outline, color: AppColors.textHint),
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined, color: AppColors.textHint),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                          child: const Text('Forgot Password?',
                              style: TextStyle(fontSize: 13, color: AppColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: 'Login', isLoading: isLoading,
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            ctx.read<AuthCubit>().login(_emailCtrl.text, _passCtrl.text);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('Create one',
                              style: TextStyle(fontSize: 13, color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
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

  void _showEmailNotConfirmedDialog(BuildContext ctx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Email Not Confirmed',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
            'Please confirm your email first. Check your inbox or resend the confirmation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ctx.read<AuthCubit>().resendConfirmation(_emailCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Resend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

