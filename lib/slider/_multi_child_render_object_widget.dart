part of 'view.dart';

class _MultiChildRenderObjectWidget extends MultiChildRenderObjectWidget {
  _MultiChildRenderObjectWidget({
    required this.offset,
    Key? key,
    this.axisDirection = AxisDirection.down,
    this.crossAxisDirection,
    this.anchor = 0.0,
    this.center,
    this.cacheExtent,
    this.cacheExtentStyle = CacheExtentStyle.pixel,
    this.clipBehavior = Clip.hardEdge,
    List<Widget> slivers = const <Widget>[],
  })  : assert(center == null ||
            slivers.where((child) => child.key == center).length == 1),
        assert(cacheExtentStyle != CacheExtentStyle.viewport ||
            cacheExtent != null),
        super(key: key, children: slivers);

  final AxisDirection axisDirection;
  final AxisDirection? crossAxisDirection;
  final double anchor;
  final ViewportOffset offset;
  final Key? center;
  final double? cacheExtent;
  final CacheExtentStyle cacheExtentStyle;
  final Clip clipBehavior;

  static AxisDirection getDefaultCrossAxisDirection(
      BuildContext context, AxisDirection axisDirection) {
    switch (axisDirection) {
      case AxisDirection.up:
        assert(debugCheckHasDirectionality(
          context,
          why:
              "to determine the cross-axis direction when the viewport has an 'up' axisDirection",
          alternative:
              "Alternatively, consider specifying the 'crossAxisDirection' argument on the Viewport.",
        ));
        return textDirectionToAxisDirection(Directionality.of(context));
      case AxisDirection.right:
        return AxisDirection.down;
      case AxisDirection.down:
        assert(debugCheckHasDirectionality(
          context,
          why:
              "to determine the cross-axis direction when the viewport has a 'down' axisDirection",
          alternative:
              "Alternatively, consider specifying the 'crossAxisDirection' argument on the Viewport.",
        ));
        return textDirectionToAxisDirection(Directionality.of(context));
      case AxisDirection.left:
        return AxisDirection.down;
    }
  }

  @override
  RenderViewport createRenderObject(BuildContext context) => RenderViewport(
        axisDirection: axisDirection,
        crossAxisDirection: crossAxisDirection ??
            _MultiChildRenderObjectWidget.getDefaultCrossAxisDirection(
                context, axisDirection),
        anchor: anchor,
        offset: offset,
        cacheExtent: cacheExtent,
        cacheExtentStyle: cacheExtentStyle,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(BuildContext context, RenderViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          _MultiChildRenderObjectWidget.getDefaultCrossAxisDirection(
              context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..cacheExtent = cacheExtent
      ..cacheExtentStyle = cacheExtentStyle
      ..clipBehavior = clipBehavior;
  }

  @override
  MultiChildRenderObjectElement createElement() => _ViewportElement(this);
}

class _ViewportElement extends MultiChildRenderObjectElement {
  _ViewportElement(_MultiChildRenderObjectWidget widget) : super(widget);

  @override
  _MultiChildRenderObjectWidget get widget =>
      super.widget as _MultiChildRenderObjectWidget;

  @override
  RenderViewport get renderObject => super.renderObject as RenderViewport;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _updateCenter();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _updateCenter();
  }

  void _updateCenter() {
    if (widget.center != null) {
      renderObject.center = children
          .singleWhere(
            (element) => element.widget.key == widget.center,
          )
          .renderObject as RenderSliver?;
    } else if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject as RenderSliver?;
    } else {
      renderObject.center = null;
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where((e) {
      final RenderSliver renderSliver = e.renderObject! as RenderSliver;
      return renderSliver.geometry!.visible;
    }).forEach(visitor);
  }
}
