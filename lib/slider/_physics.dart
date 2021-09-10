part of 'view.dart';

class _Physics extends ScrollPhysics {
  const _Physics({required this.itemsCount, ScrollPhysics? parent})
      : super(parent: parent);

  final int itemsCount;

  @override
  _Physics applyTo(ScrollPhysics? ancestor) =>
      _Physics(itemsCount: itemsCount, parent: buildParent(ancestor));

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

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = position.pixels / position.viewportDimension;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return page * position.viewportDimension;
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
