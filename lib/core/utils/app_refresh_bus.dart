import 'package:flutter/foundation.dart';

class AppRefreshBus {
  AppRefreshBus._();

  static final ValueNotifier<int> dashboardTick = ValueNotifier<int>(0);

  static void notifyDashboardChanged() {
    dashboardTick.value = dashboardTick.value + 1;
  }
}