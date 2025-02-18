import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/resources_context_impl.dart';
import 'package:simdart/src/internal/sim_context_interface.dart';
import 'package:simdart/src/internal/simdart_interface.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resources_context.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/simdart.dart';

class SimContext implements SimDartInterface, SimContextInterface {
  SimContext._({required SimDart sim, required EventAction event})
      : _sim = sim,
        _event = event;

  final SimDart _sim;
  final EventAction _event;
  late final ResourcesContext resources = ResourcesContextImpl(_sim, _event);

  @override
  int get now => _sim.now;

  @override
  void process({required Event event, String? name, int? start, int? delay}) {
    _sim.process(event: event, name: name, start: start, delay: delay);
  }

  @override
  void repeatProcess(
      {required Event event,
      int? start,
      int? delay,
      required Interval interval,
      StopCondition? stopCondition,
      String Function(int start)? name}) {
    _sim.repeatProcess(
        event: event,
        start: start,
        delay: delay,
        interval: interval,
        stopCondition: stopCondition,
        name: name);
  }

  @override
  SimCounter counter(String name) {
    return _sim.counter(name);
  }

  @override
  SimNum num(String name) {
    return _sim.num(name);
  }

  @override
  Future<void> wait(int delay) async {
    return _event.wait(delay);
  }
}

@internal
class SimContextHelper {
  static SimContext build({required SimDart sim, required EventAction event}) =>
      SimContext._(sim: sim, event: event);
}
