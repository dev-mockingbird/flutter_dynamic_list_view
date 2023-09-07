// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library dynamic_list_view;

import 'package:flutter/material.dart';

abstract class ScrollJudge {
  shouldCachePrevious(ScrollController controller);
  shouldCacheNext(ScrollController controller);
  shouldApplyPrevious(ScrollController controller);
  shouldApplyNext(ScrollController controller);
}

class DefaultScrollJudge extends ScrollJudge {
  @override
  shouldApplyNext(ScrollController controller) {
    return propotion(controller) > 0.9;
  }

  @override
  shouldApplyPrevious(ScrollController controller) {
    return propotion(controller) < 0.1;
  }

  @override
  shouldCacheNext(ScrollController controller) {
    return propotion(controller) > 0.5;
  }

  @override
  shouldCachePrevious(ScrollController controller) {
    return propotion(controller) < 0.5;
  }

  @protected
  double offset(ScrollController controller) {
    return controller.offset - controller.position.minScrollExtent;
  }

  @protected
  double total(ScrollController controller) {
    return controller.position.maxScrollExtent -
        controller.position.minScrollExtent;
  }

  @protected
  double propotion(ScrollController controller) {
    return offset(controller) / total(controller);
  }
}
