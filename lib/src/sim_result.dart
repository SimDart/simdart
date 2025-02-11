import 'dart:collection';

import 'package:simdart/src/internal/sim_result_interface.dart';
import 'package:simdart/src/simulation_track.dart';

class SimResult implements SimResultInterface {
  SimResult(
      {required this.duration,
      required this.startTime,
      required List<SimulationTrack>? tracks})
      : tracks = tracks != null ? UnmodifiableListView(tracks) : null;

  @override
  final int duration;

  @override
  final int startTime;

  final List<SimulationTrack>? tracks;
}
