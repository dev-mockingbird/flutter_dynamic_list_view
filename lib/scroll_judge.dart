// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

library flutter_dynamic_list_view;

import 'package:flutter/material.dart';

abstract class ScrollJudge {
  shouldCachePrevious(ScrollController controller);
  shouldCacheNext(ScrollController controller);
  shouldApplyPrevious(ScrollController controller);
  shouldApplyNext(ScrollController controller);
}

class PropotionScrollJudge extends ScrollJudge {
  double cacheNextPropotion;
  double applyNextPropotion;
  double cachePreviousPropotion;
  double applyPreviousPropotion;

  PropotionScrollJudge({
    this.cacheNextPropotion = 0.6,
    this.cachePreviousPropotion = 0.4,
    this.applyNextPropotion = 0.9,
    this.applyPreviousPropotion = 0.1,
  });

  @override
  shouldApplyNext(ScrollController controller) {
    return propotion(controller) > applyNextPropotion;
  }

  @override
  shouldApplyPrevious(ScrollController controller) {
    return propotion(controller) < applyPreviousPropotion;
  }

  @override
  shouldCacheNext(ScrollController controller) {
    return propotion(controller) > cacheNextPropotion;
  }

  @override
  shouldCachePrevious(ScrollController controller) {
    return propotion(controller) < cachePreviousPropotion;
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
