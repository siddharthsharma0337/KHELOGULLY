import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pet_registration_screen.dart';
import 'student_registration_screen.dart';
import 'teacher_registration_screen.dart';
import 'login_screen.dart';

class RolePickerScreen extends StatefulWidget {
  const RolePickerScreen({super.key});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _headerFade =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOut,
    ));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _cardSlides = List.generate(3, (i) {
      final start = 0.2 + i * 0.15;
      return Tween<Offset>(
              begin: const Offset(0, 0.4), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _cardsCtrl,
        curve: Interval(start, start + 0.5, curve: Curves.easeOutCubic),
      ));
    });

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200),
        () => _cardsCtrl.forward());
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: GradientHeader(
                colors: AppColors.primaryGradient,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.of(context).padding.top + AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.sports_gymnastics,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Text('KheloGully',
                            style: AppTextStyles.heading1OnDark),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Who are you?',
                        style: AppTextStyles.display
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Select your role to get started',
                        style: AppTextStyles.subtitleOnDark),
                  ],
                ),
              ),
            ),
          ),

          // ── Role cards ─────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
              ),
              children: [
                SlideTransition(
                  position: _cardSlides[0],
                  child: FadeTransition(
                    opacity: _cardsCtrl,
                    child: _RoleCard(
                      icon: Icons.groups_rounded,
                      title: 'PET (School Mode)',
                      subtitle:
                          'Register and run tests for multiple students offline',
                      colors: AppColors.petGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PetRegistrationScreen()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SlideTransition(
                  position: _cardSlides[1],
                  child: FadeTransition(
                    opacity: _cardsCtrl,
                    child: _RoleCard(
                      icon: Icons.school_rounded,
                      title: 'Student',
                      subtitle:
                          'Create your profile and take fitness tests',
                      colors: AppColors.studentGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const StudentRegistrationScreen()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SlideTransition(
                  position: _cardSlides[2],
                  child: FadeTransition(
                    opacity: _cardsCtrl,
                    child: _RoleCard(
                      icon: Icons.person_rounded,
                      title: 'Teacher',
                      subtitle:
                          'Manage your school roster and submit results',
                      colors: AppColors.teacherGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeacherRegistrationScreen()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Already have an account? Log in'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Gradient icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: colors, begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.first.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: colors.first),
          ),
        ],
      ),
    );
  }
}
