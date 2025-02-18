import 'package:simdart/src/sim_context.dart';

/// The event to be executed.
///
/// A function that represents an event in the simulation.
typedef Event = void Function(SimContext context);
