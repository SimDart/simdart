import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';

@internal
abstract class Resource {
  final String id;
  final int capacity;
  final List<EventContext> queue = [];
  final bool Function(EventContext context)? acquisitionRule;

  final List<EventContext> waiting = [];

  Resource({required this.id, this.capacity = 1, this.acquisitionRule});

  bool acquire(EventContext event);

  void release(EventContext event);

  bool isAvailable();
}

@internal
class LimitedResource extends Resource {
  LimitedResource({required super.id, super.capacity, super.acquisitionRule});

  @override
  bool acquire(EventContext event) {
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
  void release(EventContext event) {
    queue.remove(event);
  }

  @override
  bool isAvailable() {
    return queue.length < capacity;
  }
}
