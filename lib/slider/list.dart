// 🎯 Dart imports:
import 'dart:math';

// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// 🌎 Project imports:
import 'viewport.dart';

typedef SliderReorderCallback = void Function(int oldIndex, int newIndex);

typedef SliderReorderItemProxyDecorator = Widget Function(
    Widget child, int index, Animation<double> animation);

class SliderReorderableList extends StatefulWidget {
  const SliderReorderableList({
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    Key? key,
    this.position,
    this.proxyDecorator,
  })  : assert(itemCount >= 0),
        super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final SliderReorderCallback onReorder;
  final SliderReorderItemProxyDecorator? proxyDecorator;
  final ViewportOffset? position;

  @override
  SliderReorderableListState createState() => SliderReorderableListState();

  static SliderReorderableListState of(BuildContext context) {
    final SliderReorderableListState? result =
        context.findAncestorStateOfType<SliderReorderableListState>();
    assert(result != null,
        'SliverReorderableList.of() called with a context that does not contain a SliverReorderableList.');
    return result!;
  }

  static SliderReorderableListState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SliderReorderableListState>();
}

class SliderReorderableListState extends State<SliderReorderableList>
    with TickerProviderStateMixin {
  final Map<int, _ReorderableItemState> _items = <int, _ReorderableItemState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer<MultiDragPointerState>? _recognizer;
  bool _autoScrolling = false;

  @override
  void didUpdateWidget(covariant SliderReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      cancelReorder();
    }
  }

  @override
  void dispose() {
    _dragInfo?.dispose();
    super.dispose();
  }

  void startItemDragReorder({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer<MultiDragPointerState> recognizer,
  }) {
    assert(0 <= index && index < widget.itemCount);
    setState(() {
      if (_dragInfo != null) {
        cancelReorder();
      }
      if (_items.containsKey(index)) {
        _dragIndex = index;
        _recognizer = recognizer
          ..onStart = _dragStart
          ..addPointer(event);
      } else {
        throw Exception('Attempting to start a drag on a non-visible item');
      }
    });
  }

  void cancelReorder() {
    _dragReset();
  }

  void _registerItem(_ReorderableItemState item) {
    _items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item
        ..dragging = true
        ..rebuild();
    }
  }

  void _unregisterItem(int index, _ReorderableItemState item) {
    final _ReorderableItemState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  Drag? _dragStart(Offset position) {
    assert(_dragInfo == null);
    final _ReorderableItemState item = _items[_dragIndex!]!
      ..dragging = true
      ..rebuild();

    _insertIndex = item.index;
    _dragInfo = _DragInfo(
      item: item,
      initialPosition: position,
      onUpdate: _dragUpdate,
      onCancel: _dragCancel,
      onEnd: _dragEnd,
      onDropCompleted: _dropCompleted,
      proxyDecorator: widget.proxyDecorator,
      tickerProvider: this,
    );
    _dragInfo!.startDrag();

    final OverlayState overlay = Overlay.of(context)!;
    assert(_overlayEntry == null);
    _overlayEntry = OverlayEntry(builder: _dragInfo!.createProxy);
    overlay.insert(_overlayEntry!);

    for (final _ReorderableItemState childItem in _items.values) {
      if (childItem == item || !childItem.mounted) {
        continue;
      }
      childItem.updateForGap(_insertIndex!, _dragInfo!.itemExtent,
          animate: false);
    }
    return _dragInfo;
  }

  void _dragUpdate(_DragInfo item, Offset position, Offset delta) {
    setState(() {
      _overlayEntry?.markNeedsBuild();
      _dragUpdateItems();
      _autoScrollIfNecessary();
    });
  }

  void _dragCancel(_DragInfo item) {
    _dragReset();
  }

  Offset _itemOffsetAt(int index) {
    final RenderBox itemRenderBox =
        _items[index]!.context.findRenderObject()! as RenderBox;
    return itemRenderBox.localToGlobal(Offset.zero);
  }

  void _dragEnd(_DragInfo item) => setState(() {
        _finalDropPosition = _itemOffsetAt(
            _insertIndex! - (_insertIndex! > _dragIndex! ? 1 : 0));
      });

  void _dropCompleted() {
    final int fromIndex = _dragIndex!;
    final int toIndex = _insertIndex!;
    if (fromIndex != toIndex) {
      widget.onReorder.call(fromIndex, toIndex);
    }
    _dragReset();
  }

  void _dragReset() {
    setState(() {
      if (_dragInfo != null) {
        if (_dragIndex != null && _items.containsKey(_dragIndex)) {
          _items[_dragIndex!]!
            .._dragging = false
            ..rebuild();
          _dragIndex = null;
        }
        _dragInfo?.dispose();
        _dragInfo = null;
        _resetItemGap();
        _recognizer?.dispose();
        _recognizer = null;
        _overlayEntry?.remove();
        _overlayEntry = null;
        _finalDropPosition = null;
      }
    });
  }

  void _resetItemGap() {
    for (final _ReorderableItemState item in _items.values) {
      item.resetGap();
    }
  }

  void _dragUpdateItems() {
    assert(_dragInfo != null);
    final double gapExtent = _dragInfo!.itemExtent;
    final double proxyItemStart =
        (_dragInfo!.dragPosition - _dragInfo!.dragOffset).dx;
    final double proxyItemEnd = proxyItemStart + gapExtent;

    int newIndex = _insertIndex!;
    for (final _ReorderableItemState item in _items.values) {
      if (item.index == _dragIndex! || !item.mounted) {
        continue;
      }

      final Rect geometry = item.targetGeometry();
      final double itemStart = geometry.left;
      final double itemExtent = geometry.width;
      final double itemEnd = itemStart + itemExtent;
      final double itemMiddle = itemStart + itemExtent * .5;

      if (itemStart <= proxyItemStart && proxyItemStart <= itemMiddle) {
        newIndex = item.index;
        break;
      } else if (itemMiddle <= proxyItemEnd && proxyItemEnd <= itemEnd) {
        newIndex = item.index + 1;
        break;
      } else if (itemEnd < proxyItemStart && newIndex < (item.index + 1)) {
        newIndex = item.index + 1;
      } else if (proxyItemEnd < itemStart && newIndex > item.index) {
        newIndex = item.index;
      }
    }

    if (newIndex != _insertIndex) {
      _insertIndex = newIndex;
      for (final _ReorderableItemState item in _items.values) {
        if (item.index == _dragIndex! || !item.mounted) {
          continue;
        }
        item.updateForGap(newIndex, gapExtent, animate: true);
      }
    }
  }

  Future<void> _autoScrollIfNecessary() async {
    if (!_autoScrolling && _dragInfo != null && _dragInfo!.scrollable != null) {
      final ScrollPosition position = _dragInfo!.scrollable!.position;
      double? newOffset;
      const Duration duration = Duration(milliseconds: 14);
      const double step = 1;
      const double overDragMax = 20;
      const double overDragCoef = 10;

      final RenderBox scrollRenderBox =
          _dragInfo!.scrollable!.context.findRenderObject()! as RenderBox;
      final Offset scrollOrigin = scrollRenderBox.localToGlobal(Offset.zero);
      final double scrollStart = scrollOrigin.dx;
      final double scrollEnd = scrollStart + scrollRenderBox.size.width;

      final double proxyStart =
          (_dragInfo!.dragPosition - _dragInfo!.dragOffset).dx;
      final double proxyEnd = proxyStart + _dragInfo!.itemExtent;

      if (proxyStart < scrollStart &&
          position.pixels > position.minScrollExtent) {
        final double overDrag = max(scrollStart - proxyStart, overDragMax);
        newOffset = max(position.minScrollExtent,
            position.pixels - step * overDrag / overDragCoef);
      } else if (proxyEnd > scrollEnd &&
          position.pixels < position.maxScrollExtent) {
        final double overDrag = max(proxyEnd - scrollEnd, overDragMax);
        newOffset = min(position.maxScrollExtent,
            position.pixels + step * overDrag / overDragCoef);
      }

      if (newOffset != null && (newOffset - position.pixels).abs() >= 1.0) {
        _autoScrolling = true;
        await position.animateTo(
          newOffset,
          duration: duration,
          curve: Curves.linear,
        );
        _autoScrolling = false;
        if (_dragInfo != null) {
          _dragUpdateItems();
          _autoScrollIfNecessary(); // ignore: unawaited_futures
        }
      }
    }
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final Widget child = widget.itemBuilder(context, index);
    assert(child.key != null, 'All list items must have a key');
    final OverlayState overlay = Overlay.of(context)!;
    return _ReorderableItem(
      key: _ReorderableItemGlobalKey(child.key!, index, this),
      index: index,
      capturedThemes:
          InheritedTheme.capture(from: context, to: overlay.context),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));

    return Viewport(
        cacheExtent: 0,
        cacheExtentStyle: CacheExtentStyle.viewport,
        axisDirection: AxisDirection.right,
        offset: widget.position ?? ViewportOffset.zero(),
        slivers: [
          SliderFillViewport(
            viewportFraction: 1 / 3,
            delegate: SliverChildBuilderDelegate(
              _itemBuilder,
              childCount: widget.itemCount,
            ),
          )
        ]);
  }
}

