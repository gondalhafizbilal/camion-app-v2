import 'package:flutter_bloc/flutter_bloc.dart';

part 'toggle_join_us_state.dart';

class ToggleJoinUsInfluencerCubit extends Cubit<ToggleJoinUsState> {
  ToggleJoinUsInfluencerCubit() : super(const ToggleInitial());

  void toggle(int index) {
    emit(ToggleChanged(index: index));
  }
}
