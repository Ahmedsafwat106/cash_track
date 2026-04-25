import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_colors.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final _auth = LocalAuthentication();
  bool _isAvailable = false;
  bool _isEnabled = false;
  List<BiometricType> _availableTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _isAvailable = await _auth.canCheckBiometrics;
      _availableTypes = await _auth.getAvailableBiometrics();
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('biometric_enabled') ?? false;
    } catch (_) {
      _isAvailable = false;
    }
    setState(() => _loading = false);
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      try {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Confirm your identity to enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (!authenticated) return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Biometric auth failed: $e'),
                backgroundColor: AppColors.error),
          );
        }
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() => _isEnabled = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(value ? 'Biometric login enabled' : 'Biometric login disabled'),
          backgroundColor: value ? AppColors.success : AppColors.textSecondary,
        ),
      );
    }
  }

  String get _biometricLabel {
    if (_availableTypes.contains(BiometricType.face)) return 'Face ID';
    if (_availableTypes.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    return 'Biometric';
  }

  IconData get _biometricIcon {
    if (_availableTypes.contains(BiometricType.face)) return Icons.face_outlined;
    return Icons.fingerprint_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biometric Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                  Icon(
                    _biometricIcon,
                    size: 64,
                    color: _isAvailable
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAvailable
                        ? '$_biometricLabel Available'
                        : 'Biometric Not Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _isAvailable
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAvailable
                        ? 'Use ${_biometricLabel.toLowerCase()} to log in quickly'
                        : 'Your device does not support biometric authentication',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isAvailable) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ],
                ),
                child: SwitchListTile(
                  value: _isEnabled,
                  onChanged: _toggle,
                  activeColor: AppColors.primary,
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_biometricIcon,
                        size: 18, color: AppColors.primary),
                  ),
                  title: Text('Enable $_biometricLabel',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _isEnabled ? 'Enabled — tap to disable' : 'Tap to enable',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_outlined,
                        color: AppColors.primaryDark, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Biometric data is stored on your device only and never sent to our servers.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}