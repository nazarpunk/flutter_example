part of 'view.dart';

class _Viewport extends StatelessWidget {
  const _Viewport({
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
  _FillViewport createRenderObject(BuildContext context) => _FillViewport(
        childManager: context as SliverMultiBoxAdaptorElement,
        viewportFraction: viewportFraction,
      );
}

class _FillViewport extends RenderSliverFixedExtentBoxAdaptor {
  _FillViewport({
    required RenderSliverBoxChildManager childManager,
    double viewportFraction = 1.0,
  })  : assert(viewportFraction > 0.0),
        _viewportFraction = viewportFraction,
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
