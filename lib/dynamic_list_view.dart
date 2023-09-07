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
  final SliverAppBar? header;
  final Widget? noContent;
  final double? cacheExtent;

  final Axis? scrollDirection;
  final bool? reverse;
  final bool? primary;
  final ScrollBehavior? scrollBehavior;
  final bool? shrinkWrap;

  final int? semanticChildCount;
  final DragStartBehavior? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final String? restorationId;
  final Clip? clipBehavior;

  const DynamicListView({
    super.key,
    required this.itemsBuilder,
    required this.controller,
    this.scrollController,
    this.header,
    this.cacheExtent,
    this.noContent,
    this.scrollDirection,
    this.reverse,
    this.primary,
    this.scrollBehavior,
    this.shrinkWrap,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior,
  });

  @override
  State<DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  late AutoScrollController _scrollController;
  final GlobalKey _centerKey = GlobalKey();

  @override
  void initState() {
    _scrollController = widget.scrollController ?? AutoScrollController();
    widget.controller.installScrollListener(_scrollController);
    widget.controller.items.addListener(_updateUI);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      if (widget.header != null) widget.header!,
      ItemWrap(
          scrollController: _scrollController,
          index: DynamicListController.topIndex,
          child: SizedBox(height: widget.controller.topHeight))
    ];
    List<Item> data = widget.controller.items.value?.all() ?? [];
    if (data.isEmpty && widget.noContent != null) {
      children.add(SliverToBoxAdapter(child: widget.noContent));
    }
    List<Widget> items = widget.itemsBuilder(data);
    items.insert(
        items.length ~/ 2,
        ItemWrap(
            scrollController: widget.scrollController,
            index: 100000000,
            child: Container(),
            key: _centerKey));
    children.addAll(items);
    children.add(ItemWrap(
      scrollController: _scrollController,
      index: DynamicListController.bottomIndex,
      child: SizedBox(height: widget.controller.bottomHeight),
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
      center: _centerKey,
      controller: _scrollController,
      slivers: children,
    );
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
          child: child));
}
