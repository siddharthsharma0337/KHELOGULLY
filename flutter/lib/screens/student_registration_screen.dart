import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _guardianController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showOptional = false;

  final Map<String, String> _genderOptions = {
    'Male': 'male',
    'Female': 'female',
    'Other': 'other',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _guardianController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.post('/auth/register', body: {
        'userType': 'student',
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        if (_guardianController.text.trim().isNotEmpty)
          'guardianName': _guardianController.text.trim(),
        if (_villageController.text.trim().isNotEmpty)
          'village': _villageController.text.trim(),
        if (_districtController.text.trim().isNotEmpty)
          'district': _districtController.text.trim(),
      });

      ApiService.instance.unwrap(response);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please log in.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LoginScreen(prefilledPhone: _phoneController.text.trim()),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Try again.')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient header ─────────────────────────────────────────────
          GradientHeader(
            colors: AppColors.studentGradient,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Text('Student Registration',
                        style: AppTextStyles.heading1OnDark),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  'Track your fitness scores and join local programs',
                  style: AppTextStyles.subtitleOnDark,
                ),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),

                    _FieldLabel('Full Name'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 2)
                              ? 'Name must be at least 2 characters'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _FieldLabel('Phone Number'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'e.g. +919876543210',
                        prefixIcon: Icon(Icons.phone_rounded, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                          return 'Enter a valid phone number (7-15 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _FieldLabel('Password'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Create a password (min 8 characters)',
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
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Age'),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '5-25',
                                  prefixIcon: Icon(
                                      Icons.cake_outlined,
                                      size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final age = int.tryParse(v.trim());
                                  if (age == null) return 'Invalid';
                                  if (age < 5 || age > 25) return '5-25 only';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Gender'),
                              const SizedBox(height: AppSpacing.sm),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: const InputDecoration(
                                    hintText: 'Select'),
                                items: _genderOptions.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.value,
                                          child: Text(e.key),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedGender = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Optional fields toggle
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showOptional = !_showOptional),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.roleStudent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.roleStudent
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline_rounded,
                                size: 18, color: AppColors.roleStudent),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _showOptional
                                  ? 'Hide optional details'
                                  : 'Add optional details (Village, District…)',
                              style: AppTextStyles.cardSubtitle.copyWith(
                                  color: AppColors.roleStudent),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showOptional) ...[
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel('Guardian Name'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _guardianController,
                        decoration: const InputDecoration(hintText: 'Optional'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel('Village'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _villageController,
                        decoration: const InputDecoration(hintText: 'Optional'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel('District'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(hintText: 'Optional'),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roleStudent),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Create Student Account'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: const Text('Already have an account? Log in'),
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
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
      );
}
