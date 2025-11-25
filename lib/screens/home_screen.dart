import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/location_app_bar.dart';
import 'package:swipe_app/widgets/filters_bar.dart';
import 'package:swipe_app/widgets/detailed_job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'package:swipe_app/services/job_api_service.dart';
import 'package:swipe_app/services/job_cache_service.dart';
import 'package:swipe_app/services/placementindia_apply_service.dart';
import 'package:swipe_app/services/applications_service.dart';

class PlacementIndiaCreds {
  final String email;
  final String password;
  PlacementIndiaCreds(this.email, this.password);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _location = 'India';
  int _selectedFilter = 0;
  int _navIndex = 0;
  bool _isLoading = true;
  bool _isServerHealthy = false;

  // NEW: automation flags
  bool _automationInProgress = false;
  bool _suppressSnackbars = false;

  final List<String> _filters = [
    'All',
    'Remote',
    'Full-time',
    'Part-time',
    'Internship',
    'Freelance',
  ];

  List<Job> _jobs = [];
  int _currentJobIndex = 0; // still used to reference current card
  Set<String> _viewedJobIds = {};

  // Compute visible jobs based on selected filter
  List<Job> _filteredJobs() {
    if (_selectedFilter == 0) return _jobs;
    final f = _filters[_selectedFilter].toLowerCase();
    return _jobs.where((job) {
      switch (f) {
        case 'remote':
          final locRemote = job.location.toLowerCase().contains('remote');
          return job.remoteFriendly || locRemote;
        case 'full-time':
          return job.jobType.toLowerCase() == 'full-time';
        case 'part-time':
          return job.jobType.toLowerCase() == 'part-time';
        case 'internship':
          return job.jobType.toLowerCase() == 'internship';
        case 'freelance':
          return job.jobType.toLowerCase() == 'freelance';
        default:
          return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initJobs();
  }

  // --- Helper methods for PlacementIndia apply flow ---
  Future<PlacementIndiaCreds?> _promptPlacementIndiaCreds(Job job) async {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    return showDialog<PlacementIndiaCreds>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Apply: ${job.jobTitle}',
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your PlacementIndia credentials'),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email ID / Mobile',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                final pwd = passController.text;
                if (email.isEmpty || pwd.isEmpty) {
                  // simple inline validation
                  return;
                }
                Navigator.of(ctx).pop(PlacementIndiaCreds(email, pwd));
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showProcessingSnack(String msg) {
    if (!_suppressSnackbars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _showGreenSnack(String msg) {
    if (!_suppressSnackbars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  void _showErrorSnack(String msg) {
    if (!_suppressSnackbars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _initJobs() async {
    await _checkServerHealth();
    // Load cached jobs & viewed IDs
    final cached = await JobCacheService.loadJobs();
    final viewed = await JobCacheService.loadViewedJobIds();
    // Filter out viewed jobs
    final filtered = cached.where((j) => !viewed.contains(j.jobId)).toList();
    // If no cached jobs (or all viewed) -> fetch
    if (filtered.isEmpty) {
      await _loadJobs();
      return;
    }
    // Shuffle and set state
    filtered.shuffle();
    if (mounted) {
      setState(() {
        _jobs = filtered;
        _currentJobIndex = 0;
        _isLoading = false;
        _viewedJobIds = viewed;
      });
    }
  }

  Future<void> _checkServerHealth() async {
    final isHealthy = await JobApiService.isServerHealthy();
    if (mounted) {
      setState(() {
        _isServerHealthy = isHealthy;
      });
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await JobApiService.fetchJobsFromAPI(
        searchTerm: 'software developer',
        location: _location,
        pages: 3,
      );

      // Shuffle jobs so user sees random order
      jobs.shuffle();
      // Persist jobs in cache
      await JobCacheService.saveJobs(jobs);
      await JobCacheService.clearViewedJobIds();
      _viewedJobIds.clear();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _currentJobIndex = 0;
          _isLoading = false;
          _isServerHealthy = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching jobs from API: $e');
      if (mounted) {
        setState(() {
          _jobs = availableJobs; // Fallback to local data
          _isLoading = false;
          // Mark server as unhealthy on failure
          _isServerHealthy = false;
        });
      }
    }
  }

  Future<void> _refreshJobs() async {
    await _loadJobs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isServerHealthy
                ? 'Jobs refreshed from server!'
                : 'Using local data',
          ),
          backgroundColor: _isServerHealthy ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _removeJobAndAdvance(String jobId, {required bool applied}) {
    // Mark viewed & persist
    _viewedJobIds.add(jobId);
    JobCacheService.addViewedJobId(jobId);
    // Remove from underlying list by id
    final idx = _jobs.indexWhere((j) => j.jobId == jobId);
    if (idx != -1) {
      _jobs.removeAt(idx);
    }
    // Adjust current index if out of range for new filtered list
    final visible = _filteredJobs();
    if (_currentJobIndex >= visible.length) {
      _currentJobIndex = 0;
    }
  }

  Future<void> _onSwipeRight() async {
    // Suppress snackbars during automation to avoid spam
    final visible = _filteredJobs();
    if (visible.isEmpty) return;
    final job = visible[_currentJobIndex];

    // If automation running, skip interactive apply flow.
    if (_automationInProgress || job.source != 'PlacementIndia') {
      // Non-PlacementIndia (or automation): record application immediately
      if (!_suppressSnackbars) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _jobs.isNotEmpty ? 'Applied to ${job.jobTitle}!' : 'Applied',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 400),
          ),
        );
      }
      // Fire and forget application record creation (auth required)
      ApplicationsService.instance.createApplication(job);
      setState(() {
        _removeJobAndAdvance(job.jobId, applied: true);
      });
      return;
    }

    // PlacementIndia job: prompt for credentials, then call backend apply endpoint.
    final creds = await _promptPlacementIndiaCreds(job);
    if (creds == null) return; // user cancelled

    _showProcessingSnack('Applying on PlacementIndia...');
    final result = await PlacementIndiaApplyService.instance.applyJob(
      jobUrl: job.applyLink,
      email: creds.email,
      password: creds.password,
    );

    if (result.success) {
      _showGreenSnack('Applied to ${job.jobTitle} (PlacementIndia)');
      // Persist application record
      ApplicationsService.instance.createApplication(job);
    } else {
      _showErrorSnack(
        result.message ?? 'Failed to apply (step: ${result.step})',
      );
    }

    if (mounted) {
      setState(() {
        _removeJobAndAdvance(job.jobId, applied: result.success);
      });
    }
  }

  void _onSwipeLeft() {
    final visible = _filteredJobs();
    if (visible.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skipped ${visible[_currentJobIndex].jobTitle}'),
          backgroundColor: Colors.grey,
          duration: const Duration(milliseconds: 400),
        ),
      );
    }
    setState(() {
      if (visible.isNotEmpty) {
        _removeJobAndAdvance(visible[_currentJobIndex].jobId, applied: false);
      }
    });
  }

  // NEW: start automation for count jobs. Pass -1 for "All available"
  Future<void> _startAutomation(int requestedCount) async {
    if (_jobs.isEmpty) return;

    final remaining = _jobs.length - _currentJobIndex;
    final toApply = requestedCount < 0
        ? remaining
        : (requestedCount > remaining ? remaining : requestedCount);

    if (toApply <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No jobs remaining to automate')),
        );
      }
      return;
    }

    setState(() {
      _automationInProgress = true;
      _suppressSnackbars = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auto-apply started for $toApply job${toApply == 1 ? '' : 's'}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    for (var i = 0; i < toApply; i++) {
      if (!mounted) return;
      _onSwipeRight(); // reuse same path as manual apply
      await Future.delayed(const Duration(milliseconds: 450));
    }

    if (!mounted) return;
    setState(() {
      _automationInProgress = false;
      _suppressSnackbars = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Auto-apply complete: Applied to $toApply job${toApply == 1 ? '' : 's'}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // NEW: Automate menu button widget
  Widget _buildAutomateMenu(ThemeProvider themeProvider) {
    final disabled = _isLoading || _automationInProgress || _jobs.isEmpty;

    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: PopupMenuButton<int>(
          tooltip: 'AutoApply right-swipe',
          onSelected: (value) {
            if (disabled) return;
            _startAutomation(value);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 5, child: Text('5')),
            PopupMenuItem(value: 10, child: Text('10')),
            PopupMenuItem(value: 20, child: Text('20')),
            PopupMenuItem(value: -1, child: Text('All available')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _automationInProgress ? Icons.autorenew : Icons.auto_mode,
                  color: const Color(0xFF6366F1),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _automationInProgress ? 'AutoApplying...' : 'AutoApply',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: LocationAppBar(
            location: _location,
            onLocationTap: () async {
              setState(() {
                _location = _location == 'India' ? 'Remote' : 'India';
              });
              await _loadJobs(); // Reload jobs for new location
            },
            onProfileTap: () {
              // Handle profile tap
            },
          ),
          body: Column(
            children: [
              // Server status indicator
              if (!_isServerHealthy)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Using local data - Server offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              FiltersBar(
                filters: _filters,
                selectedIndex: _selectedFilter,
                onFilterSelected: (index) {
                  setState(() {
                    _selectedFilter = index;
                    _currentJobIndex = 0; // reset view to first filtered item
                  });
                },
              ),

              // Refresh button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jobs (${_filteredJobs().length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    // NEW: Automate + Refresh controls grouped
                    Row(
                      children: [
                        _buildAutomateMenu(themeProvider),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoading ? null : _refreshJobs,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.refresh,
                                  color: themeProvider.primaryTextColor,
                                ),
                          tooltip: 'Refresh jobs',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading amazing jobs for you...',
                              style: TextStyle(
                                color: themeProvider.primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredJobs().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: themeProvider.secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All current jobs viewed',
                              style: TextStyle(
                                color: themeProvider.primaryTextColor,
                              ),
                            ),
                            Text(
                              'Refresh to view more',
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _currentJobIndex < _filteredJobs().length
                    ? GestureDetector(
                        onPanEnd: (details) async {
                          if (details.velocity.pixelsPerSecond.dx > 0) {
                            await _onSwipeRight();
                          } else if (details.velocity.pixelsPerSecond.dx < 0) {
                            _onSwipeLeft(); // left swipe stays sync
                          } else {
                            // No horizontal swipe detected
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DetailedJobCard(
                            job: _filteredJobs()[_currentJobIndex],
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All jobs reviewed!',
                              style: TextStyle(
                                color: themeProvider.primaryTextColor,
                              ),
                            ),
                            Text(
                              'Refresh to see more opportunities',
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _navIndex,
            onTap: (index) {
              setState(() {
                _navIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
