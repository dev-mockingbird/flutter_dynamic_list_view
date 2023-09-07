// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library dynamic_list_view;

import 'package:dynamic_list_view/scroll_to_index.dart';
import 'package:flutter/material.dart';
import './data_provider.dart';
import './scroll_judge.dart';

enum LoadingType { previous, next }

enum DataChangeType { previous, next }

typedef LoadingListener = Function(LoadingType type, bool loading);
typedef DataChangeListener = Function(DataChangeType type, Data data);

class DynamicListController<T> {
  static const int topIndex = 10000000;
  static const int bottomIndex = 10000001;
  final double topHeight;
  final double bottomHeight;
  final DataProvider provider;
  final ScrollJudge scrollJudge;
  final List<LoadingListener> _loadingListeners = [];
  final List<DataChangeListener> _dataListeners = [];

  Data? _items;
  Data? _cachedItems;

  bool noMoreNext = false;
  bool noMorePrevious = false;
  bool _loadingNext = false;
  bool _loadingPrevious = false;

  DynamicListController({
    required this.provider,
    required this.scrollJudge,
    this.topHeight = 0,
    this.bottomHeight = 0,
    Data? items,
  }) : _items = items {
    if (_items == null) {
      provider.fetch().then((value) {
        _items = value;
        _notifyDataChange(DataChangeType.next);
      });
    }
  }

  scrollToTop(AutoScrollController scrollController, {Duration? duration}) {
    scrollController.scrollToIndex(topIndex,
        preferPosition: AutoScrollPosition.begin, duration: duration);
  }

  scrollToBottom(AutoScrollController scrollController, {Duration? duration}) {
    scrollController.scrollToIndex(bottomIndex,
        preferPosition: AutoScrollPosition.end, duration: duration);
  }

  scrollToItem(AutoScrollController scrollController, Item item,
      {Duration? duration,
      AutoScrollPosition preferPosition = AutoScrollPosition.middle}) {
    if (_items == null) {
      return;
    }
    int index = _items!.indexOf(item);
    double offset = 0;
    if (preferPosition == AutoScrollPosition.begin) {
      offset -= topHeight;
    } else if (preferPosition == AutoScrollPosition.end) {
      offset += bottomHeight;
    }
    if (index > -1) {
      scrollController.scrollToIndex(index,
          preferPosition: preferPosition,
          duration: duration,
          relativeOffset: offset);
    }
  }

  List<Item> get items {
    if (_items == null) {
      return [];
    }
    return _items!.all();
  }

  installScrollListener(ScrollController controller) {
    controller.addListener(() {
      if (scrollJudge.shouldCachePrevious(controller)) {
        _cachePreviousPage();
      }
      if (scrollJudge.shouldCacheNext(controller)) {
        _cacheNextPage();
      }
      if (scrollJudge.shouldApplyNext(controller)) {
        _applyNextPageData();
      }
      if (scrollJudge.shouldApplyPrevious(controller)) {
        _applyPreviousPageData();
      }
    });
  }

  addLoadingListener(LoadingListener listener) {
    _loadingListeners.add(listener);
  }

  addDataListener(DataChangeListener listener) {
    _dataListeners.add(listener);
  }

  goto(Item item) {}

  gotoOldest() {}

  gotoLatest() {}

  _cachePreviousPage() async {
    if (noMorePrevious ||
        _loadingPrevious ||
        _cachedItems != null ||
        _items == null ||
        _items!.length() == 0) {
      return;
    }
    _changeLoading(LoadingType.previous, true);
    _cachedItems = await provider.fetchPrevious(_items!.at(0)!);
    if (_cachedItems!.length() < provider.pageSize) {
      noMorePrevious = true;
    }
    _changeLoading(LoadingType.previous, false);
  }

  _cacheNextPage() async {
    if (noMoreNext ||
        _loadingNext ||
        _cachedItems != null ||
        _items == null ||
        _items!.length() == 0) {
      return;
    }
    _changeLoading(LoadingType.next, true);
    _cachedItems = await provider.fetchNext(_items!.at(_items!.length() - 1)!);
    if (_cachedItems!.length() < provider.pageSize) {
      noMoreNext = true;
    }
    _changeLoading(LoadingType.next, false);
  }

  _changeLoading(LoadingType type, bool loading) {
    switch (type) {
      case LoadingType.next:
        _loadingNext = loading;
      case LoadingType.previous:
        _loadingPrevious = loading;
    }
    for (var listener in _loadingListeners) {
      listener(type, loading);
    }
  }

  _notifyDataChange(DataChangeType type) {
    for (var listener in _dataListeners) {
      listener(type, _items!);
    }
  }

  _applyPreviousPageData() async {
    if (_cachedItems == null) {
      await _cachePreviousPage();
    }
    if (_cachedItems == null) {
      return;
    }
    _items!.insert(_cachedItems!.all(), CrudHint.head);
    _cachedItems = null;
    _notifyDataChange(DataChangeType.previous);
  }

  _applyNextPageData() async {
    if (_cachedItems == null) {
      await _cacheNextPage();
    }
    if (_cachedItems == null) {
      return;
    }
    _items!.insert(_cachedItems!.all(), CrudHint.tail);
    _cachedItems = null;
    _notifyDataChange(DataChangeType.next);
  }
}
