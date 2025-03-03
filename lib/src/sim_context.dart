import 'package:simdart/src/internal/simdart_interface.dart';
import 'package:simdart/src/resources.dart';

abstract interface class SimContext implements SimDartInterface {
  /// Pauses the execution of the event for the specified [delay] in simulation time.
  ///
  /// The event is re-added to the simulation's event queue and will resume after
  /// the specified delay has passed.
  ///
  /// Throws an [ArgumentError] if the delay is negative.
  Future<void> wait(int delay);

  String get eventName;

  ResourcesContext get resources;

  void stop();
}