class _ReorderableItem extends StatefulWidget {
  const _ReorderableItem({
    required Key key,
    required this.index,
    required this.child,
    required this.capturedThemes,
  }) : super(key: key);

  final int index;
  final Widget child;
  final CapturedThemes capturedThemes;

  @override
  _ReorderableItemState createState() => _ReorderableItemState();
}

class _ReorderableItemState extends State<_ReorderableItem> {
  late SliderReorderableListState _listState;

  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  Key get key => widget.key!;

  int get index => widget.index;

  bool get dragging => _dragging;

  set dragging(bool dragging) {
    if (mounted) {
      setState(() {
        _dragging = dragging;
      });
    }
  }

  bool _dragging = false;

  @override
  void initState() {
    _listState = SliderReorderableList.of(context);
    _listState._registerItem(this);
    super.initState();
  }

  @override
  void dispose() {
    _offsetAnimation?.dispose();
    _listState._unregisterItem(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReorderableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _listState
        .._unregisterItem(oldWidget.index, this)
        .._registerItem(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dragging) {
      return const SizedBox();
    }
    _listState._registerItem(this);
    return Transform(
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
      child: widget.child,
    );
  }

  @override
  void deactivate() {
    _listState._unregisterItem(index, this);
    super.deactivate();
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      final double animValue =
          Curves.easeInOut.transform(_offsetAnimation!.value);
      return Offset.lerp(_startOffset, _targetOffset, animValue)!;
    }
    return _targetOffset;
  }

