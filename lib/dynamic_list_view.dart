library flutter_dynamic_list_view;

import 'package:flutter/gestures.dart';
import 'package:flutter_dynamic_list_view/data_provider.dart';
import 'package:flutter_dynamic_list_view/dynamic_list_controller.dart';
import 'package:flutter_dynamic_list_view/scroll_to_index.dart';
import 'package:flutter/material.dart';

typedef ItemsBuilder<T extends Item> = List<Widget> Function(List<T> data);

class DynamicListView extends StatefulWidget {
  final DynamicListController controller;
  final AutoScrollController? scrollController;
  final ItemsBuilder itemsBuilder;
  final Widget? noContent;
  final Widget? header;
  final double? cacheExtent;

  final Axis? scrollDirection;
  final bool? reverse;
  final bool? primary;
  final ScrollBehavior? scrollBehavior;
  final bool? shrinkWrap;
  final Function(double contentHeight)? onContentHeightChanged;

  final int? semanticChildCount;
  final DragStartBehavior? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final String? restorationId;
  final Clip? clipBehavior;
  final double? minHeight;

  DynamicListView({
    super.key,
    required this.itemsBuilder,
    required this.controller,
    this.scrollController,
    this.cacheExtent,
    this.noContent,
    this.scrollDirection,
    this.reverse,
    this.header,
    this.primary,
    this.scrollBehavior,
    this.shrinkWrap,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior,
    this.minHeight,
    this.onContentHeightChanged,
  }) {
    // cant't enable center with header
    // https://github.com/flutter/flutter/issues/39715
    assert(!(!controller.disableCenter && header != null));
  }

  @override
  State<DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  late AutoScrollController _scrollController;
  final GlobalKey _centerKey = GlobalKey();
  double _bottomHeight = 0;
  @override
  void initState() {
    _scrollController = widget.scrollController ?? AutoScrollController();
    widget.controller.installScrollListener(_scrollController);
    widget.controller.items.addListener(_updateUI);
    widget.controller.bottomHeight.addListener(_updateUI);
    widget.controller.topHeight.addListener(_updateUI);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    widget.controller.items.removeListener(_updateUI);
    widget.controller.bottomHeight.removeListener(_updateUI);
    widget.controller.topHeight.removeListener(_updateUI);
    super.dispose();
  }

  _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _resetBottomHeight();
    });
    var children = <Widget>[
      if (widget.header != null) widget.header!,
      ItemWrap(
          scrollController: _scrollController,
          index: DynamicListController.topIndex,
          child: SizedBox(height: widget.controller.topHeight.value))
    ];
    List<Item> data = widget.controller.items.all();
    if (data.isEmpty && widget.noContent != null) {
      children.add(SliverToBoxAdapter(child: widget.noContent));
    }
    List<Widget> items = widget.itemsBuilder(data);
    if (!widget.controller.disableCenter) {
      items.insert(
        items.length ~/ 2,
        ItemWrap(
          scrollController: widget.scrollController,
          index: 100000000,
          child: Container(),
          key: _centerKey,
        ),
      );
    }
    children.addAll(items);
    if (_bottomHeight > 0.0) {
      children.add(SliverToBoxAdapter(child: SizedBox(height: _bottomHeight)));
    }
    children.add(ItemWrap(
      scrollController: _scrollController,
      index: DynamicListController.bottomIndex,
      child: SizedBox(
        height: widget.controller.bottomHeight.value,
      ),
    ));
    return CustomScrollView(
      cacheExtent: widget.cacheExtent,
      scrollDirection: widget.scrollDirection ?? Axis.vertical,
      reverse: widget.reverse ?? false,
      primary: widget.primary,
      scrollBehavior: widget.scrollBehavior,
      shrinkWrap: widget.shrinkWrap ?? false,
      semanticChildCount: widget.semanticChildCount,
      dragStartBehavior: widget.dragStartBehavior ?? DragStartBehavior.start,
      keyboardDismissBehavior: widget.keyboardDismissBehavior ??
          ScrollViewKeyboardDismissBehavior.manual,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior ?? Clip.hardEdge,
      center: widget.controller.disableCenter ? null : _centerKey,
      anchor: widget.controller.disableCenter ? 0.0 : 0.5,
      controller: _scrollController,
      slivers: children,
    );
  }

  _resetBottomHeight() {
    if (widget.minHeight == 0) {
      return;
    }
    var height = _scrollController.position.maxScrollExtent -
        _scrollController.position.minScrollExtent;

    if (widget.onContentHeightChanged != null) {
      widget.onContentHeightChanged!(height - _bottomHeight);
    }
    var bottomHeight = widget.minHeight! - (height - _bottomHeight);
    if (bottomHeight < 0) {
      bottomHeight = 0;
    }
    if (bottomHeight != _bottomHeight) {
      setState(() {
        _bottomHeight = bottomHeight;
      });
    }
  }
}

SliverToBoxAdapter ItemWrap(
    {required scrollController,
    required int index,
    required Widget child,
    GlobalKey? key}) {
  return SliverToBoxAdapter(
    key: key,
    child: AutoScrollTag(
      key: ValueKey(index),
      controller: scrollController,
      index: index,
      child: child,
    ),
  );
}
