import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/widgets/login_dialog.dart';
import '../../features/dashboard/presentation/council_dashboard.dart';
import '../../features/dashboard/presentation/staff_management_screen.dart';
import '../../features/tasks/presentation/electrician_tasks_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

class MobileGlassDrawer extends ConsumerWidget {
  const MobileGlassDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.user != null;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16, // Floating effect
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(10, 10),
            ),
          ],
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 40,
          blur: 45, // Flighty heavy blur
          alignment: Alignment.topCenter,
          border: 1.0,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  const Color(0xFF1C1C1E).withOpacity(0.75),
                  const Color(0xFF121212).withOpacity(0.65),
                ]
              : [
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.80),
                ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
              ? [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)]
              : [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.02)],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header / Profile Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isLoggedIn ? const Color(0xFF0A84FF).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: isLoggedIn ? const Color(0xFF0A84FF) : Colors.white.withOpacity(0.2)),
                        ),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          color: isLoggedIn ? const Color(0xFF0A84FF) : Colors.white70,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn ? (authState.user?.email?.split('@')[0] ?? 'User') : 'Guest',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isLoggedIn ? authState.role.name.toUpperCase() : 'Public User',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                ),

                // Navigation Links
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      if (authState.role == AppRole.council) ...[
                        _buildDrawerItem(
                          context, 
                          icon: CupertinoIcons.chart_bar_alt_fill, 
                          color: const Color(0xFF34C759), 
                          title: l10n.councilDashboard, 
                          onTap: () { 
                            Navigator.pop(context); // Close drawer
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CouncilDashboard())); 
                          }
                        ),
                        _buildDrawerItem(
                          context, 
                          icon: CupertinoIcons.person_2_alt, 
                          color: const Color(0xFF9E47FF), 
                          title: l10n.manageStaff, 
                          onTap: () { 
                            Navigator.pop(context); 
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())); 
                          }
                        ),
                      ],
                      if (authState.role == AppRole.electrician) ...[
                        _buildDrawerItem(
                          context, 
                          icon: CupertinoIcons.bolt_fill, 
                          color: const Color(0xFFFFCC00), 
                          title: l10n.myTasks, 
                          onTap: () { 
                            Navigator.pop(context); 
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectricianTasksScreen())); 
                          }
                        ),
                      ],
                      
                      _buildDrawerItem(
                        context, 
                        icon: CupertinoIcons.settings, 
                        color: Colors.grey, 
                        title: l10n.settings, 
                        onTap: () { 
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); 
                        }
                      ),
                    ],
                  ),
                ),

                // Bottom Login/Logout Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: isLoggedIn
                      ? _buildDrawerItem(context, icon: CupertinoIcons.square_arrow_right, color: const Color(0xFFFF3B30), title: l10n.logOut, isLogout: true, onTap: () {
                          HapticFeedback.mediumImpact();
                          ref.read(authProvider.notifier).signOut();
                          Navigator.pop(context);
                        })
                      : Column(
                          children: [
                            _buildDrawerItem(context, icon: CupertinoIcons.person_solid, color: const Color(0xFF0A84FF), title: l10n.publicLogin, onTap: () {
                              Navigator.pop(context);
                              showDialog(context: context, builder: (_) => const LoginDialog(isStaffMode: false));
                            }),
                            _buildDrawerItem(context, icon: CupertinoIcons.briefcase_fill, color: const Color(0xFFFF9500), title: l10n.staffLogin, onTap: () {
                              Navigator.pop(context);
                              showDialog(context: context, builder: (_) => const LoginDialog(isStaffMode: true));
                            }),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required Color color, required String title, required VoidCallback onTap, bool isLogout = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    color: isLogout ? const Color(0xFFFF3B30) : (isDark ? Colors.white : Colors.black87),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: isDark ? Colors.white38 : Colors.black38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}