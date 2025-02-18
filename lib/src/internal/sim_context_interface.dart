import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/simdart.dart';

@internal
abstract class SimContextInterface {
  /// Pauses the execution of the event for the specified [delay] in simulation time.
  ///
  /// The event is re-added to the simulation's event queue and will resume after
  /// the specified delay has passed.
  ///
  /// Throws an [ArgumentError] if the delay is negative.
  Future<void> wait(int delay);
}
