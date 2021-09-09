part of 'view.dart';

class _DragStartListener extends StatelessWidget {
  const _DragStartListener({
    required this.child,
    required this.index,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (event) {
          final _ListState? list = _List.maybeOf(context);
          list?.startItemDragReorder(
            index: index,
            event: event,
            recognizer: createRecognizer(),
          );
        },
        child: child,
      );

  @protected
  MultiDragGestureRecognizer createRecognizer() =>
      ImmediateMultiDragGestureRecognizer(debugOwner: this);
}

class _DelayedDragStartListener extends _DragStartListener {
  const _DelayedDragStartListener({
    required Widget child,
    required int index,
    Key? key,
  }) : super(key: key, child: child, index: index);

  @override
  MultiDragGestureRecognizer createRecognizer() =>
      DelayedMultiDragGestureRecognizer(debugOwner: this);
}

class _DragInfo extends Drag {
  _DragInfo({
    required _ItemState item,
    required this.tickerProvider,
    Offset initialPosition = Offset.zero,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
    this.onDropCompleted,
  }) {
    final RenderBox itemRenderBox =
        item.context.findRenderObject()! as RenderBox;
    listState = item._listState;
    index = item.index;
    child = item.widget.child;
    capturedThemes = item.widget.capturedThemes;
    dragPosition = initialPosition;
    dragOffset = itemRenderBox.globalToLocal(initialPosition);
    itemSize = item.context.size!;
    itemExtent = itemSize.width;
    scrollable = Scrollable.of(item.context);
  }

  final void Function(_DragInfo item, Offset position, Offset delta)? onUpdate;
  final void Function(_DragInfo item)? onEnd;
  final void Function(_DragInfo item)? onCancel;
  final VoidCallback? onDropCompleted;
  final TickerProvider tickerProvider;

  late _ListState listState;
  late int index;
  late Widget child;
  late Offset dragPosition;
  late Offset dragOffset;
  late Size itemSize;
  late double itemExtent;
  late CapturedThemes capturedThemes;
  ScrollableState? scrollable;
  AnimationController? _proxyAnimation;

  void dispose() {
    _proxyAnimation?.dispose();
  }

  void startDrag() {
    _proxyAnimation = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 250),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _dropCompleted();
        }
      })
      ..forward();
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset delta = Offset(details.delta.dx, 0);
    dragPosition += delta;
    onUpdate?.call(this, dragPosition, details.delta);
  }

  @override
  void end(DragEndDetails details) {
    _proxyAnimation!.reverse();
    onEnd?.call(this);
  }

  @override
  void cancel() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onCancel?.call(this);
  }

  void _dropCompleted() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onDropCompleted?.call();
  }

  Widget createProxy(BuildContext context) => capturedThemes.wrap(
        _DragItemProxy(
          listState: listState,
          index: index,
          size: itemSize,
          animation: _proxyAnimation!,
          position: dragPosition - dragOffset - _overlayOrigin(context),
          child: child,
        ),
      );
}

Offset _overlayOrigin(BuildContext context) {
  final OverlayState overlay = Overlay.of(context)!;
  final RenderBox overlayBox = overlay.context.findRenderObject()! as RenderBox;
  return overlayBox.localToGlobal(Offset.zero);
}

class _DragItemProxy extends StatelessWidget {
  const _DragItemProxy({
    required this.listState,
    required this.index,
    required this.child,
    required this.position,
    required this.size,
    required this.animation,
    Key? key,
  }) : super(key: key);

  final _ListState listState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final Widget proxyChild = AnimatedBuilder(
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
    final Offset overlayOrigin = _overlayOrigin(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        Offset effectivePosition = position;
        final Offset? dropPosition = listState._finalDropPosition;
        if (dropPosition != null) {
          effectivePosition = Offset.lerp(dropPosition - overlayOrigin,
              effectivePosition, Curves.easeOut.transform(animation.value))!;
        }
        return Positioned(
          left: effectivePosition.dx,
          top: effectivePosition.dy,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        );
      },
      child: proxyChild,
    );
  }
}
