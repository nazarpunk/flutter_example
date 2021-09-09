// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SliderFillViewport extends StatelessWidget {
  const SliderFillViewport({
    required this.delegate,
    Key? key,
    this.viewportFraction = 1.0,
  })  : assert(viewportFraction > 0.0),
        super(key: key);

  final double viewportFraction;
  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) => _RenderObjectWidget(
        viewportFraction: viewportFraction,
        delegate: delegate,
      );
}

class _RenderObjectWidget extends SliverMultiBoxAdaptorWidget {
  const _RenderObjectWidget({
    required SliverChildDelegate delegate,
    required this.viewportFraction,
    Key? key,
  }) : super(key: key, delegate: delegate);

  final double viewportFraction;

  @override
  SliderRenderSliverFillViewport createRenderObject(BuildContext context) =>
      SliderRenderSliverFillViewport(
        childManager: context as SliverMultiBoxAdaptorElement,
        viewportFraction: viewportFraction,
      );
}

class SliderRenderSliverFillViewport extends RenderSliverFixedExtentBoxAdaptor {
  SliderRenderSliverFillViewport({
    required RenderSliverBoxChildManager childManager,
    double viewportFraction = 1.0,
  })  : assert(viewportFraction > 0.0),
        _viewportFraction = viewportFraction,
        //_viewportFraction = 1,
        super(childManager: childManager);

  @override
  double get itemExtent =>
      constraints.viewportMainAxisExtent * viewportFraction;

  double get viewportFraction => _viewportFraction;
  double _viewportFraction;

  set viewportFraction(double value) {
    if (_viewportFraction == value) {
      return;
    }
    _viewportFraction = value;
    markNeedsLayout();
  }
}
