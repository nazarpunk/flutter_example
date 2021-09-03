import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliderReorderableListView extends StatefulWidget {
  SliderReorderableListView({
    required List<Widget> children,
    required this.onReorder,
    Key? key,
    this.proxyDecorator,
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
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

  const SliderReorderableListView.builder({
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    Key? key,
    this.proxyDecorator,
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  })  : assert(itemCount >= 0),
        super(key: key);

  /// {@macro flutter.widgets.reorderable_list.itemBuilder}
  final IndexedWidgetBuilder itemBuilder;

  /// {@macro flutter.widgets.reorderable_list.itemCount}
  final int itemCount;

  /// {@macro flutter.widgets.reorderable_list.onReorder}
  final ReorderCallback onReorder;

  /// {@macro flutter.widgets.reorderable_list.proxyDecorator}
  final ReorderItemProxyDecorator? proxyDecorator;

  /// If true: on desktop platforms, a drag handle is stacked over the
  /// center of each item's trailing edge; on mobile platforms, a long
  /// press anywhere on the item starts a drag.
  ///
  /// The default desktop drag handle is just an [Icons.drag_handle]
  /// wrapped by a [ReorderableDragStartListener]. On mobile
  /// platforms, the entire item is wrapped with a
  /// [ReorderableDelayedDragStartListener].
  ///
  /// To change the appearance or the layout of the drag handles, make
  /// this parameter false and wrap each list item, or a widget within
  /// each list item, with [ReorderableDragStartListener] or
  /// [ReorderableDelayedDragStartListener], or a custom subclass
  /// of [ReorderableDragStartListener].
  ///
  /// The following sample specifies `buildDefaultDragHandles: false`, and
  /// uses a [Card] at the leading edge of each item for the item's drag handle.
  ///
  /// {@tool dartpad --template=stateful_widget_scaffold}
  ///
  /// ```dart
  /// final List<int> _items = List<int>.generate(50, (int index) => index);
  ///
  /// @override
  /// Widget build(BuildContext context){
  ///   final ColorScheme colorScheme = Theme.of(context).colorScheme;
  ///   final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
  ///   final Color evenItemColor = colorScheme.primary.withOpacity(0.15);
  ///
  ///   return ReorderableListView(
  ///     buildDefaultDragHandles: false,
  ///     children: <Widget>[
  ///       for (int index = 0; index < _items.length; index++)
  ///         Container(
  ///           key: Key('$index'),
  ///           color: _items[index].isOdd ? oddItemColor : evenItemColor,
  ///           child: Row(
  ///             children: <Widget>[
  ///               Container(
  ///                 width: 64,
  ///                 height: 64,
  ///                 padding: const EdgeInsets.all(8),
  ///                 child: ReorderableDragStartListener(
  ///                   index: index,
  ///                   child: Card(
  ///                     color: colorScheme.primary,
  ///                     elevation: 2,
  ///                   ),
  ///                 ),
  ///               ),
  ///               Text('Item ${_items[index]}'),
  ///             ],
  ///           ),
  ///         ),
  ///     ],
  ///     onReorder: (int oldIndex, int newIndex) {
  ///       setState(() {
  ///         if (oldIndex < newIndex) {
  ///           newIndex -= 1;
  ///         }
  ///         final int item = _items.removeAt(oldIndex);
  ///         _items.insert(newIndex, item);
  ///       });
  ///     },
  ///   );
  /// }
  /// ```
  ///{@end-tool}
  final bool buildDefaultDragHandles;

  /// {@macro flutter.widgets.reorderable_list.padding}
  final EdgeInsets? padding;

  /// A non-reorderable header item to show before the items of the list.
  ///
  /// If null, no header will appear before the list.
  final Widget? header;

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  /// {@macro flutter.widgets.scroll_view.reverse}
  final bool reverse;

  /// {@macro flutter.widgets.scroll_view.controller}
  final ScrollController? scrollController;

  /// {@macro flutter.widgets.scroll_view.primary}

  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [scrollController] is null.
  final bool? primary;

  /// {@macro flutter.widgets.scroll_view.physics}
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scroll_view.shrinkWrap}
  final bool shrinkWrap;

  /// {@macro flutter.widgets.scroll_view.anchor}
  final double anchor;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  ///
  /// The default is [ScrollViewKeyboardDismissBehavior.manual]
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  @override
  _SliderReorderableListViewState createState() =>
      _SliderReorderableListViewState();
}

class _SliderReorderableListViewState extends State<SliderReorderableListView> {
  Widget _wrapWithSemantics(Widget child, int index) {
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder(startIndex, endIndex);
      }
    }

    // First, determine which semantics actions apply.
    final Map<CustomSemanticsAction, VoidCallback> semanticsActions =
        <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, widget.itemCount);
    void moveBefore() => reorder(index, index - 1);
    // To move after, we go to index+2 because we are moving it to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => reorder(index, index + 2);

    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    // If the item can move to before its current position in the list.
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

    // If the item can move to after its current position in the list.
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

    // We pass toWrap with a GlobalKey into the item so that when it
    // gets dragged, the accessibility framework can preserve the selected
    // state of the dragging item.
    //
    // We also apply the relevant custom accessibility actions for moving the item
    // up, down, to the start, and to the end of the list.
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

    // TODO(goderbauer): The semantics stuff should probably happen inside
    //   _ReorderableItem so the widget versions can have them as well.
    final Widget itemWithSemantics = _wrapWithSemantics(item, index);
    final Key itemGlobalKey =
        _ReorderableListViewChildGlobalKey(item.key!, this);

    if (widget.buildDefaultDragHandles) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
        case TargetPlatform.macOS:
          switch (widget.scrollDirection) {
            case Axis.horizontal:
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  itemWithSemantics,
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    start: 0,
                    end: 0,
                    bottom: 8,
                    child: Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                ],
              );
            case Axis.vertical:
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  itemWithSemantics,
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: 0,
                    bottom: 0,
                    end: 8,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                ],
              );
          }

        case TargetPlatform.iOS:
        case TargetPlatform.android:
          return ReorderableDelayedDragStartListener(
            key: itemGlobalKey,
            index: index,
            child: itemWithSemantics,
          );
      }
    }

    return KeyedSubtree(
      key: itemGlobalKey,
      child: itemWithSemantics,
    );
  }

  Widget _proxyDecorator(
          Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(0, 6, animValue)!;
          return Material(
            elevation: elevation,
            child: child,
          );
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));

    // If there is a header we can't just apply the padding to the list,
    // so we wrap the CustomScrollView in the padding for the top, left and right
    // and only add the padding from the bottom to the sliver list (or the equivalent
    // for other axis directions).
    final EdgeInsets padding = widget.padding ?? EdgeInsets.zero;
    late EdgeInsets outerPadding;
    late EdgeInsets listPadding;
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        if (widget.reverse) {
          outerPadding = EdgeInsets.fromLTRB(
              0, padding.top, padding.right, padding.bottom);
          listPadding = EdgeInsets.fromLTRB(padding.left, 0, 0, 0);
        } else {
          outerPadding =
              EdgeInsets.fromLTRB(padding.left, padding.top, 0, padding.bottom);
          listPadding = EdgeInsets.fromLTRB(0, 0, padding.right, 0);
        }
        break;
      case Axis.vertical:
        if (widget.reverse) {
          outerPadding = EdgeInsets.fromLTRB(
              padding.left, 0, padding.right, padding.bottom);
          listPadding = EdgeInsets.fromLTRB(0, padding.top, 0, 0);
        } else {
          outerPadding =
              EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 0);
          listPadding = EdgeInsets.fromLTRB(0, 0, 0, padding.bottom);
        }
        break;
    }

    return Padding(
      padding: outerPadding,
      child: CustomScrollView(
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        controller: widget.scrollController,
        primary: widget.primary,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        anchor: widget.anchor,
        cacheExtent: widget.cacheExtent,
        dragStartBehavior: widget.dragStartBehavior,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        restorationId: widget.restorationId,
        clipBehavior: widget.clipBehavior,
        slivers: <Widget>[
          if (widget.header != null) SliverToBoxAdapter(child: widget.header!),
          SliverPadding(
            padding: listPadding,
            sliver: SliverReorderableList(
              itemBuilder: _itemBuilder,
              itemCount: widget.itemCount,
              onReorder: widget.onReorder,
              proxyDecorator: widget.proxyDecorator ?? _proxyDecorator,
            ),
          ),
        ],
      ),
    );
  }
}

// A global key that takes its identity from the object and uses a value of a
// particular type to identify itself.
//
// The difference with GlobalObjectKey is that it uses [==] instead of [identical]
// of the objects used to generate widgets.
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
