import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _autoApply = false;
  String _preferredLocation = 'Bangalore';
  String _salaryRange = '₹10L - ₹20L';
  String _jobTypes = 'Full-time, Remote';
  String _experience = '2-5 years';
  List<String> _selectedSkills = ['Flutter', 'Dart'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Job Preferences',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Preferences
            _buildSectionHeader('Location Preferences'),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.location_on,
                  title: 'Preferred Location',
                  subtitle: _preferredLocation,
                  onTap: () => _showLocationPicker(),
                ),
                _buildSettingsTile(
                  icon: Icons.work_outline,
                  title: 'Work Type',
                  subtitle: 'Remote, Hybrid, On-site',
                  onTap: () => _showWorkTypePicker(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Salary & Compensation
            _buildSectionHeader('Salary & Compensation'),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.attach_money,
                  title: 'Salary Range',
                  subtitle: _salaryRange,
                  onTap: () => _showSalaryPicker(),
                ),
                _buildSettingsTile(
                  icon: Icons.business_center,
                  title: 'Benefits',
                  subtitle: 'Health insurance, PTO',
                  onTap: () => _showBenefitsPicker(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Job Details
            _buildSectionHeader('Job Details'),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.work,
                  title: 'Job Types',
                  subtitle: _jobTypes,
                  onTap: () => _showJobTypesPicker(),
                ),
                _buildSettingsTile(
                  icon: Icons.timeline,
                  title: 'Experience Level',
                  subtitle: _experience,
                  onTap: () => _showExperiencePicker(),
                ),
                _buildSettingsTile(
                  icon: Icons.code,
                  title: 'Skills & Technologies',
                  subtitle: _selectedSkills.join(', '),
                  onTap: () => _showSkillsPicker(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Automation
            _buildSectionHeader('Automation'),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.auto_awesome,
                  title: 'Auto Apply',
                  subtitle: 'Automatically apply to jobs matching your preferences',
                  value: _autoApply,
                  onChanged: (value) {
                    setState(() {
                      _autoApply = value;
                    });
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.schedule,
                  title: 'Application Schedule',
                  subtitle: 'Weekdays, 9 AM - 6 PM',
                  onTap: () => _showSchedulePicker(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _savePreferences();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildPreferenceCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6366F1),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Preferred Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ...[
              'Bangalore',
              'Mumbai',
              'Delhi',
              'Hyderabad',
              'Chennai',
              'Pune',
              'Remote',
              'Any Location',
            ].map(
              (location) => ListTile(
                title: Text(location),
                trailing: _preferredLocation == location
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() {
                    _preferredLocation = location;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSalaryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Salary Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ...[
              '₹3L - ₹5L',
              '₹5L - ₹10L',
              '₹10L - ₹20L',
              '₹20L - ₹30L',
              '₹30L - ₹50L',
              '₹50L+',
            ].map(
              (range) => ListTile(
                title: Text(range),
                trailing: _salaryRange == range
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() {
                    _salaryRange = range;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJobTypesPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Job Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ...[
              'Full-time',
              'Part-time',
              'Contract',
              'Freelance',
              'Internship',
              'Remote',
            ].map(
              (type) => ListTile(
                title: Text(type),
                onTap: () {
                  setState(() {
                    _jobTypes = type;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkTypePicker() {
    // Implementation for work type picker
  }

  void _showBenefitsPicker() {
    // Implementation for benefits picker
  }

  void _showExperiencePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Experience Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ...[
              'Entry Level (0-2 years)',
              'Mid Level (2-5 years)',
              'Senior Level (5-10 years)',
              'Lead/Principal (10+ years)',
            ].map(
              (level) => ListTile(
                title: Text(level),
                trailing: _experience == level
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() {
                    _experience = level;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkillsPicker() {
    // Implementation for skills picker
  }

  void _showSchedulePicker() {
    // Implementation for schedule picker
  }

  void _savePreferences() {
    // Save preferences to backend/storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
