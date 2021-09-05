import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'controller.dart';
import 'metrics.dart';
import 'physics.dart';

final SliderController _defaultPageController = SliderController();

class SliderView extends StatefulWidget {
  SliderView({
    required this.onReorder,
    Key? key,
    SliderController? controller,
    this.onPageChanged,
    List<Widget> children = const <Widget>[],
    this.restorationId,
  })  : controller = controller ?? _defaultPageController,
        childrenDelegate = SliverChildListDelegate(children),
        super(key: key);

  SliderView.builder({
    required IndexedWidgetBuilder itemBuilder,
    required this.onReorder,
    Key? key,
    SliderController? controller,
    this.onPageChanged,
    int? itemCount,
    this.restorationId,
  })  : controller = controller ?? _defaultPageController,
        childrenDelegate =
            SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
        super(key: key);

  final ReorderCallback onReorder;
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

  AxisDirection _getDirection(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return textDirectionToAxisDirection(Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);

    return NotificationListener<ScrollNotification>(
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
        axisDirection: axisDirection,
        controller: widget.controller,
        physics: const SliderPhysics(),
        restorationId: widget.restorationId,
        scrollBehavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false, overscroll: false),
        viewportBuilder: (context, position) => Viewport(
          cacheExtent: 0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          axisDirection: axisDirection,
          offset: position,
          slivers: <Widget>[
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
}
