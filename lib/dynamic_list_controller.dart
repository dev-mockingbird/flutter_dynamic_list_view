// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library flutter_dynamic_list_view;

import 'package:flutter/foundation.dart';

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

class DataChangeNotifier<T extends Item> extends ChangeNotifier
    implements Data<T> {
  Data<T>? _value;

  @override
  insert(List<T> data, CrudHint insertHint) {
    _value?.insert(data, insertHint);
    notifyListeners();
  }

  @override
  removeAt(int index) {
    _value?.removeAt(index);
    notifyListeners();
  }

  @override
  remove(T item) {
    _value?.remove(item);
    notifyListeners();
  }

  @override
  update(T item) {
    _value?.update(item);
    notifyListeners();
  }

  @override
  List<T> all() {
    return _value?.all() ?? [];
  }

  @override
  T? at(int idx) {
    return _value?.at(idx);
  }

  @override
  int indexOf(Item item) {
    return _value?.indexOf(item) ?? -1;
  }

  @override
  int length() {
    return _value?.length() ?? 0;
  }

  set value(Data<T>? value) {
    _value = value;
    notifyListeners();
  }
}

class DynamicListController<T extends Item> {
  static const int topIndex = 10000000;
  static const int bottomIndex = 10000001;
  final bool disableCenter;
  final ValueChangeNotifier<double> topHeight = ValueChangeNotifier(0.0);
  final ValueChangeNotifier<double> bottomHeight = ValueChangeNotifier(0.0);
  final DataProvider<T> provider;
  final ScrollJudge scrollJudge;

  Data<T>? _cachedNextItems;
  Data<T>? _cachedPreviousItems;

  final DataChangeNotifier<T> _items = DataChangeNotifier();
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
    this.disableCenter = false,
    Data<T>? items,
  }) {
    if (items != null) {
      _items.value = items;
      return;
    }
  }

  initItems({Duration? minimumWait}) async {
    _loadingNext.value = true;
    _loadingPrevious.value = true;
    fetchDone() {
      _loadingNext.value = false;
      _loadingPrevious.value = false;
      if (_items.length() == 0) {
        _noMoreNext.value = true;
        _noMorePrevious.value = true;
        return;
      }
      _noMoreNext.value = !provider.hasMoreNext(
        _items.at(_items.length() - 1)!,
      );
      _noMorePrevious.value = !provider.hasMorePrevious(_items.at(0)!);
    }

    if (minimumWait == null) {
      _items.value = await provider.fetch();
      fetchDone();
      return;
    }
    Data<T>? items;
    doInitItems() async {
      items = await provider.fetch();
    }

    await Future.wait([
      doInitItems(),
      Future.delayed(minimumWait),
    ]);
    _items.value = items;
    fetchDone();
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
    scrollController.scrollToIndex(
      topIndex,
      preferPosition: AutoScrollPosition.begin,
      duration: duration,
    );
  }

  scrollToBottom(AutoScrollController scrollController, {Duration? duration}) {
    scrollController.scrollToIndex(
      bottomIndex,
      preferPosition: AutoScrollPosition.end,
      duration: duration,
    );
  }

  scrollToItem(AutoScrollController scrollController, Item item,
      {Duration? duration,
      AutoScrollPosition preferPosition = AutoScrollPosition.middle}) {
    int index = _items.indexOf(item);
    double offset = 0;
    if (preferPosition == AutoScrollPosition.begin) {
      offset -= topHeight.value;
    }
    if (index > -1) {
      scrollController.scrollToIndex(index,
          preferPosition: preferPosition,
          duration: duration,
          relativeOffset: offset);
    }
  }

  DataChangeNotifier<T> get items {
    return _items;
  }

  insert(List<T> items, CrudHint hint) {
    _items.insert(items, hint);
  }

  remove(T item) {
    _items.remove(item);
  }

  update(T item) {
    _items.update(item);
  }

  installScrollListener(AutoScrollController controller) {
    bool handling = false;
    controller.addListener(() async {
      if (handling) {
        return;
      }
      handling = true;
      if (scrollJudge.shouldCachePrevious(controller)) {
        await _cachePreviousPage();
      }
      if (scrollJudge.shouldCacheNext(controller)) {
        await _cacheNextPage();
      }
      if (disableCenter && controller.offset == 0 ||
          !disableCenter && scrollJudge.shouldApplyPrevious(controller)) {
        await _applyPreviousPageData(controller);
      }
      if (scrollJudge.shouldApplyNext(controller)) {
        await _applyNextPageData(controller);
      }
      handling = false;
    });
  }

  _cachePreviousPage() async {
    if (_noMorePrevious.value ||
        _loadingPrevious.value ||
        _cachedPreviousItems != null ||
        _items.length() == 0) {
      return;
    }
    _loadingPrevious.value = true;
    var firstItem = _items.at(0)!;
    if (kDebugMode) {
      print("start cache previous from: ${firstItem.id}");
    }
    _cachedPreviousItems = await provider.fetchPrevious(firstItem);
    _loadingPrevious.value = false;
  }

  _cacheNextPage() async {
    if (_noMoreNext.value ||
        _loadingNext.value ||
        _cachedNextItems != null ||
        _items.length() == 0) {
      return;
    }
    _loadingNext.value = true;
    var lastItem = _items.at(_items.length() - 1)!;
    if (kDebugMode) {
      print("start cache next from: ${lastItem.id}");
    }
    _cachedNextItems = await provider.fetchNext(lastItem);
    _loadingNext.value = false;
  }

  _applyPreviousPageData(AutoScrollController controller) async {
    if (_cachedPreviousItems == null) {
      await _cachePreviousPage();
    }
    if (_cachedPreviousItems == null) {
      return;
    }
    if (kDebugMode) {
      print("apply cached previous");
    }
    if (disableCenter) {
      Item item = _items.at(0)!;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        scrollToItem(controller, item,
            preferPosition: AutoScrollPosition.begin);
      });
    }
    _items.insert(_cachedPreviousItems!.all(), CrudHint.head);
    _noMorePrevious.value = !provider.hasMorePrevious(_items.at(0) as T);
    _cachedPreviousItems = null;
  }

  _applyNextPageData(AutoScrollController controller) async {
    if (_cachedNextItems == null) {
      await _cacheNextPage();
    }
    if (_cachedNextItems == null) {
      return;
    }
    if (kDebugMode) {
      print("apply cached next");
    }
    if (disableCenter) {
      Item item = _items.all()[_items.length() - 1];
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        scrollToItem(controller, item, preferPosition: AutoScrollPosition.end);
      });
    }
    _items.insert(_cachedNextItems!.all(), CrudHint.tail);
    _noMoreNext.value =
        !provider.hasMoreNext(_items.at(_items.length() - 1) as T);
    _cachedNextItems = null;
  }
}
