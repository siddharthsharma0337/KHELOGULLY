import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

/// PET Home Screen — 3 tabs: School Mode / Register Student / History
/// This was the MISSING screen — PET login now routes here correctly.
class PetHomeScreen extends StatefulWidget {
  const PetHomeScreen({super.key, required this.petName});
  final String petName;

  @override
  State<PetHomeScreen> createState() => _PetHomeScreenState();
}

class _PetHomeScreenState extends State<PetHomeScreen> {
  int _currentIndex = 0;

  void _handleLogout() async {
    await ApiService.instance.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _PetDashboardTab(
            petName: widget.petName,
            onLogout: _handleLogout,
            onSwitchTab: (i) => setState(() => _currentIndex = i),
          ),
          const _RegisterStudentTab(),
          const _PetHistoryTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.rolePet,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_rounded), label: 'Register'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), label: 'History'),
        ],
      ),
    );
  }
}

// ── Tab 0: PET Dashboard ─────────────────────────────────────────────────────

class _PetDashboardTab extends StatelessWidget {
  final String petName;
  final VoidCallback onLogout;
  final ValueChanged<int> onSwitchTab;

  const _PetDashboardTab({
    required this.petName,
    required this.onLogout,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final initial = petName.isNotEmpty ? petName[0].toUpperCase() : 'P';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GradientHeader(
          colors: AppColors.petGradient,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PET Dashboard',
                        style: AppTextStyles.subtitleOnDark),
                    IconButton(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white70, size: 20),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(petName,
                            style: AppTextStyles.heading1OnDark),
                        Text('Physical Education Teacher',
                            style: AppTextStyles.subtitleOnDark),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Actions', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),

              // Action cards
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      onTap: () => onSwitchTab(1), // → Register Student tab
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.petGradient),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Register\nStudent',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardSubtitle
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GlassCard(
                      onTap: () => onSwitchTab(2), // → History/Batch test tab
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.studentGradient),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.videocam_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('View\nHistory',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardSubtitle
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GlassCard(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Sync Results'),
                            content: const Text(
                              'All locally stored test results will be uploaded to the server. '
                              'Make sure you have an internet connection before syncing.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Sync Now'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.teacherGradient),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.upload_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Sync\nResults',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardSubtitle
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('About School Mode', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.groups_rounded,
                      color: AppColors.rolePet,
                      text:
                          'Register multiple students under your school without needing them to create their own accounts.',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _InfoRow(
                      icon: Icons.wifi_off_rounded,
                      color: AppColors.roleStudent,
                      text:
                          'Tests can be run offline. Results are stored locally and synced when internet is available.',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _InfoRow(
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.roleTeacher,
                      text:
                          'View complete fitness history for all students in your school.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.cardSubtitle)),
        ],
      );
}

// ── Tab 1: Register Student ──────────────────────────────────────────────────

class _RegisterStudentTab extends StatefulWidget {
  const _RegisterStudentTab();

  @override
  State<_RegisterStudentTab> createState() => _RegisterStudentTabState();
}

class _RegisterStudentTabState extends State<_RegisterStudentTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _ageCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a gender')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.post('/auth/register', body: {
        'userType': 'student',
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'age': int.parse(_ageCtrl.text.trim()),
        'gender': _selectedGender,
        if (_regionCtrl.text.trim().isNotEmpty)
          'district': _regionCtrl.text.trim(),
      });

      ApiService.instance.unwrap(response);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_nameCtrl.text.trim()} registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear form for next student
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _passwordCtrl.clear();
      _ageCtrl.clear();
      setState(() => _selectedGender = null);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text('Register a Student', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add a student to the KheloGully system under your school.',
              style: AppTextStyles.cardSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),

            _FieldLabel('Full Name'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Student full name',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Name must be at least 2 characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            _FieldLabel('Phone Number'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. +919876543210',
                prefixIcon: Icon(Icons.phone_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                  return 'Invalid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _FieldLabel('Temporary Password'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Min 8 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
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
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '5-25'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final a = int.tryParse(v);
                          if (a == null) return 'Invalid';
                          if (a < 5 || a > 25) return '5-25 only';
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
                        decoration:
                            const InputDecoration(hintText: 'Select'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'female', child: Text('Female')),
                          DropdownMenuItem(
                              value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _FieldLabel('District / Region (Optional)'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _regionCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Jabalpur',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rolePet),
              onPressed: _isLoading ? null : _handleRegister,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Register Student'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: History ───────────────────────────────────────────────────────────

class _PetHistoryTab extends StatelessWidget {
  const _PetHistoryTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.petGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Test History', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Previous test results for your registered students will appear here once tests are submitted.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync from Server'),
            ),
          ],
        ),
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