  void updateForGap(int gapIndex, double gapExtent, {required bool animate}) {
    Offset newTargetOffset =
        gapIndex > index ? Offset.zero : Offset(gapExtent, 0);

    if (_listState._dragIndex! <= index) {
      newTargetOffset = gapIndex <= index ? Offset.zero : Offset(-gapExtent, 0);
    }

    if (newTargetOffset != _targetOffset) {
      _targetOffset = newTargetOffset;
      if (animate) {
        if (_offsetAnimation == null) {
          _offsetAnimation = AnimationController(
            vsync: _listState,
            duration: const Duration(milliseconds: 300),
          )
            ..addListener(rebuild)
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                _startOffset = _targetOffset;
                _offsetAnimation!.dispose();
                _offsetAnimation = null;
              }
            })
            ..forward();
        } else {
          _startOffset = offset;
          _offsetAnimation!.forward(from: 0);
        }
      } else {
        if (_offsetAnimation != null) {
          _offsetAnimation!.dispose();
          _offsetAnimation = null;
        }
        _startOffset = _targetOffset;
      }
      rebuild();
    }
  }

  void resetGap() {
    if (_offsetAnimation != null) {
      _offsetAnimation!.dispose();
      _offsetAnimation = null;
    }
    _startOffset = Offset.zero;
    _targetOffset = Offset.zero;
    rebuild();
  }

  Rect targetGeometry() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition =
        itemRenderBox.localToGlobal(Offset.zero) + _targetOffset;
    return itemPosition & itemRenderBox.size;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}

class SliderReorderableDragStartListener extends StatelessWidget {
  const SliderReorderableDragStartListener({
    required this.child,
    required this.index,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (event) => _startDragging(context, event),
        child: child,
      );

  @protected
  MultiDragGestureRecognizer<MultiDragPointerState> createRecognizer() =>
      ImmediateMultiDragGestureRecognizer(debugOwner: this);

  void _startDragging(BuildContext context, PointerDownEvent event) {
    final SliderReorderableListState? list =
        SliderReorderableList.maybeOf(context);
    list?.startItemDragReorder(
      index: index,
      event: event,
      recognizer: createRecognizer(),
    );
  }
}

class SliderReorderableDelayedDragStartListener
    extends SliderReorderableDragStartListener {
  const SliderReorderableDelayedDragStartListener({
    required Widget child,
    required int index,
    Key? key,
  }) : super(key: key, child: child, index: index);

  @override
  MultiDragGestureRecognizer<MultiDragPointerState> createRecognizer() =>
      DelayedMultiDragGestureRecognizer(debugOwner: this);
}

// ignore: avoid_private_typedef_functions
typedef _DragItemUpdate = void Function(
  _DragInfo item,
  Offset position,
  Offset delta,
);
typedef _DragItemCallback = void Function(_DragInfo item);

class _DragInfo extends Drag {
  _DragInfo({
    required _ReorderableItemState item,
    required this.tickerProvider,
    Offset initialPosition = Offset.zero,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
    this.onDropCompleted,
    this.proxyDecorator,
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

  final _DragItemUpdate? onUpdate;
  final _DragItemCallback? onEnd;
  final _DragItemCallback? onCancel;
  final VoidCallback? onDropCompleted;
  final SliderReorderItemProxyDecorator? proxyDecorator;
  final TickerProvider tickerProvider;

  late SliderReorderableListState listState;
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
          proxyDecorator: proxyDecorator,
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
    required this.proxyDecorator,
    Key? key,
  }) : super(key: key);

  final SliderReorderableListState listState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
  final AnimationController animation;
  final SliderReorderItemProxyDecorator? proxyDecorator;

  @override
  Widget build(BuildContext context) {
    final Widget proxyChild =
        proxyDecorator?.call(child, index, animation.view) ?? child;
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

@optionalTypeArgs
class _ReorderableItemGlobalKey extends GlobalObjectKey {
  const _ReorderableItemGlobalKey(this.subKey, this.index, this.state)
      : super(subKey);

  final Key subKey;
  final int index;
  final SliderReorderableListState state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableItemGlobalKey &&
        other.subKey == subKey &&
        other.index == index &&
        other.state == state;
  }

  @override
  int get hashCode => hashValues(subKey, index, state);
}
