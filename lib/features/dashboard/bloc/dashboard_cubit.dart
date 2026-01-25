import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final bool isSidebarVisible;
  final int activeTabIndex;

  const DashboardState({this.isSidebarVisible = true, this.activeTabIndex = 0});

  @override
  List<Object?> get props => [isSidebarVisible, activeTabIndex];

  DashboardState copyWith({bool? isSidebarVisible, int? activeTabIndex}) {
    return DashboardState(
      isSidebarVisible: isSidebarVisible ?? this.isSidebarVisible,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  void toggleSidebar() {
    emit(state.copyWith(isSidebarVisible: !state.isSidebarVisible));
  }

  void setSidebarVisibility(bool visible) {
    emit(state.copyWith(isSidebarVisible: visible));
  }

  void changeTab(int index) {
    emit(state.copyWith(activeTabIndex: index));
  }
}
