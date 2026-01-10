import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FloatingMessageType { success, error, info, warning }

class FloatingMessage {
  static OverlayEntry? _entry;
  static Timer? _timer;
  static final ValueNotifier<String> _messageNotifier = ValueNotifier<String>("");

  static void show(
      BuildContext context, {
        required String message,
        FloatingMessageType type = FloatingMessageType.info,
        Duration duration = const Duration(seconds: 2),
        bool fromTop = false,
        IconData? icon,
        Color? backgroundColor,
        Color? textColor,
        double horizontalMargin = 16,
        double verticalMargin = 24,
        double borderRadius = 12,
      }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // If already showing, just update message + reset timer
    if (_entry != null) {
      update(message, duration: duration);
      return;
    }

    final colors = _typeColors(type);
    final bg = backgroundColor ?? colors.$1;
    final fg = textColor ?? colors.$2;
    final ic = icon ?? colors.$3;

    _messageNotifier.value = message;

    _entry = OverlayEntry(
      builder: (_) => _FloatingMessageWidget(
        messageListenable: _messageNotifier,
        bg: bg,
        fg: fg,
        icon: ic,
        fromTop: fromTop,
        horizontalMargin: horizontalMargin,
        verticalMargin: verticalMargin,
        borderRadius: borderRadius,
      ),
    );

    overlay.insert(_entry!);

    _timer?.cancel();
    _timer = Timer(duration, hide);
  }

  /// ✅ Update text without removing overlay (no flicker)
  static void update(String message, {Duration? duration}) {
    if (_entry == null) return;

    _messageNotifier.value = message;

    if (duration != null) {
      _timer?.cancel();
      _timer = Timer(duration, hide);
    }
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static (Color, Color, IconData) _typeColors(FloatingMessageType t) {
    switch (t) {
      case FloatingMessageType.success:
        return (const Color(0xFF3FAF58), Colors.white, Icons.check_circle);
      case FloatingMessageType.error:
        return (const Color(0xFFDA5747), Colors.white, Icons.error);
      case FloatingMessageType.warning:
        return (const Color(0xFFF8B10F), Colors.black, Icons.warning);
      case FloatingMessageType.info:
      default:
        return (const Color(0xFF252525), Colors.white, Icons.info);
    }
  }
}

class _FloatingMessageWidget extends StatefulWidget {
  final ValueListenable<String> messageListenable;
  final Color bg;
  final Color fg;
  final IconData icon;
  final bool fromTop;
  final double horizontalMargin;
  final double verticalMargin;
  final double borderRadius;

  const _FloatingMessageWidget({
    required this.messageListenable,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.fromTop,
    required this.horizontalMargin,
    required this.verticalMargin,
    required this.borderRadius,
  });

  @override
  State<_FloatingMessageWidget> createState() => _FloatingMessageWidgetState();
}

class _FloatingMessageWidgetState extends State<_FloatingMessageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.fromTop ? -0.2 : 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Positioned(
      left: widget.horizontalMargin,
      right: widget.horizontalMargin,
      top: widget.fromTop ? (media.padding.top + widget.verticalMargin) : null,
      bottom: widget.fromTop ? null : (media.padding.bottom + widget.verticalMargin),
      child: SafeArea(
        child: IgnorePointer(
          ignoring: true,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.bg,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.fg, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: widget.messageListenable,
                          builder: (_, msg, __) {
                            return Text(
                              msg,
                              style: GoogleFonts.poppins(
                                color: widget.fg,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.20,
                              ),
                            );
                          },
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
    );
  }
}
