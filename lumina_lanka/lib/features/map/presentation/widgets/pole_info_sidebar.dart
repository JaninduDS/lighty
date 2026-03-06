import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../l10n/app_localizations.dart';

class PoleInfoSidebar extends ConsumerStatefulWidget {
  final Map<String, dynamic>? poleData;
  final VoidCallback onClose;
  final VoidCallback onReportTapped;
  final bool isVisible;
  final double leftPosition;

  const PoleInfoSidebar({
    super.key,
    required this.poleData,
    required this.onClose,
    required this.onReportTapped,
    required this.isVisible,
    required this.leftPosition,
  });

  @override
  ConsumerState<PoleInfoSidebar> createState() => _PoleInfoSidebarState();
}

class _PoleInfoSidebarState extends ConsumerState<PoleInfoSidebar> {
  // To handle the opening animation
  double get _currentWidth {
    if (!widget.isVisible || widget.poleData == null) {
      return 0.0;
    }
    return 420.0; 
  }

  List<dynamic> _reports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    if (widget.poleData != null) {
      _fetchReports();
    }
  }

  @override
  void didUpdateWidget(covariant PoleInfoSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the ID changed OR if the sidebar just became visible again
    final idChanged = widget.poleData?['id'] != oldWidget.poleData?['id'];
    final becameVisible = widget.isVisible && !oldWidget.isVisible;
    
    if ((idChanged || becameVisible) && widget.poleData != null) {
      _fetchReports();
    }
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final data = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('pole_id', widget.poleData!['id'])
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _reports = data;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports for pole: $e');
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authentication state to get the user's role
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: widget.leftPosition, // Dynamically adjust based on sidebar state
      top: 16,
      bottom: 16,
      width: _currentWidth,
      child: GlassmorphicContainer(
        width: _currentWidth,
        height: double.infinity,
        borderRadius: 24,
        blur: 14,
        alignment: Alignment.topCenter,
        border: 1.0,
        linearGradient: LinearGradient(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, 1.0),
          colors: [
            const Color(0xFF1E1E1E).withValues(alpha: 0.75), // Dark sleek background 
            const Color(0xFF1E1E1E).withValues(alpha: 0.85),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: (!widget.isVisible || widget.poleData == null)
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    key: ValueKey(widget.poleData?['id'] ?? 'none'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Back Button
                          _buildBackButton(),
                          
                          const SizedBox(height: 16),

                          // Header Title & Subtitle
                          Text(
                            'Street Light #${widget.poleData!['id'].toString().substring(0, 5)}',
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status · ${widget.poleData!['status']}',
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: l10n.directions,
                                  icon: CupertinoIcons.arrow_turn_up_right,
                                  color: const Color(0xFF0A84FF),
                                  textColor: Colors.white,
                                  onTap: () async {
                                    // Open Google Maps / Apple Maps
                                    final lat = widget.poleData!['latitude'];
                                    final lng = widget.poleData!['longitude'];
                                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // If Electrician AND pole is broken, show Resolve instead of Report
                              if (authState.role == AppRole.electrician && widget.poleData!['status'] != 'Working')
                                Expanded(
                                  child: _buildActionButton(
                                    label: l10n.resolve,
                                    icon: CupertinoIcons.checkmark_seal_fill,
                                    color: const Color(0xFF34C759), // Green
                                    textColor: Colors.white,
                                    onTap: () async {
                                      try {
                                        // 1. Update Supabase
                                        await Supabase.instance.client
                                            .from('poles')
                                            .update({'status': 'Working'})
                                            .eq('id', widget.poleData!['id']);
                                            
                                        // 2. Show Success
                                        if (mounted) {
                                          AppNotifications.show(
                                            context: context,
                                            message: 'Pole marked as Working!',
                                            icon: CupertinoIcons.check_mark_circled_solid,
                                            iconColor: const Color(0xFF34C759),
                                          );
                                          widget.onClose();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          AppNotifications.show(
                                            context: context,
                                            message: 'Error: $e',
                                            icon: CupertinoIcons.exclamationmark_triangle_fill,
                                            iconColor: Colors.redAccent,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                )
                              else
                                Expanded(
                                  child: _buildActionButton(
                                    label: l10n.reportAnIssue,
                                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                                    color: Colors.white.withValues(alpha: 0.1),
                                    textColor: Colors.white,
                                    onTap: () {
                                      widget.onReportTapped();
                                    },
                                  ),
                                ),

                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  label: l10n.copyId,
                                  icon: CupertinoIcons.doc_on_clipboard_fill,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  textColor: Colors.white,
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.poleData!['id'].toString()));
                                    AppNotifications.show(
                                      context: context,
                                      message: 'ID Copied',
                                      icon: CupertinoIcons.doc_on_clipboard_fill,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // divider
                          _buildDivider(),

                          const SizedBox(height: 16),
                          
                          // Quick Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('STATUS', style: _labelStyle()),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.poleData!['status'], 
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: _getStatusColor(widget.poleData!['status']),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1, 
                                height: 30, 
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('LAST UPDATED', style: _labelStyle()),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recently', 
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildDivider(),
                          const SizedBox(height: 24),

                          // About Section
                          Text(
                            l10n.about,
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              l10n.aboutDesc,
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Details Section
                          Text(
                            l10n.details,
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(l10n.latitude, widget.poleData!['latitude'].toStringAsFixed(6)),
                                _buildDivider(),
                                _buildDetailRow(l10n.longitude, widget.poleData!['longitude'].toStringAsFixed(6)),
                                _buildDivider(),
                                _buildDetailRow(l10n.powerDraw, _formatBulbType(widget.poleData!['bulb_type'] as String?)),
                                _buildDivider(),
                                _buildDetailRow(l10n.poleType, _formatPoleType(widget.poleData!['pole_type'] as String?), isLast: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // === RECENT REPORTS SECTION ===
                          Text(
                            l10n.recentReports,
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (_isLoadingReports)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                              ),
                            )
                          else if (_reports.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'No issues reported for this pole.',
                                style: TextStyle(
                                  fontFamily: 'GoogleSansFlex',
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: _reports.length,
                                separatorBuilder: (context, index) => _buildDivider(),
                                itemBuilder: (context, index) {
                                  final report = _reports[index];
                                  final isPending = report['status'] == 'Pending';
                                  
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isPending ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.check_mark_circled_solid,
                                              color: isPending ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                report['issue_type'] ?? 'Unknown Issue',
                                                style: const TextStyle(
                                                  fontFamily: 'GoogleSansFlex',
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              report['status'],
                                              style: TextStyle(
                                                fontFamily: 'GoogleSansFlex',
                                                color: isPending ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Reported by ${report['name'] ?? 'Anonymous'}',
                                          style: TextStyle(
                                            fontFamily: 'GoogleSansFlex',
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                        
                                        // === SHOW IMAGE IF IT EXISTS ===
                                        if (report['image_url'] != null) ...[
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              report['image_url'],
                                              width: double.infinity,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  height: 150,
                                                  color: Colors.white.withOpacity(0.05),
                                                  child: const Center(child: CupertinoActivityIndicator()),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 100,
                                                  color: Colors.white.withOpacity(0.05),
                                                  child: const Center(
                                                    child: Icon(CupertinoIcons.photo, color: Colors.white38),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onClose();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.chevron_back,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontFamily: 'GoogleSansFlex',
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Working': return const Color(0xFF34C759);
      case 'Reported': return const Color(0xFFFF3B30);
      case 'Maintenance': return const Color(0xFFFF9500);
      default: return Colors.white;
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  String _formatBulbType(String? type) {
    if (type == null || type.isEmpty) return 'N/A';
    if (type == 'led_30w') return '30W LED';
    if (type == 'led_50w') return '50W LED';
    if (type == 'sodium') return 'Sodium Vapor';
    if (type == 'cfl') return 'CFL';
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatPoleType(String? type) {
    if (type == null || type.isEmpty) return 'N/A';
    if (type == 'concrete') return 'Concrete';
    if (type == 'iron') return 'Iron';
    return type[0].toUpperCase() + type.substring(1);
  }
}
