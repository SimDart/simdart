import 'dart:async';
import 'dart:math';

import 'package:simdart/simdart.dart';
import 'package:simdart/src/internal/event_scheduler_interface.dart';

/// The event to be executed.
///
/// A function that represents an event in the simulation. It receives an
/// [EventContext] that provides data about the event's execution state and context.
typedef Event = void Function(EventContext context);
