// or material
import 'package:flutter/physics.dart';

class SwipePhysics extends ScrollPhysics {
  const SwipePhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  SwipePhysics applyTo(ScrollPhysics? ancestor) {
    return SwipePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 80,
        stiffness: 100,
        damping: 1,
      );
}

/* Example:
PageView(
  physics: const SwipePhysics(),
  ...
)
*/
