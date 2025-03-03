import 'package:meta/meta.dart';

@internal
abstract class DebugListener {

  void onScheduleNextAction();

  void onExecuteAction();

  void onStop();

  void onAddCompleter();

  void onRemoveCompleter();
}

