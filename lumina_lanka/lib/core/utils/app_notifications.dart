import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppNotifications {
  static void show({
    required BuildContext context,
    required String message,
    String? title,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _NotificationWidget(
          message: message,
          title: title ?? 'Lumina Lanka',
          icon: icon,
          iconColor: iconColor,
          duration: duration,
          onDismiss: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    Key? key,
    required this.message,
    required this.title,
    this.icon,
    this.iconColor,
    required this.duration,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_isDismissed || !mounted) return;
    _isDismissed = true;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16.0, // Top margin
      left: 0,     // Changed from 24 to 0
      right: 0,    // Changed from 24 to 0 to allow true centering
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -5) {
                      _dismiss();
                    }
                  },
                  onTap: _dismiss,
                  child: Container(
                    // 1. REDUCED MAX WIDTH: Forces it to stay safely between the buttons
                    constraints: const BoxConstraints(maxWidth: 230), 
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(100), 
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Padding(
                          // 2. TIGHTER PADDING
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), 
                          child: Row(
                            mainAxisSize: MainAxisSize.min, 
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                width: 28, 
                                height: 28,
                                decoration: BoxDecoration(
                                  color: (widget.iconColor ?? Colors.white).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.icon ?? CupertinoIcons.bell_fill,
                                  color: widget.iconColor ?? Colors.white,
                                  size: 14, 
                                ),
                              ),
                              // 3. REDUCED SPACING
                              const SizedBox(width: 8), 
                              // Content
                              Flexible( 
                                child: Text(
                                  widget.message,
                                  // 4. CENTERED AND SLIGHTLY SMALLER TEXT
                                  textAlign: TextAlign.center, 
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 12, 
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    height: 1.2, // Keeps lines tight if it wraps
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
