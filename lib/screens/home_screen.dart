import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/location_app_bar.dart';
import 'package:swipe_app/widgets/filters_bar.dart';
import 'package:swipe_app/widgets/detailed_job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'package:swipe_app/services/job_api_service.dart';

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

  final List<String> _filters = [
    'All',
    'Remote',
    'Full-time',
    'Part-time',
    'Internship',
    'Freelance',
  ];

  List<Job> _jobs = [];
  int _currentJobIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _checkServerHealth();
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

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _currentJobIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _jobs = availableJobs; // Fallback to local data
          _isLoading = false;
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

  void _onSwipeRight() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied to ${_jobs[_currentJobIndex].jobTitle}!'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      if (_currentJobIndex < _jobs.length - 1) {
        _currentJobIndex++;
      } else {
        _currentJobIndex = 0; // Reset to first job
      }
    });
  }

  void _onSwipeLeft() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skipped ${_jobs[_currentJobIndex].jobTitle}'),
        backgroundColor: Colors.grey,
      ),
    );
    setState(() {
      if (_currentJobIndex < _jobs.length - 1) {
        _currentJobIndex++;
      } else {
        _currentJobIndex = 0; // Reset to first job
      }
    });
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
                      Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
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
                  });
                },
              ),

              // Refresh button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jobs (${_jobs.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _refreshJobs,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, color: themeProvider.primaryTextColor),
                      tooltip: 'Refresh jobs',
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
                              style: TextStyle(color: themeProvider.primaryTextColor),
                            ),
                          ],
                        ),
                      )
                    : _jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_off, size: 64, color: themeProvider.secondaryTextColor),
                            const SizedBox(height: 16),
                            Text(
                              'No jobs found',
                              style: TextStyle(color: themeProvider.primaryTextColor),
                            ),
                            Text(
                              'Try refreshing or change your filters',
                              style: TextStyle(color: themeProvider.secondaryTextColor),
                            ),
                          ],
                        ),
                      )
                    : _currentJobIndex < _jobs.length
                    ? GestureDetector(
                        onPanEnd: (details) {
                          if (details.velocity.pixelsPerSecond.dx > 0) {
                            _onSwipeRight();
                          } else {
                            _onSwipeLeft();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DetailedJobCard(job: _jobs[_currentJobIndex]),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 64, color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              'All jobs reviewed!',
                              style: TextStyle(color: themeProvider.primaryTextColor),
                            ),
                            Text(
                              'Refresh to see more opportunities',
                              style: TextStyle(color: themeProvider.secondaryTextColor),
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
