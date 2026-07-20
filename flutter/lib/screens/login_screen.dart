import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'student_home_screen.dart';
import 'teacher_home_screen.dart';
import 'pet_home_screen.dart';

/// Login screen — shared by all 3 roles.
/// Backend POST /auth/login returns { user, accessToken, refreshToken }.
/// Role determines which home screen to show after login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prefilledPhone});
  final String? prefilledPhone;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController =
        TextEditingController(text: widget.prefilledPhone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.post('/auth/login', body: {
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
      });

      final data = ApiService.instance.unwrap(response);
      await ApiService.instance.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      final user = data['user'];
      final role = user['role'];
      final name = user['name'] ?? '';

      if (!mounted) return;

      Widget destination;
      if (role == 'student') {
        destination = StudentHomeScreen(studentName: name);
      } else if (role == 'teacher') {
        destination = TeacherHomeScreen(
          teacherName: name,
          schoolOrRegion: user['schoolOrRegion'] ?? '',
        );
      } else {
        // 'pet' role — new dedicated home screen
        destination = PetHomeScreen(petName: name);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Network error. Check your connection and try again.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Compact gradient header ─────────────────────────────────────
          GradientHeader(
            colors: AppColors.primaryGradient,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.of(context).padding.top + AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Welcome back 👋',
                    style: AppTextStyles.heading1OnDark),
                const SizedBox(height: AppSpacing.xs),
                Text('Log in to continue your fitness journey',
                    style: AppTextStyles.subtitleOnDark),
              ],
            ),
          ),

          // ── Form ───────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _FieldLabel('Phone Number'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone_rounded, size: 20),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Phone number is required'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _FieldLabel('Password'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? 'Password is required'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Log In'),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Works for all roles: PET, Student, and Teacher. '
                              'You will be automatically redirected to your dashboard.',
                              style: AppTextStyles.cardSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary));
  }
}
