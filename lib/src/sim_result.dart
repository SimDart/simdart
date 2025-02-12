import 'dart:collection';

import 'package:simdart/src/internal/sim_result_interface.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/simulation_track.dart';

class SimResult implements SimResultInterface {
  SimResult(
      {required this.duration,
      required this.startTime,
      required List<SimulationTrack>? tracks,
      required Map<String, SimNum> numProperties,
      required Map<String, SimCounter> counterProperties})
      : tracks = tracks != null ? UnmodifiableListView(tracks) : null,
        numProperties = UnmodifiableMapView(numProperties),
        counterProperties = UnmodifiableMapView(counterProperties);

  @override
  final int duration;

  @override
  final int startTime;

  final List<SimulationTrack>? tracks;

  final Map<String, SimNum> numProperties;
  final Map<String, SimCounter> counterProperties;
}
