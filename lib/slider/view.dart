// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

part '_drag_proxy.dart';

part '_item.dart';

part '_key.dart';

part '_list.dart';

part '_metrics.dart';

part '_physics.dart';

part '_position.dart';

part '_viewport.dart';

part 'controller.dart';

class SliderView extends StatefulWidget {
  SliderView({
    required List<Widget> children,
    required this.itemsCount,
    required this.onReorder,
    Key? key,
  })  : assert(
          children.every((w) => w.key != null),
          'All children of this widget must have a key.',
        ),
        itemBuilder = ((context, index) => children[index]),
        itemCount = children.length,
        super(key: key);

  final int itemsCount;
  final ReorderCallback onReorder;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  @override
  _SliderViewState createState() => _SliderViewState();
}

class _SliderViewState extends State<SliderView> {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));
    final SliderController controller = SliderController();

    return Scrollable(
      axisDirection: AxisDirection.right,
      controller: controller,
      physics: _Physics(itemsCount: widget.itemsCount),
      scrollBehavior: ScrollConfiguration.of(context)
          .copyWith(scrollbars: false, overscroll: false),
      viewportBuilder: (context, position) => _List(
        itemsCount: widget.itemsCount,
        position: position,
        itemBuilder: (context, index) {
          final Widget item = widget.itemBuilder(context, index);
          assert(item.key != null, 'Every item of must have a key.');
          return _DelayedDragStartListener(
            key: _ViewGlobalKey(item.key!, this),
            index: index,
            child: item,
          );
        },
        itemCount: widget.itemCount,
        onReorder: widget.onReorder,
      ),
    );
  }
}
