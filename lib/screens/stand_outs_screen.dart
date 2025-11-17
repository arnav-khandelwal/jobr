import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/compact_job_card.dart';
import 'package:swipe_app/widgets/detailed_job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';

class StandOutsScreen extends StatefulWidget {
  const StandOutsScreen({super.key});

  @override
  State<StandOutsScreen> createState() => _StandOutsScreenState();
}

class _StandOutsScreenState extends State<StandOutsScreen> {
  late final List<Job> _topJobs;
  late final List<Map<String, dynamic>> _topApplications;
  int _navIndex = 1; // Stand Outs tab index in BottomNavBar
  int _currentJobIndex = 0;
  final Set<String> _appliedJobIds = {};

  @override
  void initState() {
    super.initState();
    _topJobs = _selectTopJobs(availableJobs, 3);
    _topApplications = _selectTopApplications(availableJobs, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeProvider.backgroundColor,
            elevation: 0,
            title: Text(
              'Stand Outs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryTextColor,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Jobs section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Jobs for You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      Text(
                        _currentJobIndex < _topJobs.length
                            ? '${_currentJobIndex + 1} of ${_topJobs.length}'
                            : '${_topJobs.length} of ${_topJobs.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentJobIndex < _topJobs.length) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatusRow(_topJobs[_currentJobIndex], themeProvider),
                  ),
                  const SizedBox(height: 8),
                  _buildSwipeableJobCard(_topJobs[_currentJobIndex]),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'All stand-out jobs reviewed!',
                            style: TextStyle(color: themeProvider.primaryTextColor, fontSize: 16),
                          ),
                          Text(
                            'Scroll to see Top Applications below',
                            style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Top Applications section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Applications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      Text(
                        '${_topApplications.length} shown',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._topApplications.map((app) => CompactJobCard(
                      job: app['job'] as Job,
                      status: app['status'] as String,
                      onStatusChanged: (_) {},
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _navIndex,
            onTap: (index) {
              if (index == 0) {
                // Go back to Home when Home tab tapped
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
              setState(() {
                _navIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  // Simple heuristic to pick top jobs
  List<Job> _selectTopJobs(List<Job> jobs, int count) {
    const preferredSkills = {'Flutter', 'Dart', 'Python', 'AWS'};

    final scored = jobs
        .map((j) {
          final skillMatches = j.skills.where((s) => preferredSkills.contains(s)).length;
          final remoteBoost = j.remoteFriendly ? 1 : 0;
          final fullTimeBoost = j.jobType.toLowerCase().contains('full') ? 1 : 0;
          final score = skillMatches * 2 + remoteBoost + fullTimeBoost;
          return (job: j, score: score);
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(count).map((e) => e.job).toList();
  }

  // Wrap a DetailedJobCard with horizontal swipe handling
  Widget _buildSwipeableJobCard(Job job) {
    // Mirror Home's simple left/right swipe behavior (sign-based)
    return GestureDetector(
      onPanEnd: (details) {
        final dx = details.velocity.pixelsPerSecond.dx;
        if (dx > 0) {
          _onJobSwipeRight(job);
        } else if (dx < 0) {
          _onJobSwipeLeft(job);
        }
      },
      child: DetailedJobCard(job: job),
    );
  }

  void _onJobSwipeRight(Job job) {
    _appliedJobIds.add(job.jobId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied to ${job.jobTitle}!'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _nextJob();
  }

  void _onJobSwipeLeft(Job job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skipped ${job.jobTitle}'),
        backgroundColor: Colors.grey,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _nextJob();
  }

  void _nextJob() {
    if (!mounted) return;
    setState(() {
      if (_currentJobIndex < _topJobs.length - 1) {
        _currentJobIndex++;
      } else {
        _currentJobIndex = _topJobs.length; // mark as finished
      }
    });
  }

  Widget _buildStatusRow(Job job, ThemeProvider themeProvider) {
    final bool applied = _appliedJobIds.contains(job.jobId);
    final Color color = applied ? const Color(0xFF10B981) : const Color(0xFF64748B);
    final String label = applied ? 'Applied' : 'Not applied';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(applied ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Use some of the available jobs as mock applications and prioritize accepted > pending > rejected
  List<Map<String, dynamic>> _selectTopApplications(List<Job> jobs, int count) {
    final mockApps = <Map<String, dynamic>>[
      {'job': jobs[0], 'status': 'accepted', 'id': 's1'},
      {'job': jobs[2], 'status': 'pending', 'id': 's2'},
      {'job': jobs[4], 'status': 'accepted', 'id': 's3'},
      {'job': jobs[1], 'status': 'pending', 'id': 's4'},
      {'job': jobs[3], 'status': 'rejected', 'id': 's5'},
    ];

    int statusRank(String s) {
      switch (s) {
        case 'accepted':
          return 0;
        case 'pending':
          return 1;
        case 'rejected':
        default:
          return 2;
      }
    }

    mockApps.sort((a, b) => statusRank(a['status']).compareTo(statusRank(b['status'])));
    return mockApps.take(count).toList();
  }
}
