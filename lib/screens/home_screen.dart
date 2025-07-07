import 'package:flutter/material.dart';
import 'package:swipe_app/widgets/location_app_bar.dart';
import 'package:swipe_app/widgets/filters_bar.dart';
import 'package:swipe_app/widgets/job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';

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

  final List<Map<String, String>> _jobs = [
    {
      'title': 'Flutter Developer',
      'company': 'Techify',
      'location': 'Bangalore',
      'salary': '₹12L - ₹18L',
      'description':
          'Build beautiful mobile apps with Flutter. 2+ years experience required.',
    },
    {
      'title': 'UI/UX Designer',
      'company': 'DesignPro',
      'location': 'Remote',
      'salary': '₹8L - ₹14L',
      'description': 'Design intuitive user interfaces for web and mobile.',
    },
    {
      'title': 'Backend Engineer',
      'company': 'CloudBase',
      'location': 'Hyderabad',
      'salary': '₹15L - ₹22L',
      'description': 'Work on scalable backend systems using Node.js and AWS.',
    },
  ];

  int _currentJobIndex = 0;

  void _onSwipeRight() {
    // Here you would handle the job application logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied to ${_jobs[_currentJobIndex]['title']}!'),
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
                    child: JobCard(
                      title: _jobs[_currentJobIndex]['title']!,
                      company: _jobs[_currentJobIndex]['company']!,
                      location: _jobs[_currentJobIndex]['location']!,
                      salary: _jobs[_currentJobIndex]['salary']!,
                      description: _jobs[_currentJobIndex]['description']!,
                    ),
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
