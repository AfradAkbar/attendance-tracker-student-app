import 'package:flutter/material.dart';

/// A premium badge-style ID card widget that displays student information
class StudentIdCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String? registerNumber;
  final String? batchName;
  final String? courseName;
  final String? departmentName;
  final String? startYear;
  final String? endYear;

  const StudentIdCard({
    super.key,
    this.imageUrl,
    required this.name,
    this.registerNumber,
    this.batchName,
    this.courseName,
    this.departmentName,
    this.startYear,
    this.endYear,
  });

  static const Color primaryColor = Color(0xFF5B8A72);
  static const Color cardBgColor = Color(0xFF2D3E50);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgColor,
            cardBgColor.withOpacity(0.9),
            const Color(0xFF1E2A36),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardBgColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.08),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID badge label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.badge_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'STUDENT ID',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    // College/Institution logo placeholder
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'STEMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Main content row
                Row(
                  children: [
                    // Profile photo
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                        color: Colors.grey.shade800,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Info section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Register number
                          if (registerNumber != null &&
                              registerNumber!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                registerNumber!,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Pending Assignment',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Course
                          if (courseName != null && courseName!.isNotEmpty)
                            Text(
                              courseName!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),

                const SizedBox(height: 12),

                // Bottom info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Batch info
                    if (batchName != null && batchName!.isNotEmpty)
                      _buildInfoChip(
                        Icons.class_outlined,
                        batchName!,
                      ),

                    // Academic year
                    if (startYear != null && endYear != null)
                      _buildInfoChip(
                        Icons.calendar_today_outlined,
                        '$startYear - $endYear',
                      ),

                    // Department
                    if (departmentName != null && departmentName!.isNotEmpty)
                      _buildInfoChip(
                        Icons.account_balance_outlined,
                        departmentName!.length > 12
                            ? '${departmentName!.substring(0, 12)}...'
                            : departmentName!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 40,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white54,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
