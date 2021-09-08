// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 🌎 Project imports:
import 'position.dart';

class SliderController extends ScrollController {
  SliderController({
    this.initialPage = 0,
    this.keepPage = true,
    this.viewportFraction = 1.0,
  }) : assert(viewportFraction > 0.0);

  final int initialPage;
  final bool keepPage;
  final double viewportFraction;

  double? get page {
    assert(
      positions.isNotEmpty,
      'PageController.page cannot be accessed before a PageView is built with it.',
    );
    assert(
      positions.length == 1,
      'The page property cannot be read when multiple PageViews are attached to '
      'the same PageController.',
    );
    final SliderPosition position = this.position as SliderPosition;
    return position.page;
  }

  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    final SliderPosition position = this.position as SliderPosition;
    return position.animateTo(
      position.getPixelsFromPage(page.toDouble()),
      duration: duration,
      curve: curve,
    );
  }

  void jumpToPage(int page) {
    final SliderPosition position = this.position as SliderPosition;
    position.jumpTo(position.getPixelsFromPage(page.toDouble()));
  }

  Future<void> nextPage({required Duration duration, required Curve curve}) =>
      animateToPage(page!.round() + 1, duration: duration, curve: curve);

  Future<void> previousPage(
          {required Duration duration, required Curve curve}) =>
      animateToPage(page!.round() - 1, duration: duration, curve: curve);

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      SliderPosition(
        physics: physics,
        context: context,
        initialPage: initialPage,
        keepPage: keepPage,
        viewportFraction: viewportFraction,
        oldPosition: oldPosition,
      );

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    (position as SliderPosition).viewportFraction = viewportFraction;
  }
}
