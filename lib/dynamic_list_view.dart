library flutter_dynamic_list_view;

import 'package:flutter_dynamic_list_view/data_provider.dart';
import 'package:flutter_dynamic_list_view/dynamic_list_controller.dart';
import 'package:flutter_dynamic_list_view/scroll_to_index.dart';
import 'package:flutter/material.dart';

typedef ItemsBuilder = List<Widget> Function(
    List<Item> data, Map<String, GlobalKey> keys);

class DynamicListView extends StatefulWidget {
  final DynamicListController controller;
  final AutoScrollController? scrollController;
  final ItemsBuilder itemsBuilder;
  final Widget? header;
  final Widget? noContent;

  const DynamicListView({
    super.key,
    required this.itemsBuilder,
    required this.controller,
    this.scrollController,
    this.header,
    this.noContent,
  });

  @override
  State<DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  late AutoScrollController _scrollController;
  final Map<String, GlobalKey> _msgKeys = {};
  Key? _centerKey;

  @override
  void initState() {
    _scrollController = widget.scrollController ?? AutoScrollController();
    widget.controller.installScrollListener(_scrollController);
    widget.controller.addDataListener((type, data) {
      _updateUI();
    });
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
    List<Item> data = widget.controller.items;
    if (data.isEmpty && widget.noContent != null) {
      children.add(SliverToBoxAdapter(child: widget.noContent));
    }
    _msgKeys.clear();
    for (var item in data) {
      var key = GlobalKey();
      _msgKeys[item.id] = key;
    }
    List<Widget> items = widget.itemsBuilder(data, _msgKeys);
    if (items.isNotEmpty) {
      _centerKey = items[items.length ~/ 2].key;
    }
    children.addAll(items);
    children.add(ItemWrap(
      scrollController: _scrollController,
      index: DynamicListController.bottomIndex,
      child: SizedBox(height: widget.controller.bottomHeight),
    ));
    return CustomScrollView(
      cacheExtent: 100,
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
