import 'package:simdart/src/event_phase.dart';
import 'package:simdart/src/sim_observer.dart';
import 'package:test/expect.dart';

class TestHelper with SimObserverMixin {
  final List<String> _events = [];

  int get length => _events.length;

  Function? afterOnFinishedEvent;

  void test(List<String> events) {
    expect(events, _events);
  }

  @override
  void onEvent(
      {required String name,
      required int time,
      required EventPhase phase,
      required int executionHash}) {
    _events.add('[$time][$name][${phase.name}]');
    if (phase == EventPhase.finished) {
      afterOnFinishedEvent?.call();
    }
  }

  @override
  void onStart() {
    _events.clear();
  }
}
