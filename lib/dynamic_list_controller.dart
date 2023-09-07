// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library flutter_dynamic_list_view;

import './scroll_to_index.dart';
import 'package:flutter/material.dart';
import './data_provider.dart';
import './scroll_judge.dart';

enum FetchType { previous, next, unknown }

class ValueChangeNotifier<T> extends ChangeNotifier {
  ValueChangeNotifier(T val) : _value = val;

  T _value;
  set value(T value) {
    _value = value;
    notifyListeners();
  }

  T get value {
    return _value;
  }
}

class DynamicListController<T extends Item> {
  static const int topIndex = 10000000;
  static const int bottomIndex = 10000001;
  final double topHeight;
  final double bottomHeight;
  final DataProvider<T> provider;
  final ScrollJudge scrollJudge;

  Data<T>? _cachedItems;

  final ValueChangeNotifier<Data<T>?> _items =
      ValueChangeNotifier<Data<T>?>(null);
  final ValueChangeNotifier<bool> _noMoreNext =
      ValueChangeNotifier<bool>(false);
  final ValueChangeNotifier<bool> _noMorePrevious =
      ValueChangeNotifier<bool>(false);
  final ValueChangeNotifier<bool> _loadingNext =
      ValueChangeNotifier<bool>(false);
  final ValueChangeNotifier<bool> _loadingPrevious =
      ValueChangeNotifier<bool>(false);
  FetchType lastLoadingType = FetchType.unknown;

  DynamicListController({
    required this.provider,
    required this.scrollJudge,
    this.topHeight = 0,
    this.bottomHeight = 0,
    Data<T>? items,
  }) {
    if (items != null) {
      _items.value = items;
      return;
    }
    provider.fetch().then((value) {
      _items.value = value;
    });
  }

  ValueChangeNotifier<bool> get loadingNext {
    return _loadingNext;
  }

  ValueChangeNotifier<bool> get loadingPrevious {
    return _loadingPrevious;
  }

  ValueChangeNotifier<bool> get noMoreNext {
    return _noMoreNext;
  }

  ValueChangeNotifier<bool> get noMorePrevious {
    return _noMorePrevious;
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
    Data<T>? items = _items.value;
    if (items == null) {
      return;
    }
    int index = items.indexOf(item);
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

  ValueChangeNotifier<Data<T>?> get items {
    return _items;
  }

  insert(List<T> items, CrudHint hint) {
    _items.value?.insert(items, hint);
  }

  remove(T item) {
    _items.value?.remove(item);
  }

  update(T item) {
    _items.value?.update(item);
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

  _cachePreviousPage() async {
    if (_noMorePrevious.value ||
        _loadingPrevious.value ||
        _cachedItems != null ||
        _items.value == null ||
        _items.value!.length() == 0) {
      return;
    }
    _loadingPrevious.value = true;
    _cachedItems = await provider.fetchPrevious(_items.value!.at(0)!);
    if (_cachedItems!.length() < provider.pageSize) {
      _noMorePrevious.value = true;
    }
    _loadingPrevious.value = false;
  }

  _cacheNextPage() async {
    if (_noMoreNext.value ||
        _loadingNext.value ||
        _cachedItems != null ||
        _items.value == null ||
        _items.value!.length() == 0) {
      return;
    }
    _loadingNext.value = true;
    _cachedItems =
        await provider.fetchNext(_items.value!.at(_items.value!.length() - 1)!);
    if (_cachedItems!.length() < provider.pageSize) {
      _noMoreNext.value = true;
    }
    _loadingNext.value = false;
  }

  _applyPreviousPageData() async {
    if (_cachedItems == null) {
      await _cachePreviousPage();
    }
    if (_cachedItems == null) {
      return;
    }
    _items.value?.insert(_cachedItems!.all(), CrudHint.head);
    _cachedItems = null;
  }

  _applyNextPageData() async {
    if (_cachedItems == null) {
      await _cacheNextPage();
    }
    if (_cachedItems == null) {
      return;
    }
    _items.value?.insert(_cachedItems!.all(), CrudHint.tail);
    _cachedItems = null;
  }
}
