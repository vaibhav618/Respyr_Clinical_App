import 'package:cupertino_battery_indicator/cupertino_battery_indicator.dart';
import 'package:flutter/material.dart';
import 'package:respyr_clinical/shared/colors.dart';

class BatteryUtils {
  static const double fullBatteryVoltage = 4.2;
  static const double emptyBatteryVoltage = 3.40;
  static const double voltageDividerFactor = 6.5577;

  /// Convert raw input voltage (e.g. 0.63V) into actual battery voltage and then to percentage.
  static int calculateBatteryPercentage(double inputVoltage) {
    // Adjust using calibration (device-specific)
    final actualVoltage =
        0.9766 * (inputVoltage * voltageDividerFactor) + 0.1026;

    if (actualVoltage >= fullBatteryVoltage) return 100;
    if (actualVoltage <= emptyBatteryVoltage) return 0;

    final percentage =
        ((actualVoltage - emptyBatteryVoltage) /
            (fullBatteryVoltage - emptyBatteryVoltage)) *
        100;
    return percentage.round();
  }

  static Widget batteryIndicatorWidget(int batteryPercentage) {
    return BatteryIndicator(
      trackAspectRatio: 2,
      value: batteryPercentage / 100,
      barColor:
          batteryPercentage <= 30 ? Colors.red : AppColor.primaryBlackColor,
      trackBorderColor:
          batteryPercentage <= 30 ? Colors.red : AppColor.primaryBlackColor,
      trackHeight: 12,
    );
  }
}
