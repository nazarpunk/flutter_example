import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef SliderReorderCallback = void Function(int oldIndex, int newIndex);

typedef SliderReorderItemProxyDecorator = Widget Function(
    Widget child, int index, Animation<double> animation);

class SliderReorderableList extends StatefulWidget {
  const SliderReorderableList({
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    Key? key,
    this.proxyDecorator,
    this.controller,
    this.primary,
    this.physics,
    this.restorationId,
  })  : assert(itemCount >= 0),
        super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final SliderReorderCallback onReorder;
  final SliderReorderItemProxyDecorator? proxyDecorator;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final String? restorationId;

  static SliderReorderableListState of(BuildContext context) {
    final SliderReorderableListState? result =
        context.findAncestorStateOfType<SliderReorderableListState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'ReorderableList.of() called with a context that does not contain a ReorderableList.'),
          ErrorDescription(
            'No ReorderableList ancestor could be found starting from the context that was passed to ReorderableList.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the ReorderableList. Please see the ReorderableList documentation for examples '
            'of how to refer to an ReorderableListState object:\n'
            '  https://api.flutter.dev/flutter/widgets/ReorderableListState-class.html',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  static SliderReorderableListState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SliderReorderableListState>();

  @override
  SliderReorderableListState createState() => SliderReorderableListState();
}

class SliderReorderableListState extends State<SliderReorderableList> {
  final GlobalKey<SliderSliverReorderableListState> _sliverReorderableListKey =
      GlobalKey();

  void startItemDragReorder({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer<MultiDragPointerState> recognizer,
  }) {
    _sliverReorderableListKey.currentState!.startItemDragReorder(
        index: index, event: event, recognizer: recognizer);
  }

  void cancelReorder() {
    _sliverReorderableListKey.currentState!.cancelReorder();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller: widget.controller,
        primary: widget.primary,
        physics: widget.physics,
        restorationId: widget.restorationId,
        slivers: [
          SliderSliverReorderableList(
            key: _sliverReorderableListKey,
            itemBuilder: widget.itemBuilder,
            itemCount: widget.itemCount,
            onReorder: widget.onReorder,
            proxyDecorator: widget.proxyDecorator,
          )
        ],
      );
}

class SliderSliverReorderableList extends StatefulWidget {
  const SliderSliverReorderableList({
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    Key? key,
    this.proxyDecorator,
  })  : assert(itemCount >= 0),
        super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final SliderReorderCallback onReorder;
  final SliderReorderItemProxyDecorator? proxyDecorator;

  @override
  SliderSliverReorderableListState createState() =>
      SliderSliverReorderableListState();

  static SliderSliverReorderableListState of(BuildContext context) {
    final SliderSliverReorderableListState? result =
        context.findAncestorStateOfType<SliderSliverReorderableListState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'SliverReorderableList.of() called with a context that does not contain a SliverReorderableList.',
          ),
          ErrorDescription(
            'No SliverReorderableList ancestor could be found starting from the context that was passed to SliverReorderableList.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the SliverReorderableList. Please see the SliverReorderableList documentation for examples '
            'of how to refer to an SliverReorderableList object:\n'
            '  https://api.flutter.dev/flutter/widgets/SliverReorderableListState-class.html',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  static SliderSliverReorderableListState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SliderSliverReorderableListState>();
}

class SliderSliverReorderableListState
    extends State<SliderSliverReorderableList> with TickerProviderStateMixin {
  final Map<int, _ReorderableItemState> _items = <int, _ReorderableItemState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer<MultiDragPointerState>? _recognizer;
  bool _autoScrolling = false;

  late ScrollableState _scrollable;

  Axis get _scrollDirection => axisDirectionToAxis(_scrollable.axisDirection);

  bool get _reverse =>
      _scrollable.axisDirection == AxisDirection.up ||
      _scrollable.axisDirection == AxisDirection.left;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.of(context)!;
  }

  @override
  void didUpdateWidget(covariant SliderSliverReorderableList oldWidget) {
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
      scrollDirection: _scrollDirection,
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
          animate: false, reverse: _reverse);
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

  void _dragEnd(_DragInfo item) {
    setState(() {
      if (_insertIndex! < widget.itemCount - 1) {
        _finalDropPosition = _itemOffsetAt(_insertIndex!);
      } else {
        final int itemIndex =
            _items.length > 1 ? _insertIndex! - 1 : _insertIndex!;
        if (_reverse) {
          _finalDropPosition = _itemOffsetAt(itemIndex) -
              _extentOffset(item.itemExtent, _scrollDirection);
        } else {
          _finalDropPosition = _itemOffsetAt(itemIndex) +
              _extentOffset(item.itemExtent, _scrollDirection);
        }
      }
    });
  }

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
    final double proxyItemStart = _offsetExtent(
        _dragInfo!.dragPosition - _dragInfo!.dragOffset, _scrollDirection);
    final double proxyItemEnd = proxyItemStart + gapExtent;

