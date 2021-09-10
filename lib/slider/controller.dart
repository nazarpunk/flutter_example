part of 'view.dart';

class SliderController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      _Position(
        physics: physics,
        context: context,
        oldPosition: oldPosition,
      );
}
