import 'package:meta/meta.dart';
import 'package:simdart/src/internal/event_action.dart';

@internal
abstract class Resource {
  final String id;
  final int capacity;
  final List<EventAction> queue = [];
  final bool Function(EventAction event)? acquisitionRule;

  final List<EventAction> waiting = [];

  Resource({required this.id, this.capacity = 1, this.acquisitionRule});

  bool acquire(EventAction event);

  void release(EventAction event);

  bool isAvailable();
}

@internal
class LimitedResource extends Resource {
  LimitedResource({required super.id, super.capacity, super.acquisitionRule});

  @override
  bool acquire(EventAction event) {
    if (acquisitionRule != null && !acquisitionRule!(event)) {
      // waiting.add(event);
      return false;
    }
    if (isAvailable()) {
      queue.add(event);
      return true;
    }

    // waiting.add(event);
    return false;
  }

  @override
  void release(EventAction event) {
    queue.remove(event);
  }

  @override
  bool isAvailable() {
    return queue.length < capacity;
  }
}
