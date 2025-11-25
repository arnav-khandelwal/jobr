import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/compact_job_card.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';
import 'package:swipe_app/services/applications_service.dart';

class TrackJobsScreen extends StatefulWidget {
  const TrackJobsScreen({super.key});

  @override
  State<TrackJobsScreen> createState() => _TrackJobsScreenState();
}

class _TrackJobsScreenState extends State<TrackJobsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 2; // Track tab index
  bool _loading = true;
  List<ApplicationRecord> _applications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    final records = await ApplicationsService.instance.fetchApplications();
    if (!mounted) return;
    setState(() {
      _applications = records;
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
                onPressed: _loading
                    ? null
                    : () async {
                        await _loadApplications();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Applications refreshed'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildApplicationsList(_applications, themeProvider),
                          _buildApplicationsList(
                            _applications
                                .where((app) => app.status == 'pending')
                                .toList(),
                            themeProvider,
                          ),
                          _buildApplicationsList(
                            _applications
                                .where((app) => app.status == 'accepted')
                                .toList(),
                            themeProvider,
                          ),
                          _buildApplicationsList(
                            _applications
                                .where((app) => app.status == 'rejected')
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
    List<ApplicationRecord> applications,
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
            job: application.jobSnapshot,
            status: application.status,
            onStatusChanged: (_) {}, // status changes not yet supported
          ),
        );
      },
    );
  }

  void _showApplicationDetails(
    ApplicationRecord application,
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
                      job: application.jobSnapshot,
                      status: application.status,
                      onStatusChanged: (_) {},
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
                      _relativeTime(application.appliedAt),
                      true,
                      themeProvider,
                    ),
                    if (application.status == 'accepted')
                      _buildTimelineItem(
                        'Accepted',
                        'Recently',
                        true,
                        themeProvider,
                      ),
                    if (application.status == 'rejected')
                      _buildTimelineItem(
                        'Rejected',
                        'Recently',
                        true,
                        themeProvider,
                      ),
                    if (application.status == 'pending')
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

  int _getPendingCount() =>
      _applications.where((app) => app.status == 'pending').length;
  int _getAcceptedCount() =>
      _applications.where((app) => app.status == 'accepted').length;
  int _getRejectedCount() =>
      _applications.where((app) => app.status == 'rejected').length;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
