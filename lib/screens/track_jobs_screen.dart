import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/compact_job_card.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';

class TrackJobsScreen extends StatefulWidget {
  const TrackJobsScreen({super.key});

  @override
  State<TrackJobsScreen> createState() => _TrackJobsScreenState();
}

class _TrackJobsScreenState extends State<TrackJobsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 2; // Track tab index

  // Sample application data with status (now mutable)
  List<Map<String, dynamic>> _applications = [
    {
      'job': availableJobs[0],
      'status': 'pending',
      'appliedDate': '2 days ago',
      'id': 'app_1',
    },
    {
      'job': availableJobs[1],
      'status': 'accepted',
      'appliedDate': '1 week ago',
      'id': 'app_2',
    },
    {
      'job': availableJobs[2],
      'status': 'rejected',
      'appliedDate': '3 days ago',
      'id': 'app_3',
    },
    {
      'job': availableJobs[3],
      'status': 'pending',
      'appliedDate': '5 days ago',
      'id': 'app_4',
    },
    {
      'job': availableJobs[4],
      'status': 'accepted',
      'appliedDate': '2 weeks ago',
      'id': 'app_5',
    },
    {
      'job': availableJobs[5],
      'status': 'pending',
      'appliedDate': '1 day ago',
      'id': 'app_6',
    },
    {
      'job': availableJobs[6],
      'status': 'rejected',
      'appliedDate': '4 days ago',
      'id': 'app_7',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to update application status
  void _updateApplicationStatus(String applicationId, String newStatus) {
    setState(() {
      final applicationIndex = _applications.indexWhere(
        (app) => app['id'] == applicationId,
      );
      if (applicationIndex != -1) {
        _applications[applicationIndex]['status'] = newStatus;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_getStatusIcon(newStatus), color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Status updated to ${newStatus.toUpperCase()}'),
              ],
            ),
            backgroundColor: _getStatusColor(newStatus),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
              'Track Applications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryTextColor,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: themeProvider.primaryTextColor,
                ),
                onPressed: () {
                  _showFilterOptions(themeProvider);
                },
              ),
              // Add refresh button
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: themeProvider.primaryTextColor,
                ),
                onPressed: () {
                  setState(() {}); // Refresh the UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Applications refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: themeProvider.secondaryTextColor,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: 'All (${_applications.length})'),
                Tab(text: 'Pending (${_getPendingCount()})'),
                Tab(text: 'Accepted (${_getAcceptedCount()})'),
                Tab(text: 'Rejected (${_getRejectedCount()})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Stats Overview
              _buildStatsOverview(themeProvider),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApplicationsList(_applications, themeProvider),
                    _buildApplicationsList(
                      _applications
                          .where((app) => app['status'] == 'pending')
                          .toList(),
                      themeProvider,
                    ),
                    _buildApplicationsList(
                      _applications
                          .where((app) => app['status'] == 'accepted')
                          .toList(),
                      themeProvider,
                    ),
                    _buildApplicationsList(
                      _applications
                          .where((app) => app['status'] == 'rejected')
                          .toList(),
                      themeProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _navIndex,
            onTap: (index) {
              if (index != _navIndex) {
                Navigator.pop(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsOverview(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Applied',
              '${_applications.length}',
              Icons.send,
              const Color(0xFF6366F1),
              themeProvider,
            ),
          ),
          Container(width: 1, height: 40, color: themeProvider.borderColor),
          Expanded(
            child: _buildStatItem(
              'Success Rate',
              _applications.isNotEmpty
                  ? '${((_getAcceptedCount() / _applications.length) * 100).toInt()}%'
                  : '0%',
              Icons.trending_up,
              const Color(0xFF10B981),
              themeProvider,
            ),
          ),
          Container(width: 1, height: 40, color: themeProvider.borderColor),
          Expanded(
            child: _buildStatItem(
              'Pending',
              '${_getPendingCount()}',
              Icons.access_time,
              const Color(0xFFF59E0B),
              themeProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeProvider.primaryTextColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildApplicationsList(
    List<Map<String, dynamic>> applications,
    ThemeProvider themeProvider,
  ) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: themeProvider.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No applications found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: themeProvider.primaryTextColor,
              ),
            ),
            Text(
              'Start applying to jobs to track them here',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return GestureDetector(
          onTap: () {
            _showApplicationDetails(application, themeProvider);
          },
          child: CompactJobCard(
            job: application['job'],
            status: application['status'],
            onStatusChanged: (newStatus) {
              _updateApplicationStatus(application['id'], newStatus);
            },
          ),
        );
      },
    );
  }

  void _showApplicationDetails(
    Map<String, dynamic> application,
    ThemeProvider themeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeProvider.secondaryTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Application Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryTextColor,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompactJobCard(
                      job: application['job'],
                      status: application['status'],
                      onStatusChanged: (newStatus) {
                        _updateApplicationStatus(application['id'], newStatus);
                        Navigator.pop(
                          context,
                        ); // Close the modal after status change
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Application Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimelineItem(
                      'Applied',
                      application['appliedDate'],
                      true,
                      themeProvider,
                    ),
                    if (application['status'] == 'accepted')
                      _buildTimelineItem(
                        'Accepted',
                        '1 day ago',
                        true,
                        themeProvider,
                      ),
                    if (application['status'] == 'rejected')
                      _buildTimelineItem(
                        'Rejected',
                        '1 day ago',
                        true,
                        themeProvider,
                      ),
                    if (application['status'] == 'pending')
                      _buildTimelineItem(
                        'Under Review',
                        'Pending',
                        false,
                        themeProvider,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    bool isCompleted,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : themeProvider.secondaryTextColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.access_time,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryTextColor,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.date_range, color: Color(0xFF6366F1)),
              title: Text(
                'By Date',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Color(0xFF6366F1)),
              title: Text(
                'By Company',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.work, color: Color(0xFF6366F1)),
              title: Text(
                'By Job Type',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for status handling
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.access_time;
    }
  }

  int _getPendingCount() =>
      _applications.where((app) => app['status'] == 'pending').length;
  int _getAcceptedCount() =>
      _applications.where((app) => app['status'] == 'accepted').length;
  int _getRejectedCount() =>
      _applications.where((app) => app['status'] == 'rejected').length;
}
