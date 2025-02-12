import 'package:simdart/simdart.dart';

/// The event to be executed.
///
/// A function that represents an event in the simulation. It receives an
/// [SimContext] that provides data about the event's execution state and context.
typedef Event = void Function(SimContext context);
