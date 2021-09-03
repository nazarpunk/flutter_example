import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

class SliderScrollPhysics extends ScrollPhysics {
  const SliderScrollPhysics({required this.itemsCount, ScrollPhysics? parent})
      : super(parent: parent);

  @override
  SliderScrollPhysics applyTo(ScrollPhysics? ancestor) => SliderScrollPhysics(
      parent: buildParent(ancestor), itemsCount: itemsCount);

  @override
  double get maxFlingVelocity => 1400;

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

  final int itemsCount;

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;

    final double distance = 200 *
        math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) *
        velocity.sign;

    final double _itemSize = position.viewportDimension / itemsCount;
    final int _itemCurrent = ((position.pixels + distance) / _itemSize).round();
    double _end = _itemCurrent * _itemSize;

    if (position.outOfRange) {
      if (position.pixels > position.maxScrollExtent) {
        _end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        _end = position.minScrollExtent;
      }
    }

    if (velocity.abs() < tolerance.velocity &&
        position.pixels.round() == _end.round()) {
      return null;
    }

    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      _end,
      velocity,
      tolerance: tolerance,
    );
  }
}
