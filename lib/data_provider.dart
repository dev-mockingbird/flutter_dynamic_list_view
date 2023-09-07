// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library flutter_dynamic_list_view;

abstract class Item {
  String get id;
}

abstract class DataProvider<T extends Item> {
  Future<Data<T>> fetchPrevious(Item firstItem);
  Future<Data<T>> fetchNext(Item lastItem);
  Future<Data<T>> fetch();
  int get pageSize;
}

enum CrudHint { head, tail }

abstract class Data<T extends Item> {
  insert(List<T> data, CrudHint insertHint);
  removeAt(int index);
  remove(T item);
  update(T item);
  List<T> all();
  T? at(int idx);
  int indexOf(Item item);
  int length();
}

abstract class ListData<T extends Item> extends Data<T> {
  List<T> _items = [];

  @override
  insert(List<T> data, CrudHint insertHint) {
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
  removeAt(int index) {
    _items.removeAt(index);
  }

  @override
  update(T item) {
    int index = indexOf(item);
    if (index > -1) {
      _items[index] = item;
    }
  }

  @override
  remove(T item) {
    int index = indexOf(item);
    if (index > -1) {
      removeAt(index);
    }
  }

  @override
  List<T> all() {
    return _items;
  }

  @override
  T? at(int idx) {
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
}
