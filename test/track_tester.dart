import 'package:simdart/simdart.dart';
import 'package:simdart/src/sim_result.dart';
import 'package:test/expect.dart';

class TrackTester {
  TrackTester(this.result);

  final SimResult result;

  int get length => result.tracks != null ? result.tracks!.length : 0;

  void test(List<String> tracks) {
    expect(tracks.length, result.tracks?.length);
    for (int index = 0; index < tracks.length; index++) {
      SimulationTrack? track = result.tracks?[index];
      expect(tracks[index], track?.toString());
    }
  }
}
