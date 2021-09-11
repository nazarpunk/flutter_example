part of 'view.dart';

class _List extends StatefulWidget {
  const _List({
    required this.itemBuilder,
    required this.itemCount,
    required this.itemsCount,
    required this.onReorder,
    Key? key,
    this.position,
  })  : assert(itemCount >= 0),
        super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int itemsCount;
  final void Function(int, int) onReorder;
  final ViewportOffset? position;

  @override
  _ListState createState() => _ListState();

  static _ListState of(BuildContext context) {
    final _ListState? result = context.findAncestorStateOfType<_ListState>();
    assert(result != null,
        'SliverReorderableList.of() called with a context that does not contain a SliverReorderableList.');
    return result!;
  }

  static _ListState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_ListState>();
}

class _ListState extends State<_List> with TickerProviderStateMixin {
  final Map<int, _ItemState> _items = <int, _ItemState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer? _recognizer;
  bool _autoScrolling = true;

  @override
  void didUpdateWidget(covariant _List oldWidget) {
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
    required MultiDragGestureRecognizer recognizer,
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

  void _registerItem(_ItemState item) {
    _items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item
        ..dragging = true
        ..rebuild();
    }
  }

  void _unregisterItem(int index, _ItemState item) {
    final _ItemState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  Drag? _dragStart(Offset position) {
    assert(_dragInfo == null);
    final _ItemState item = _items[_dragIndex!]!
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
      tickerProvider: this,
    );
    _dragInfo!.startDrag();

    final OverlayState overlay = Overlay.of(context)!;
    assert(_overlayEntry == null);
    _overlayEntry = OverlayEntry(builder: _dragInfo!.createProxy);
    overlay.insert(_overlayEntry!);

    for (final _ItemState childItem in _items.values) {
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
    for (final _ItemState item in _items.values) {
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
    for (final _ItemState item in _items.values) {
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
      for (final _ItemState item in _items.values) {
        if (item.index == _dragIndex! || !item.mounted) {
          continue;
        }
        item.updateForGap(newIndex, gapExtent, animate: true);
      }
    }
  }

  Future<void> _autoScrollIfNecessary() async {
    if (_autoScrolling && _dragInfo != null && _dragInfo!.scrollable != null) {
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
        final double overDrag = math.max(scrollStart - proxyStart, overDragMax);
        newOffset = math.max(position.minScrollExtent,
            position.pixels - step * overDrag / overDragCoef);
      } else if (proxyEnd > scrollEnd &&
          position.pixels < position.maxScrollExtent) {
        final double overDrag = math.max(proxyEnd - scrollEnd, overDragMax);
        newOffset = math.min(position.maxScrollExtent,
            position.pixels + step * overDrag / overDragCoef);
      }

      if (newOffset != null && (newOffset - position.pixels).abs() >= 1.0) {
        _autoScrolling = false;
        await position.animateTo(
          newOffset,
          duration: duration,
          curve: Curves.linear,
        );
        _autoScrolling = true;
        if (_dragInfo != null) {
          _dragUpdateItems();
          _autoScrollIfNecessary(); // ignore: unawaited_futures
        }
      }
    }
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
          _Viewport(
            viewportFraction: 1 / widget.itemsCount,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final Widget child = widget.itemBuilder(context, index);
                assert(child.key != null, 'All list items must have a key');
                final OverlayState overlay = Overlay.of(context)!;
                return _Item(
                  key: _ListGlobalKey(child.key!, index, this),
                  index: index,
                  capturedThemes: InheritedTheme.capture(
                      from: context, to: overlay.context),
                  child: child,
                );
              },
              childCount: widget.itemCount,
            ),
          )
        ]);
  }
}
