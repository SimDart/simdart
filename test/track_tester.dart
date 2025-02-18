import 'package:simdart/simdart.dart';
import 'package:test/expect.dart';

class TrackTester {
  TrackTester(this.result);

  final SimResult result;

  int get length => result.tracks != null ? result.tracks!.length : 0;

  void test(List<String> tracks) {
    List<String> list = [];
    if (result.tracks != null) {
      for (SimulationTrack track in result.tracks!) {
        list.add(track.toString());
      }
    }
    expect(tracks, list);
  }
}
