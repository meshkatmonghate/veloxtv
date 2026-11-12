import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV-first Focusable wrapper for Android TV D-Pad and Desktop Remote Navigation.
/// Automatically handles focus glow, scaling, keyboard events, and scroll into view.
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autoFocus;
  final double scaleFactor;
  final Color glowColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const TvFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.onLongPress,
    this.focusNode,
    this.autoFocus = false,
    this.scaleFactor = 1.05,
    this.glowColor = const Color(0xFF00E5FF), // Cyan neon glow
    this.borderRadius,
    this.padding,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> with SingleTickerProviderStateMixin {
  late FocusNode _node;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_handleFocusChange);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _handleFocusChange() {
    if (_node.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _node.hasFocus;
      });

      if (_isFocused) {
        _animController.forward();
        // Ensure item is visible on TV screen when navigated via D-pad
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _node.dispose();
    } else {
      _node.removeListener(_handleFocusChange);
    }
    _animController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        widget.onSelect?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return Focus(
      focusNode: _node,
      autofocus: widget.autoFocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: _isFocused ? widget.glowColor : Colors.transparent,
                    width: _isFocused ? 2.5 : 1.0,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: widget.glowColor.withOpacity(0.45),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
