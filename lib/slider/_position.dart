part of 'view.dart';

class _Position extends ScrollPositionWithSingleContext implements _Metrics {
  _Position({
    required ScrollPhysics physics,
    required ScrollContext context,
    ScrollPosition? oldPosition,
  }) : super(
          physics: physics,
          context: context,
          initialPixels: null,
          keepScrollOffset: true,
          oldPosition: oldPosition,
        );

  @override
  Future<void> ensureVisible(
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    RenderObject? targetRenderObject,
  }) =>
      super.ensureVisible(
        object,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
      );

  double getPageFromPixels(double pixels, double viewportDimension) {
    final double actual =
        math.max(0, pixels) / math.max(1.0, viewportDimension);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions =
        hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);
    final double? oldPixels = hasPixels ? pixels : null;
    final double page = oldPixels == null || oldViewportDimensions == 0.0
        ? 0
        : getPageFromPixels(oldPixels, oldViewportDimensions!);

    final double newPixels = page * viewportDimension;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  _Metrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
  }) =>
      _Metrics(
        minScrollExtent: minScrollExtent ??
            (hasContentDimensions ? this.minScrollExtent : null),
        maxScrollExtent: maxScrollExtent ??
            (hasContentDimensions ? this.maxScrollExtent : null),
        pixels: pixels ?? (hasPixels ? this.pixels : null),
        viewportDimension: viewportDimension ??
            (hasViewportDimension ? this.viewportDimension : null),
        axisDirection: axisDirection ?? this.axisDirection,
      );
}
