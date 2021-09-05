import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'physics.dart';

class SliderViewReorderable extends StatefulWidget {
  SliderViewReorderable({
    required List<Widget> children,
    required this.onReorder,
    Key? key,
    this.proxyDecorator,
    this.scrollDirection = Axis.horizontal,
    this.controller,
    this.primary,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  })  : assert(
          children.every((w) => w.key != null),
          'All children of this widget must have a key.',
        ),
        itemBuilder = ((context, index) => children[index]),
        itemCount = children.length,
        super(key: key);

  const SliderViewReorderable.builder({
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    Key? key,
    this.proxyDecorator,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.primary,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  })  : assert(itemCount >= 0),
        super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ReorderCallback onReorder;
  final ReorderItemProxyDecorator? proxyDecorator;
  final Axis scrollDirection;
  final ScrollController? controller;
  final bool? primary;
  final bool shrinkWrap;
  final double anchor;
  final double? cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  @override
  _SliderViewReorderableState createState() => _SliderViewReorderableState();
}

class _SliderViewReorderableState extends State<SliderViewReorderable> {
  Widget _wrapWithSemantics(Widget child, int index) {
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder(startIndex, endIndex);
      }
    }

    final Map<CustomSemanticsAction, VoidCallback> semanticsActions =
        <CustomSemanticsAction, VoidCallback>{};

    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, widget.itemCount);
    void moveBefore() => reorder(index, index - 1);
    void moveAfter() => reorder(index, index + 2);

    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    if (index > 0) {
      semanticsActions[
              CustomSemanticsAction(label: localizations.reorderItemToStart)] =
          moveToStart;
      String reorderItemBefore = localizations.reorderItemUp;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemBefore = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemLeft
            : localizations.reorderItemRight;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] =
          moveBefore;
    }

    if (index < widget.itemCount - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemAfter = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemRight
            : localizations.reorderItemLeft;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] =
          moveAfter;
      semanticsActions[
              CustomSemanticsAction(label: localizations.reorderItemToEnd)] =
          moveToEnd;
    }

    return MergeSemantics(
      child: Semantics(
        customSemanticsActions: semanticsActions,
        child: child,
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    assert(() {
      if (item.key == null) {
        throw FlutterError(
          'Every item of ReorderableListView must have a key.',
        );
      }
      return true;
    }());

    final Widget itemWithSemantics = _wrapWithSemantics(item, index);
    final Key itemGlobalKey =
        _ReorderableListViewChildGlobalKey(item.key!, this);

    return ReorderableDelayedDragStartListener(
      key: itemGlobalKey,
      index: index,
      child: itemWithSemantics,
    );
  }

  Widget _proxyDecorator(
          Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final double ease = Curves.easeInOut.transform(animation.value);
          return Transform.scale(
            scale: 1 - .08 * ease,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF8A1215))),
              child: child,
            ),
          );
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));

    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      controller: widget.controller,
      primary: widget.primary,
      physics: const SliderPhysics(),
      shrinkWrap: widget.shrinkWrap,
      anchor: widget.anchor,
      cacheExtent: widget.cacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      slivers: [
        SliverReorderableList(
          itemBuilder: _itemBuilder,
          itemCount: widget.itemCount,
          onReorder: widget.onReorder,
          proxyDecorator: widget.proxyDecorator ?? _proxyDecorator,
        )
      ],
    );
  }
}

@optionalTypeArgs
class _ReorderableListViewChildGlobalKey extends GlobalObjectKey {
  const _ReorderableListViewChildGlobalKey(this.subKey, this.state)
      : super(subKey);

  final Key subKey;
  final State state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableListViewChildGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => hashValues(subKey, state);
}
