import 'package:meta/meta.dart';
import 'package:simdart/src/sim_context.dart';

@internal
abstract class Resource {
  final String id;
  final int capacity;
  final List<SimContext> queue = [];
  final bool Function(SimContext context)? acquisitionRule;

  final List<SimContext> waiting = [];

  Resource({required this.id, this.capacity = 1, this.acquisitionRule});

  bool acquire(SimContext event);

  void release(SimContext event);

  bool isAvailable();
}

@internal
class LimitedResource extends Resource {
  LimitedResource({required super.id, super.capacity, super.acquisitionRule});

  @override
  bool acquire(SimContext event) {
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
  void release(SimContext event) {
    queue.remove(event);
  }

  @override
  bool isAvailable() {
    return queue.length < capacity;
  }
}
