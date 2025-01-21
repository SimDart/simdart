import 'dart:collection';

import 'package:simdart/simdart.dart';
import 'package:test/expect.dart';

class TestHelper {
  TestHelper() {
    sim = SimDart(onTrack: _onTrack, secondarySortByName: true);
  }

  late final SimDart sim;

  final List<SimulationTrack> _trackList = [];

  late final UnmodifiableListView<SimulationTrack> trackList =
      UnmodifiableListView(_trackList);

  void _onTrack(SimulationTrack track) {
    _trackList.add(track);
  }

  void testTrack(
      {required int index,
      required String? name,
      required Status status,
      required int time}) {
    expect(trackList[index].name, name);
    expect(trackList[index].status, status);
    expect(trackList[index].time, time);
  }

  static Future<void> emptyEvent(EventContext context) async {}
}
