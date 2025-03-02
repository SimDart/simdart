import 'package:meta/meta.dart';

@internal
abstract class DebugListener {

  void onScheduleNextAction();

  void onNextAction();
  
  void onExecuteAction();

  void onStop();

  void onAddCompleter();

  void onRemoveCompleter();
}

