import 'package:simdart/src/event_phase.dart';
import 'package:simdart/src/internal/debug_listener.dart';
import 'package:simdart/src/sim_listener.dart';
import 'package:test/expect.dart';

class TestHelper with SimListenerMixin implements DebugListener {
  final List<String> _events = [];

  int get length => _events.length;
  int _completerCount = 0;
  int get completerCount => _completerCount;

  void testEvents(List<String> events) {
    expect(_events, events);
  }

  @override
  void onEvent(
      {required String name,
      required int time,
      required EventPhase phase,
      required int executionHash}) {
    _events.add('[$time][$name][${phase.name}]');
  }

  @override
  void onStart() {
    _completerCount = 0;
    _events.clear();
  }

  @override
  void onAddCompleter() {
    _completerCount++;
  }

  @override
  void onRemoveCompleter() {
    _completerCount--;
  }
}
