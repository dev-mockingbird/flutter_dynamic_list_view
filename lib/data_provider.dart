// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library dynamic_list_view;

abstract class Item {
  String get id;
}

abstract class DataProvider {
  Future<Data> fetchPrevious(Item firstItem);
  Future<Data> fetchNext(Item firstItem);
  Future<Data> fetch();
  int get pageSize;
}

enum CrudHint { head, tail }

abstract class Data {
  insert(List<Item> data, CrudHint insertHint);
  remove(int size, CrudHint removeHint);
  List<Item> all();
  Item? at(int idx);
  int indexOf(Item item);
  int length();
  int get maintainSize;
}

abstract class ListData extends Data {
  List<Item> _items = [];

  @override
  insert(List<Item> data, CrudHint insertHint) {
    switch (insertHint) {
      case CrudHint.head:
        for (var item in _items) {
          bool exists = false;
          for (var i in data) {
            if (i.id == item.id) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            data.add(item);
          }
        }
        _items = data;
        break;
      case CrudHint.tail:
        for (var item in data) {
          bool exists = false;
          for (var i in _items) {
            if (i.id == item.id) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            _items.add(item);
          }
        }
    }
  }

  @override
  remove(int size, CrudHint removeHint) {
    switch (removeHint) {
      case CrudHint.head:
        _items = _items.sublist(size);
        break;
      case CrudHint.tail:
        _items = _items.sublist(0, _items.length - size);
    }
  }

  @override
  List<Item> all() {
    return _items;
  }

  @override
  Item? at(int idx) {
    if (idx > _items.length || idx < 0) {
      return null;
    }
    return _items[idx];
  }

  @override
  int length() {
    return _items.length;
  }

  @override
  int indexOf(Item item) {
    for (var i = 0; i < _items.length; i++) {
      if (item.id == _items[i].id) {
        return i;
      }
    }
    return -1;
  }

  @override
  int get maintainSize;
}
