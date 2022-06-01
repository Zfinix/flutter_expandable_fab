library flutter_expandable_fab;

import 'dart:math' as math;

import 'package:flutter/material.dart';

// Inspired by this article.
// https://docs.flutter.dev/cookbook/effects/expandable-fab

/// The type of behavior of this widget.
enum ExpandableFabType { fan, up, left }

/// Style of the close button.
@immutable
class ExpandableFabCloseButtonStyle {
  const ExpandableFabCloseButtonStyle({
    this.child = const Icon(Icons.close),
    this.foregroundColor,
    this.backgroundColor,
  });

  /// The widget below the close button widget in the tree.
  final Widget child;

  /// The default foreground color for icons and text within the button.
  final Color? foregroundColor;

  /// The button's background color.
  final Color? backgroundColor;
}

/// Fab button that can show/hide multiple action buttons with animation.
@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    Key? key,
    this.distance = 100,
    this.duration = const Duration(milliseconds: 250),
    this.fanAngle = 90,
    this.initialOpen = false,
    this.type = ExpandableFabType.fan,
    this.closeButtonStyle = const ExpandableFabCloseButtonStyle(),
    this.foregroundColor,
    this.backgroundColor,
    this.child = const Icon(Icons.menu),
    this.childrenOffset = const Offset(8, 8),
    required this.children,
  }) : super(key: key);

  /// Distance from children.
  final double distance;

  /// Animation duration.
  final Duration duration;

  /// Angle of opening when fan type.
  final double fanAngle;

  /// Open at initial display.
  final bool initialOpen;

  /// The type of behavior of this widget.
  final ExpandableFabType type;

  /// Style of the close button.
  final ExpandableFabCloseButtonStyle closeButtonStyle;

  /// The widget below this widget in the tree.
  final Widget child;

  /// For positioning of children widgets.
  final Offset childrenOffset;

  /// The widgets below this widget in the tree.
  final List<Widget> children;

  /// The default foreground color for icons and text within the button.
  final Color? foregroundColor;

  /// The button's background color.
  final Color? backgroundColor;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: widget.duration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    final style = widget.closeButtonStyle;
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: FloatingActionButton.small(
          heroTag: null,
          foregroundColor: style.foregroundColor,
          backgroundColor: style.backgroundColor,
          onPressed: _toggle,
          child: style.child,
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = widget.fanAngle / (count - 1);
    for (var i = 0; i < count; i++) {
      final double dir, dist;
      switch (widget.type) {
        case ExpandableFabType.fan:
          dir = step * i;
          dist = widget.distance;
          break;
        case ExpandableFabType.up:
          dir = 90;
          dist = widget.distance * (i + 1);
          break;
        case ExpandableFabType.left:
          dir = 0;
          dist = widget.distance * (i + 1);
          break;
      }
      children.add(
        _ExpandingActionButton(
          directionInDegrees: dir + (90 - widget.fanAngle) / 2,
          maxDistance: dist,
          progress: _expandAnimation,
          offset: widget.childrenOffset,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    final duration = widget.duration;
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: duration,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: duration,
          child: FloatingActionButton(
            heroTag: null,
            foregroundColor: widget.foregroundColor,
            backgroundColor: widget.backgroundColor,
            onPressed: _toggle,
            child: AnimatedRotation(
              duration: duration,
              turns: _open ? -0.5 : 0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.offset,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final pos = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: offset.dx + pos.dx,
          bottom: offset.dy + pos.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}