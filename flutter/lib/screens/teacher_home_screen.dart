import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'camera_test_screen.dart';

/// Teacher Home Screen — 3 tabs: Roster / Run Test / Stats
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({
    super.key,
    required this.teacherName,
    required this.schoolOrRegion,
  });
  final String teacherName;
  final String schoolOrRegion;

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<_RosterEntry> _roster = [];
  String _searchQuery = '';
  _RosterEntry? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ApiService.instance.get('/enrollments/students');
      final data = ApiService.instance.unwrap(res) as List;
      final roster = data.map((entry) {
        final athlete = entry['athleteId'] ?? {};
        return _RosterEntry(
          athleteId: athlete['_id'] ?? '',
          name: athlete['name'] ?? 'Unnamed',
          age: athlete['age'] ?? 0,
          gender: athlete['gender'] ?? '',
          district: athlete['district'],
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load roster. Check your connection.';
        _isLoading = false;
      });
    }
  }

  List<_RosterEntry> get _filteredRoster {
    if (_searchQuery.trim().isEmpty) return _roster;
    final q = _searchQuery.toLowerCase();
    return _roster.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  void _handleLogout() async {
    await ApiService.instance.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // ── Tab 0: Roster ────────────────────────────────────────────────────────

  Widget _buildRoster() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardSubtitle),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                  onPressed: _loadRoster, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoster,
      child: Column(
        children: [
          GradientHeader(
            colors: AppColors.teacherGradient,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Roster', style: AppTextStyles.subtitleOnDark),
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white70, size: 20),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.teacherName,
                      style: AppTextStyles.heading1OnDark),
                  Text(widget.schoolOrRegion,
                      style: AppTextStyles.subtitleOnDark),
                  const SizedBox(height: AppSpacing.md),
                  // Stats chips
                  Row(
                    children: [
                      _HeaderChip(
                          value: '${_roster.length}', label: 'Students'),
                      const SizedBox(width: AppSpacing.sm),
                      _HeaderChip(
                          value: widget.schoolOrRegion
                              .split(',')
                              .last
                              .trim(),
                          label: 'Region'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search student by name…',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // List
          Expanded(
            child: _filteredRoster.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.groups_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.md),
                          Text('No students found',
                              style: AppTextStyles.cardTitle),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Students who enroll in your school/region will appear here',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardSubtitle,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    itemCount: _filteredRoster.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final s = _filteredRoster[i];
                      return _RosterTile(
                        student: s,
                        onRunTest: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraTestScreen(
                                studentId: s.athleteId,
                                studentName: s.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Run Test ──────────────────────────────────────────────────────

  Widget _buildRunTest() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Run a Fitness Test', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text('Select a student from the list below, then start the test.',
            style: AppTextStyles.cardSubtitle),
        const SizedBox(height: AppSpacing.lg),

        // Student picker
        Text('Select Student', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        if (_roster.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('No students on roster yet.',
                style: AppTextStyles.cardSubtitle),
          )
        else
          DropdownButtonFormField<_RosterEntry>(
            initialValue: _selectedStudent,
            decoration: const InputDecoration(
                hintText: 'Choose a student…',
                prefixIcon: Icon(Icons.person_search_rounded, size: 20)),
            items: _roster
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.name} (${s.age} yrs)'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedStudent = v),
          ),

        const SizedBox(height: AppSpacing.xl),

        // Launch button
        AnimatedOpacity(
          opacity: _selectedStudent != null ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roleTeacher,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
            ),
            onPressed: _selectedStudent == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraTestScreen(
                          studentId: _selectedStudent!.athleteId,
                          studentName: _selectedStudent!.name,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.videocam_rounded),
            label: Text(_selectedStudent != null
                ? 'Start Test — ${_selectedStudent!.name}'
                : 'Start Test'),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Info card
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'The camera will detect body pose in real-time using MediaPipe AI. '
                  'Ask the student to stand in front of the camera before starting.',
                  style: AppTextStyles.cardSubtitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Stats ─────────────────────────────────────────────────────────

  Widget _buildStats() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('School Statistics', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.md),
        // Summary cards grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.4,
          children: [
            _StatsCard(
              icon: Icons.groups_rounded,
              value: '${_roster.length}',
              label: 'Total Students',
              color: AppColors.primary,
            ),
            _StatsCard(
              icon: Icons.location_on_rounded,
              value: widget.schoolOrRegion.split(',').first.trim().length > 15
                  ? '${widget.schoolOrRegion.split(',').first.trim().substring(0, 15)}…'
                  : widget.schoolOrRegion.split(',').first.trim(),
              label: 'School',
              color: AppColors.roleTeacher,
            ),
            _StatsCard(
              icon: Icons.male_rounded,
              value:
                  '${_roster.where((s) => s.gender == 'male').length}',
              label: 'Male Athletes',
              color: AppColors.primary,
            ),
            _StatsCard(
              icon: Icons.female_rounded,
              value:
                  '${_roster.where((s) => s.gender == 'female').length}',
              label: 'Female Athletes',
              color: AppColors.roleStudent,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Tip', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'To run a fitness test, go to the "Run Test" tab, select a student, '
                'and press Start. The AI camera will track the student\'s movement '
                'and automatically count reps.',
                style: AppTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRoster(),
          _buildRunTest(),
          _buildStats(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded), label: 'Roster'),
          BottomNavigationBarItem(
              icon: Icon(Icons.videocam_rounded), label: 'Run Test'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _RosterEntry {
  final String athleteId;
  final String name;
  final int age;
  final String gender;
  final String? district;

  const _RosterEntry({
    required this.athleteId,
    required this.name,
    required this.age,
    required this.gender,
    this.district,
  });
}

class _RosterTile extends StatelessWidget {
  final _RosterEntry student;
  final VoidCallback onRunTest;

  const _RosterTile({required this.student, required this.onRunTest});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.roleTeacher.withValues(alpha: 0.15),
              child: Text(
                student.name.isNotEmpty
                    ? student.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.roleTeacher),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: AppTextStyles.cardTitle),
                  Text(
                    '${student.age} yrs • ${student.gender}'
                    '${student.district != null ? ' • ${student.district}' : ''}',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onRunTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleTeacher,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Test'),
            ),
          ],
        ),
      );
}

class _HeaderChip extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatsCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(value,
                style: AppTextStyles.stat
                    .copyWith(fontSize: 22, color: AppColors.textPrimary)),
            Text(label, style: AppTextStyles.statLabel),
          ],
        ),
      );
}
