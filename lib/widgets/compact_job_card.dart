import 'package:flutter/material.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';

class CompactJobCard extends StatelessWidget {
  final Job job;
  final String status;
  final Function(String)? onStatusChanged; // Add callback for status change

  const CompactJobCard({
    super.key,
    required this.job,
    required this.status,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.postedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusDropdown(), // Changed from badge to dropdown
              ],
            ),
            const SizedBox(height: 12),

            // Job Title
            Text(
              job.jobTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Location and Salary Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.location_on,
                    text: job.location,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.attach_money,
                    text: job.salary,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Job Type and Experience
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.work_outline,
                    text: job.jobType,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.schedule,
                    text: job.experienceRequired,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Description',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.jobDescription,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Skills Preview
            if (job.skills.isNotEmpty) ...[
              Text(
                'Skills',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              _buildSkillsPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final List<String> statusOptions = ['pending', 'accepted', 'rejected'];
    
    return PopupMenuButton<String>(
      onSelected: (String newStatus) {
        if (onStatusChanged != null) {
          onStatusChanged!(newStatus);
        }
      },
      itemBuilder: (BuildContext context) {
        return statusOptions.map((String statusOption) {
          final color = _getStatusColorForOption(statusOption);
          final icon = _getStatusIconForOption(statusOption);
          final isSelected = statusOption == status;
          
          return PopupMenuItem<String>(
            value: statusOption,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusDisplayName(statusOption),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? color : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: color,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getStatusColor().withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(), size: 14, color: _getStatusColor()),
            const SizedBox(width: 6),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: _getStatusColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsPreview() {
    final displaySkills = job.skills.take(3).toList();
    final hasMoreSkills = job.skills.length > 3;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...displaySkills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E293B).withOpacity(0.2),
              ),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          );
        }),
        if (hasMoreSkills)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF64748B).withOpacity(0.2),
              ),
            ),
            child: Text(
              '+${job.skills.length - 3}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor() {
    return _getStatusColorForOption(status);
  }

  IconData _getStatusIcon() {
    return _getStatusIconForOption(status);
  }

  Color _getStatusColorForOption(String statusOption) {
    switch (statusOption.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIconForOption(String statusOption) {
    switch (statusOption.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.access_time;
    }
  }

  String _getStatusDisplayName(String statusOption) {
    switch (statusOption.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}