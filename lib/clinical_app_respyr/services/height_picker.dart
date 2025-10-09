import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:respyr_clinical/shared/colors.dart';

class HeightPicker extends StatefulWidget {
  // Required initial values
  final int cmValue;
  final int ftValue;
  final int inchValue;

  // Optional properties
  final String initialUnit;

  // Callbacks
  final Function(int) onCmChanged;
  final Function(int, int) onFtInchChanged;
  final VoidCallback onDone;

  const HeightPicker({
    super.key,
    required this.cmValue,
    required this.ftValue,
    required this.inchValue,
    required this.initialUnit,
    required this.onCmChanged,
    required this.onFtInchChanged,
    required this.onDone,
  });

  @override
  State<HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<HeightPicker> {
  // Temporary values to hold changes until "Done" is pressed
  late int _tempCmValue;
  late int _tempFtValue;
  late int _tempInchValue;
  late String selectedUnit;

  Map<String, int> _convertCmToFtInch(double cm) {
    final inchesTotal = (cm / 2.54).round();
    final feet = inchesTotal ~/ 12;
    final inches = inchesTotal % 12;
    return {'feet': feet, 'inches': inches};
  }

  // Convert feet and inches to centimeters
  double _convertFtInchToCm(int feet, int inches) {
    return (feet * 30.48) + (inches * 2.54);
  }

  @override
  void initState() {
    super.initState();
    _tempCmValue = widget.cmValue;
    _tempFtValue = widget.ftValue;
    _tempInchValue = widget.inchValue;
    selectedUnit = widget.initialUnit;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                // Commit the changes to the parent state only when "Done" is pressed
                setState(() {
                  if (selectedUnit == 'cm') {
                    widget.onCmChanged(_tempCmValue);
                  } else {
                    widget.onFtInchChanged(_tempFtValue, _tempInchValue);
                  }
                });
                widget.onDone();
                Navigator.pop(context);
              },
              icon: Text(
                'Done',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: AppColor.primaryBlueColor,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          selectedUnit == 'cm' ? _buildCmPicker() : _buildFtInchPicker(),
        ],
      ),
    );
  }

  Widget _buildCmPicker() {
    return Column(
      children: [
        Text(
          'Centimeter',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            color: AppColor.primaryBlueColor,
          ),
        ),
        NumberPicker(
          value: _tempCmValue,
          minValue: 0,
          maxValue: 500,
          onChanged: (value) {
            setState(() {
              _tempCmValue = value;
              final ftInch = _convertCmToFtInch(_tempCmValue.toDouble());
              _tempFtValue = ftInch['feet']!;
              _tempInchValue = ftInch['inches']!;
            });
          },
          itemHeight: 90,
          textStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlueColor,
          ),
          selectedTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColor.primaryBlueColor,
          ),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColor.primaryBlueColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFtInchPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              'Feet',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: AppColor.primaryBlueColor,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            NumberPicker(
              value: _tempFtValue,
              minValue: 0,
              maxValue: 10,
              onChanged: (value) {
                setState(() {
                  _tempFtValue = value;
                  _tempCmValue =
                      _convertFtInchToCm(_tempFtValue, _tempInchValue).round();
                });
              },
              itemHeight: 90,
              textStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColor.primaryBlueColor,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColor.primaryBlueColor,
              ),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColor.primaryBlueColor),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Column(
          children: [
            Text(
              'Inches',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: AppColor.primaryBlueColor,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            NumberPicker(
              value: _tempInchValue,
              minValue: 0,
              maxValue: 11,
              onChanged: (value) {
                setState(() {
                  _tempInchValue = value;
                  _tempCmValue =
                      _convertFtInchToCm(_tempFtValue, _tempInchValue).round();
                });
              },
              itemHeight: 90,
              textStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColor.primaryBlueColor,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColor.primaryBlueColor,
              ),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColor.primaryBlueColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
