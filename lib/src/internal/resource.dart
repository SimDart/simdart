import 'package:meta/meta.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/simdart.dart';

@internal
abstract class Resource {
  final String id;
  final int capacity;
  final List<EventAction> queue = [];
  final bool Function(EventAction event)? acquisitionRule;

  /// A queue that holds completer to resume events waiting for a resource to become available.
  final List<EventAction> waiting = [];

  Resource({required this.id, this.capacity = 1, this.acquisitionRule});

  bool acquire(EventAction event);

  bool release(SimDart sim, EventAction event);

  bool isAvailable();
}

@internal
class LimitedResource extends Resource {
  LimitedResource({required super.id, super.capacity, super.acquisitionRule});

  @override
  bool acquire(EventAction event) {
    if (acquisitionRule != null && !acquisitionRule!(event)) {
      return false;
    }
    if (isAvailable()) {
      queue.add(event);
      return true;
    }

    return false;
  }

  @override
  bool release(SimDart sim, EventAction event) {
    return queue.remove(event);
  }

  @override
  bool isAvailable() {
    return queue.length < capacity;
  }
}
