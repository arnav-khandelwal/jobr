import 'package:flutter/material.dart';
import 'package:swipe_app/widgets/location_app_bar.dart';
import 'package:swipe_app/widgets/filters_bar.dart';
import 'package:swipe_app/widgets/detailed_job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _location = 'India';
  int _selectedFilter = 0;
  int _navIndex = 0;

  final List<String> _filters = [
    'All',
    'Remote',
    'Full-time',
    'Part-time',
    'Internship',
    'Freelance',
  ];

  final List<Job> _jobs = availableJobs;

  int _currentJobIndex = 0;

  void _onSwipeRight() {
    // Here you would handle the job application logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied to ${_jobs[_currentJobIndex].jobTitle}!'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      if (_currentJobIndex < _jobs.length - 1) {
        _currentJobIndex++;
      }
    });
  }

  void _onSwipeLeft() {
    setState(() {
      if (_currentJobIndex < _jobs.length - 1) {
        _currentJobIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LocationAppBar(
        location: _location,
        onProfileTap: () {
          // Navigate to profile
        },
        onLocationTap: () async {
          // Here you would implement location permission and fetching
          // For now, just toggle between India and Remote
          setState(() {
            _location = _location == 'India' ? 'Remote' : 'India';
          });
        },
      ),
      body: Column(
        children: [
          FiltersBar(
            filters: _filters,
            selectedIndex: _selectedFilter,
            onFilterSelected: (index) {
              setState(() {
                _selectedFilter = index;
              });
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _currentJobIndex < _jobs.length
                ? GestureDetector(
                    onPanEnd: (details) {
                      if (details.velocity.pixelsPerSecond.dx > 0) {
                        _onSwipeRight();
                      } else {
                        _onSwipeLeft();
                      }
                    },
                    child: DetailedJobCard(job: _jobs[_currentJobIndex]),
                  )
                : Center(
                    child: Text(
                      'No more jobs! Check back later.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
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
            // Handle navigation to other screens if needed
          });
        },
      ),
    );
  }
}