    int newIndex = _insertIndex!;
    for (final _ReorderableItemState item in _items.values) {
      if (item.index == _dragIndex! || !item.mounted) {
        continue;
      }

      final Rect geometry = item.targetGeometry();
      final double itemStart =
          _scrollDirection == Axis.vertical ? geometry.top : geometry.left;
      final double itemExtent =
          _scrollDirection == Axis.vertical ? geometry.height : geometry.width;
      final double itemEnd = itemStart + itemExtent;
      final double itemMiddle = itemStart + itemExtent / 2;

      if (_reverse) {
        if (itemEnd >= proxyItemEnd && proxyItemEnd >= itemMiddle) {
          newIndex = item.index;
          break;
        } else if (itemMiddle >= proxyItemStart &&
            proxyItemStart >= itemStart) {
          newIndex = item.index + 1;
          break;
        } else if (itemStart > proxyItemEnd && newIndex < (item.index + 1)) {
          newIndex = item.index + 1;
        } else if (proxyItemStart > itemEnd && newIndex > item.index) {
          newIndex = item.index;
        }
      } else {
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
    }

    if (newIndex != _insertIndex) {
      _insertIndex = newIndex;
      for (final _ReorderableItemState item in _items.values) {
        if (item.index == _dragIndex! || !item.mounted) {
          continue;
        }
        item.updateForGap(newIndex, gapExtent,
            animate: true, reverse: _reverse);
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
      final double scrollStart = _offsetExtent(scrollOrigin, _scrollDirection);
      final double scrollEnd =
          scrollStart + _sizeExtent(scrollRenderBox.size, _scrollDirection);

      final double proxyStart = _offsetExtent(
          _dragInfo!.dragPosition - _dragInfo!.dragOffset, _scrollDirection);
      final double proxyEnd = proxyStart + _dragInfo!.itemExtent;

      if (_reverse) {
        if (proxyEnd > scrollEnd &&
            position.pixels > position.minScrollExtent) {
          final double overDrag = max(proxyEnd - scrollEnd, overDragMax);
          newOffset = max(position.minScrollExtent,
              position.pixels - step * overDrag / overDragCoef);
        } else if (proxyStart < scrollStart &&
            position.pixels < position.maxScrollExtent) {
          final double overDrag = max(scrollStart - proxyStart, overDragMax);
          newOffset = min(position.maxScrollExtent,
              position.pixels + step * overDrag / overDragCoef);
        }
      } else {
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

  Offset _itemOffsetAt(int index) {
    final RenderBox itemRenderBox =
        _items[index]!.context.findRenderObject()! as RenderBox;
    return itemRenderBox.localToGlobal(Offset.zero);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (_dragInfo != null && index >= widget.itemCount) {
      switch (_scrollDirection) {
        case Axis.horizontal:
          return SizedBox(width: _dragInfo!.itemExtent);
        case Axis.vertical:
          return SizedBox(height: _dragInfo!.itemExtent);
      }
    }
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        _itemBuilder,
        childCount: widget.itemCount + (_dragInfo != null ? 1 : 0),
      ),
    );
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
  late SliderSliverReorderableListState _listState;

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
    _listState = SliderSliverReorderableList.of(context);
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

  void updateForGap(int gapIndex, double gapExtent,
      {required bool animate, required bool reverse}) {
    final Offset newTargetOffset = (gapIndex <= index)
        ? _extentOffset(
            reverse ? -gapExtent : gapExtent, _listState._scrollDirection)
        : Offset.zero;
    if (newTargetOffset != _targetOffset) {
      _targetOffset = newTargetOffset;
      if (animate) {
        if (_offsetAnimation == null) {
          _offsetAnimation = AnimationController(
            vsync: _listState,
            duration: const Duration(milliseconds: 250),
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
    final SliderSliverReorderableListState? list =
        SliderSliverReorderableList.maybeOf(context);
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
    this.scrollDirection = Axis.vertical,
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
    itemExtent = _sizeExtent(itemSize, scrollDirection);
    scrollable = Scrollable.of(item.context);
  }

  final Axis scrollDirection;
  final _DragItemUpdate? onUpdate;
  final _DragItemCallback? onEnd;
  final _DragItemCallback? onCancel;
  final VoidCallback? onDropCompleted;
  final SliderReorderItemProxyDecorator? proxyDecorator;
  final TickerProvider tickerProvider;

  late SliderSliverReorderableListState listState;
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
    final Offset delta = _restrictAxis(details.delta, scrollDirection);
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

  final SliderSliverReorderableListState listState;
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

double _sizeExtent(Size size, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return size.width;
    case Axis.vertical:
      return size.height;
  }
}

double _offsetExtent(Offset offset, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return offset.dx;
    case Axis.vertical:
      return offset.dy;
  }
}

Offset _extentOffset(double extent, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return Offset(extent, 0);
    case Axis.vertical:
      return Offset(0, extent);
  }
}

Offset _restrictAxis(Offset offset, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return Offset(offset.dx, 0);
    case Axis.vertical:
      return Offset(0, offset.dy);
  }
}

@optionalTypeArgs
class _ReorderableItemGlobalKey extends GlobalObjectKey {
  const _ReorderableItemGlobalKey(this.subKey, this.index, this.state)
      : super(subKey);

  final Key subKey;
  final int index;
  final SliderSliverReorderableListState state;

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