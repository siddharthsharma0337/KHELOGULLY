import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

/// Student Home Screen — 3 tabs: Dashboard / Enrollments / Scores
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key, required this.studentName});
  final String studentName;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<EnrollmentModel> _enrollments = [];
  List<TestResultModel> _scores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final enrollRes = await ApiService.instance.get('/student/enrollments');
      final enrollData = ApiService.instance.unwrap(enrollRes);
      _enrollments = (enrollData as List)
          .map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
          .where((e) => e.status == 'active')
          .toList();

      final scoresRes = await ApiService.instance.get('/student/scores');
      final scoresData = ApiService.instance.unwrap(scoresRes);
      _scores = (scoresData as List)
          .map((s) => TestResultModel.fromJson(s as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleWithdraw(EnrollmentModel enrollment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw enrollment?'),
        content: Text(
            'You will be removed from "${enrollment.schoolOrRegion}". This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res =
          await ApiService.instance.delete('/enrollments/${enrollment.id}');
      ApiService.instance.unwrap(res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Withdrawn successfully')));
        await _loadData();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showEnrollSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnrollSheet(
        controller: ctrl,
        onEnroll: (schoolOrRegion) async {
          try {
            final res = await ApiService.instance.post('/enrollments', body: {
              'schoolOrRegion': schoolOrRegion,
            });
            ApiService.instance.unwrap(res);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enrolled successfully!')));
              await _loadData();
            }
          } on ApiException catch (e) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.message)));
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Network error. Try again.')));
            }
          }
        },
      ),
    );
  }

  void _handleLogout() async {
    await ApiService.instance.clearTokens();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/', (route) => false);
  }

  // ── Tabs ─────────────────────────────────────────────────────────────────

  Widget _buildDashboard() {
    final initial =
        widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : '?';
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Profile hero card
          GradientHeader(
            colors: AppColors.studentGradient,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dashboard', style: AppTextStyles.subtitleOnDark),
                      IconButton(
                        onPressed: _handleLogout,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.studentName,
                                style: AppTextStyles.heading1OnDark),
                            Text('Student Athlete',
                                style: AppTextStyles.subtitleOnDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        value: '${_enrollments.length}',
                        label: 'Enrollments',
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatChip(
                        value: '${_scores.length}',
                        label: 'Tests Done',
                        icon: Icons.fitness_center_rounded,
                      ),
                      if (_scores.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          value: _scores
                              .where((s) => s.percentile != null)
                              .fold(0.0, (a, s) => a + s.percentile!)
                              .toStringAsFixed(0),
                          label: 'Avg %ile',
                          icon: Icons.bar_chart_rounded,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recent scores
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Test Results', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.md),
                if (_scores.isEmpty)
                  _EmptyState(
                    icon: Icons.bar_chart_rounded,
                    message: 'No test results yet.\nAsk your teacher to run a test!',
                  )
                else
                  ..._scores.take(5).map((s) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ScoreTile(result: s),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollments() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Enrollments', style: AppTextStyles.heading3),
              TextButton.icon(
                onPressed: _showEnrollSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Enroll'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.roleStudent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_enrollments.isEmpty)
            _EmptyState(
              icon: Icons.location_on_outlined,
              message:
                  'Not enrolled anywhere yet.\nTap "Enroll" to join a school or region.',
            )
          else
            ..._enrollments.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _EnrollmentTile(
                    enrollment: e,
                    onWithdraw: () => _handleWithdraw(e),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildScores() {
    // Group by test type
    final Map<String, List<TestResultModel>> grouped = {};
    for (final s in _scores) {
      grouped.putIfAbsent(s.displayTestType, () => []).add(s);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('All Test Scores', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          if (_scores.isEmpty)
            _EmptyState(
              icon: Icons.bar_chart_rounded,
              message: 'No scores yet.',
            )
          else
            ...grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(entry.key,
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.roleStudent)),
                    ),
                    ...entry.value.map((s) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ScoreTile(result: s),
                        )),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboard(),
                _buildEnrollments(),
                _buildScores(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded), label: 'Enrollments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Scores'),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatChip({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}

class _EnrollmentTile extends StatelessWidget {
  final EnrollmentModel enrollment;
  final VoidCallback onWithdraw;

  const _EnrollmentTile(
      {required this.enrollment, required this.onWithdraw});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.roleStudent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.roleStudent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(enrollment.schoolOrRegion,
                      style: AppTextStyles.cardTitle),
                  Text(
                    'Active · Enrolled ${_formatDate(enrollment.enrolledAt)}',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onWithdraw,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.textSecondary,
              tooltip: 'Withdraw',
            ),
          ],
        ),
      );

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _ScoreTile extends StatelessWidget {
  final TestResultModel result;
  const _ScoreTile({required this.result});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.fitness_center_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.displayTestType,
                      style: AppTextStyles.cardTitle),
                  Text('${result.rawScore} ${result.unit}',
                      style: AppTextStyles.cardSubtitle),
                ],
              ),
            ),
            if (result.percentile != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.roleStudent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${result.percentile!.toStringAsFixed(0)}th %ile',
                  style: AppTextStyles.badge.copyWith(
                      color: AppColors.roleStudent),
                ),
              )
            else
              Text('Pending',
                  style: AppTextStyles.badge
                      .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle),
          ],
        ),
      );
}

// ── Enroll Bottom Sheet ──────────────────────────────────────────────────────

class _EnrollSheet extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onEnroll;

  const _EnrollSheet({required this.controller, required this.onEnroll});

  @override
  State<_EnrollSheet> createState() => _EnrollSheetState();
}

class _EnrollSheetState extends State<_EnrollSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Enroll in a School / Region',
              style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text('Enter the exact school or region name to enroll.',
              style: AppTextStyles.cardSubtitle),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: widget.controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Govt. Senior Secondary School, Jabalpur',
              prefixIcon: Icon(Icons.school_outlined, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleStudent),
            onPressed: _loading
                ? null
                : () async {
                    final val = widget.controller.text.trim();
                    if (val.isEmpty) return;
                    setState(() => _loading = true);
                    await widget.onEnroll(val);
                    if (mounted) setState(() => _loading = false);
                  },
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Confirm Enrollment'),
          ),
        ],
      ),
    );
  }
}
