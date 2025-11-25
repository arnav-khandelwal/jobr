import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'package:swipe_app/services/job_cache_service.dart';
import 'package:swipe_app/services/resume_cache_service.dart';
import 'package:swipe_app/services/recommendations_service.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/detailed_job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';

class StandOutsScreen extends StatefulWidget {
  const StandOutsScreen({super.key});

  @override
  State<StandOutsScreen> createState() => _StandOutsScreenState();
}

class _StandOutsScreenState extends State<StandOutsScreen> {
  List<Job> _topJobs = const [];
  List<Job> _recommended = const [];
  bool _loading = true;
  int _navIndex = 1; // Stand Outs tab index in BottomNavBar
  int _currentJobIndex = 0;
  final Set<String> _appliedJobIds = {};
  bool _aiTried = false;
  bool _aiFailed = false;

  @override
  void initState() {
    super.initState();
    _initStandouts();
  }

  Future<void> _initStandouts() async {
    final cachedJobs = await JobCacheService.loadJobs();
    final resume = await ResumeCacheService.loadResumeData();
    List<Job> heuristic = _selectTopJobs(cachedJobs, 5);
    List<Job> recommended = [];
    if (resume.isNotEmpty && cachedJobs.isNotEmpty) {
      try {
        // Pass cached resume and jobs explicitly to the recommendations service
        recommended = await RecommendationsService.instance
            .fetchRecommendedJobs(resume: resume, jobs: cachedJobs);
        _aiTried = true;
        if (recommended.isEmpty) {
          _aiFailed = true;
        }
      } catch (_) {
        _aiTried = true;
        _aiFailed = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _recommended = recommended.isNotEmpty ? recommended : heuristic;
      _topJobs = _recommended; // unify usage
      _currentJobIndex = 0;
      _loading = false;
    });
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
            actions: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Refresh recommendations',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshRecommendations,
                ),
            ],
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
                        _aiTried && !_aiFailed
                            ? 'AI Recommended Jobs'
                            : 'Top Jobs for You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      if (!_loading && _topJobs.isNotEmpty)
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
                if (_loading) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading your stand-out jobs...'),
                        ],
                      ),
                    ),
                  ),
                ] else if (_aiFailed && _aiTried) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI recommendation unavailable. Showing heuristic picks.',
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_currentJobIndex < _topJobs.length &&
                    _topJobs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatusRow(
                      _topJobs[_currentJobIndex],
                      themeProvider,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSwipeableJobCard(_topJobs[_currentJobIndex]),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            _topJobs.isEmpty ? Icons.inbox : Icons.check_circle,
                            color: _topJobs.isEmpty
                                ? Colors.grey
                                : Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _topJobs.isEmpty
                                ? 'No cached jobs found'
                                : 'All stand-out jobs reviewed!',
                            style: TextStyle(
                              color: themeProvider.primaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _topJobs.isEmpty
                                ? 'Load jobs from Home, then revisit Stand Outs.'
                                : 'No more stand-out jobs. Come back later for new matches.',
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!_loading && _topJobs.isNotEmpty)
                  Center(
                    child: TextButton.icon(
                      onPressed: _refreshRecommendations,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Top 5'),
                    ),
                  ),
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

  // Simple heuristic (fallback when AI fails / not available)
  List<Job> _selectTopJobs(List<Job> jobs, int count) {
    const preferredSkills = {'Flutter', 'Dart', 'Python', 'AWS'};

    final scored = jobs.map((j) {
      final skillMatches = j.skills
          .where((s) => preferredSkills.contains(s))
          .length;
      final remoteBoost = j.remoteFriendly ? 1 : 0;
      final fullTimeBoost = j.jobType.toLowerCase().contains('full') ? 1 : 0;
      final score = skillMatches * 2 + remoteBoost + fullTimeBoost;
      return (job: j, score: score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(count).map((e) => e.job).toList();
  }

  Future<void> _refreshRecommendations() async {
    setState(() {
      _loading = true;
      _aiTried = false;
      _aiFailed = false;
      _recommended = const [];
      _topJobs = const [];
      _currentJobIndex = 0;
    });
    await _initStandouts();
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
    final Color color = applied
        ? const Color(0xFF10B981)
        : const Color(0xFF64748B);
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
              Icon(
                applied ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Top Applications section removed.
}
