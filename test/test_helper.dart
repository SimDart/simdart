import 'package:simdart/src/event_phase.dart';
import 'package:simdart/src/internal/debug_listener.dart';
import 'package:simdart/src/sim_listener.dart';
import 'package:test/expect.dart';

class TestHelper with SimListenerMixin implements DebugListener {
  final List<String> _events = [];
  final List<String> _tracks =[];

  int get length => _events.length;
  int _completerCount=0;
  int get completerCount=>_completerCount;

  void testEvents(List<String> events) {
    expect(_events, events);
  }

  void testTracks(List<String> tracks) {
    expect(_tracks, tracks);
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
    _completerCount=0;
    _events.clear();
    _tracks.clear();
  }

  @override
  void onScheduleNextAction(){
    _tracks.add('scheduleNextAction');
  }

  @override
  void onNextAction() {
    _tracks.add('nextAction');
  }

  @override
  void onExecuteAction() {
    _tracks.add('executeAction');
  }

  @override
  void onStop() {
    _tracks.add('stop');
  }

  @override
  void onAddCompleter(){
    _completerCount++;
  }

  @override
  void onRemoveCompleter(){
    _completerCount--;
  }


}
