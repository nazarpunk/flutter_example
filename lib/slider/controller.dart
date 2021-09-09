part of 'view.dart';

class SliderController extends ScrollController {
  SliderController({
    this.initialPage = 0,
    this.viewportFraction = 1.0,
  }) : assert(viewportFraction > 0.0);

  final int initialPage;
  final double viewportFraction;

  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    final _Position position = this.position as _Position;
    return position.animateTo(
      position.getPixelsFromPage(page.toDouble()),
      duration: duration,
      curve: curve,
    );
  }

  void jumpToPage(int page) {
    final _Position position = this.position as _Position;
    position.jumpTo(position.getPixelsFromPage(page.toDouble()));
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      _Position(
        physics: physics,
        context: context,
        initialPage: initialPage,
        viewportFraction: viewportFraction,
        oldPosition: oldPosition,
      );

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    (position as _Position).viewportFraction = viewportFraction;
  }
}
