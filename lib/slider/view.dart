import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'controller.dart';
import 'metrics.dart';
import 'physics.dart';

class SliderView extends StatefulWidget {
  SliderView({
    required List<Widget> children,
    required this.controller,
    required this.onReorder,
    Key? key,
    this.restorationId,
    this.onPageChanged,
  })  : childrenDelegate = SliverChildListDelegate(children),
        itemBuilder = ((context, index) => children[index]),
        itemCount = children.length,
        super(key: key);

  final ReorderCallback onReorder;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final String? restorationId;
  final SliderController controller;
  final ValueChanged<int>? onPageChanged;
  final SliverChildDelegate childrenDelegate;

  @override
  State<SliderView> createState() => _SliderViewState();
}

class _SliderViewState extends State<SliderView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.controller.initialPage;
  }

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
      reorderItemBefore = Directionality.of(context) == TextDirection.ltr
          ? localizations.reorderItemLeft
          : localizations.reorderItemRight;
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] =
          moveBefore;
    }

    if (index < widget.itemCount - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      reorderItemAfter = Directionality.of(context) == TextDirection.ltr
          ? localizations.reorderItemRight
          : localizations.reorderItemLeft;
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

  // ignore: unused_element
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

  // ignore: unused_element
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
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              widget.onPageChanged != null &&
              notification is ScrollUpdateNotification) {
            final SliderMetrics metrics = notification.metrics as SliderMetrics;
            final int currentPage = metrics.page!.round();
            if (currentPage != _lastReportedPage) {
              _lastReportedPage = currentPage;
              widget.onPageChanged!(currentPage);
            }
          }
          return false;
        },
        child: Scrollable(
          axisDirection: AxisDirection.right,
          controller: widget.controller,
          physics: const SliderPhysics(),
          restorationId: widget.restorationId,
          scrollBehavior: ScrollConfiguration.of(context)
              .copyWith(scrollbars: false, overscroll: false),
          viewportBuilder: (context, position) => Viewport(
            cacheExtent: 0,
            cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: AxisDirection.right,
            offset: position,
            slivers: [
              SliverFillViewport(
                viewportFraction: widget.controller.viewportFraction,
                delegate: widget.childrenDelegate,
                padEnds: false,
              ),
            ],
          ),
        ),
      );
}

/*

 */

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
