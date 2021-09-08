// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 🌎 Project imports:
import 'position.dart';

class SliderPhysics extends ScrollPhysics {
  const SliderPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  SliderPhysics applyTo(ScrollPhysics? ancestor) =>
      SliderPhysics(parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (position.pixels <= position.minScrollExtent &&
        value < position.pixels) {
      return value - position.pixels;
    }
    if (position.pixels >= position.maxScrollExtent &&
        value > position.pixels) {
      return value - position.pixels;
    }
    if (position.pixels > position.minScrollExtent &&
        value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent &&
        value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return 0;
  }

  @override
  double get maxFlingVelocity => 1400;

  double _getPage(ScrollMetrics position) {
    if (position is SliderPosition) {
      return position.page!;
    }
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    if (position is SliderPosition) {
      return position.getPixelsFromPage(page);
    }
    return page * position.viewportDimension;
  }

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return _getPixels(position, page.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = this.tolerance;
    double target = _getTargetPixels(position, tolerance, velocity);

    // new physics
    final double distance = 200 *
        math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) *
        velocity.sign;
    const int itemsCount = 3;
    final double itemSize = position.viewportDimension / itemsCount;
    final int itemPosition = ((position.pixels + distance) / itemSize).round();
    target = itemPosition * itemSize;

    if (target == position.pixels) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
