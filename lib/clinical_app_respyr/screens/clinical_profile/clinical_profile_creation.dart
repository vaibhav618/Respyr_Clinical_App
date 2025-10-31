import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/clinical_profile/clinical_profile_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/clinical_profile_creation_api.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/height_picker.dart';
import 'package:respyr_clinical/device_connectivity/presentation/pages/device_connectivity_screen.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../new_result/data/model/result_profile_data_model.dart';

class ClinicalProfileCreation extends StatefulWidget {
  final ResultProfileDataModel profileDetails;
  const ClinicalProfileCreation({super.key, required this.profileDetails});

  @override
  State<ClinicalProfileCreation> createState() =>
      _ClinicalProfileCreationState();
}

class _ClinicalProfileCreationState extends State<ClinicalProfileCreation> {
  String? selectedUnit = 'cm';

  bool isMale = true;

  int? _cmValue;
  int _inchValue = 9;
  int _ftValue = 4;
  int _weightValue = 50;
  bool initialIsMale = false;
  bool isSaveButtonEnabled = false;
  String? initialHeight;
  String? initialWeight;
  String? initialName;
  String? initialAge;
  String? _usernameError;
  String? _ageError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set initials only once here
    initialName = _nameController.text.trim();
    initialAge = _ageController.text.trim();
    initialWeight = _weightController.text.trim();
    initialHeight =
        '$_ftValue\' $_inchValue"'; // or '$_cmValue cm' based on unit
    initialIsMale = isMale;
    _updateWeight();
    _updateHeight();
  }

  void _updateHeight() {
    if (selectedUnit == 'cm') {
      final double cm = _convertFtInchToCm(_ftValue, _inchValue);
      _cmValue = cm.round();
      _heightController.text = '$_cmValue cm';
    } else if (selectedUnit == 'ft') {
      final ftInch = _convertCmToFtInch(_cmValue?.toDouble() ?? 0);
      _ftValue = ftInch['feet']!;
      _inchValue = ftInch['inches']!;
      _heightController.text = '$_ftValue\' $_inchValue"';
    }

    _checkForChanges();
  }

  void _updateWeight() {
    final String weightText =
        _weightController.text.trim().replaceAll('kg', '').trim();
    final int? weight = int.tryParse(weightText);

    if (weight != null && weight > 0) {
      setState(() {
        _weightValue = weight;
        _checkForChanges();
      });
    } else {
      if (kDebugMode) print('Invalid weight value.');
    }
  }

  void _checkForChanges() {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();

    final age = int.tryParse(ageText) ?? 0;
    final weight = _weightController.text.trim();
    final heightValid =
        selectedUnit == 'cm'
            ? (_cmValue != null && _cmValue! > 0)
            : (_ftValue > 0 || _inchValue > 0);

    final isValid =
        name.isNotEmpty && age > 0 && weight.isNotEmpty && heightValid;

    final isChanged =
        name != (initialName ?? '') ||
        ageText != (initialAge ?? '') ||
        isMale != initialIsMale ||
        heightText != (initialHeight ?? '') ||
        ('$weight kg' != (initialWeight ?? ''));

    setState(() {
      isSaveButtonEnabled = isValid && isChanged;
    });
  }

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

  void _saveProfile() async {
    final ClinicalPatientProfileApi profileInfo = ClinicalPatientProfileApi();
    String username = _nameController.text.trim();
    String genderToUpdate = isMale ? 'Male' : 'Female';
    final age = int.tryParse(_ageController.text) ?? 0;

    double heightInCm;
    if (selectedUnit == 'cm') {
      heightInCm = _cmValue?.toDouble() ?? 0.0;
    } else if (selectedUnit == 'ft') {
      heightInCm = _convertFtInchToCm(_ftValue, _inchValue);
    } else {
      setState(() {
        _heightController.text = 'Invalid height';
      });
      return;
    }

    final height = heightInCm.toInt();
    final weight =
        int.tryParse(
          _weightController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (kDebugMode) {
      print("User name: $username");
      print("Gender: $genderToUpdate");
      print("Age: $age");
      print("Height: $height");
      print("Weight: $weight");
    }

    final response = await profileInfo.clinicalProfileInfo(
      clinicalName: 'OFFC',
      profileName: username,
      age: age,
      gender: genderToUpdate,
      height: height,
      weight: weight,
    );
    if (kDebugMode) print("Successfully Profile Created");

    if (response['status'] == "success") {
      _showProfileCreationOption();
    } else {
      if (kDebugMode) print("Profile Creation as some error");
      throw Exception('Profile Creation as some error');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.primaryBlueColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return PopScope(
      canPop: !isSaveButtonEnabled, // Prevent pop if there are unsaved changes
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && isSaveButtonEnabled) {
          bool? discardChanges = await _showDiscardChanges();
          if (discardChanges == true) {
            Get.back();
          }
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Create Profile",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColor.primaryBlackColor,
            ),
          ),
          backgroundColor: AppColor.whiteColor,
          surfaceTintColor: AppColor.whiteColor,
        ),
        backgroundColor: AppColor.whiteColor,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  _buildContainer(
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SvgPicture.asset('assets/svg_icons/user.svg'),
                        ),
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Name',
                                style: GoogleFonts.mulish(
                                  color: AppColor.primaryBlueColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextFormField(
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  // Trim leading and trailing spaces before validation
                                  value = value?.trim();
                                  if (value == null || value.isEmpty) {
                                    return 'Name should not be empty';
                                  }
                                  if (value.length < 3) {
                                    return 'Name must be at least 3 characters long';
                                  }
                                  final RegExp nameExp = RegExp(
                                    r'^[a-zA-Z\s]+$',
                                  );
                                  if (!nameExp.hasMatch(value)) {
                                    return 'Name cannot contain numbers or special characters';
                                  }
                                  return null; // No error if validation passes
                                },
                                cursorColor: AppColor.primaryBlueColor,
                                controller: _nameController,
                                onChanged: (value) {
                                  setState(() {
                                    value = value.trimLeft();
                                    _nameController.value = TextEditingValue(
                                      text: value,
                                      selection: TextSelection.collapsed(
                                        offset: value.length,
                                      ),
                                    );

                                    // Revalidate dynamically
                                    if (value.isEmpty) {
                                      _usernameError =
                                          'Name should not be empty';
                                    } else if (value.length < 3) {
                                      _usernameError =
                                          'Name must be at least 3 characters long';
                                    } else if (!RegExp(
                                      r'^[a-zA-Z\s]+$',
                                    ).hasMatch(value)) {
                                      _usernameError =
                                          'Name cannot contain numbers or special characters';
                                    } else {
                                      _usernameError =
                                          null; // Remove error when valid
                                    }
                                    _checkForChanges();
                                  });
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  errorText:
                                      _usernameError?.isEmpty == true
                                          ? null
                                          : _usernameError,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  _buildContainer(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SvgPicture.asset('assets/gender_icon.svg'),
                        ),
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gender',
                                style: GoogleFonts.mulish(
                                  color: AppColor.primaryBlueColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.06,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE4F0FF),
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isMale = false;
                                            _checkForChanges();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                !isMale
                                                    ? AppColor.primaryBlackColor
                                                    : AppColor.whiteColor,
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/svg_icons/tick_icon.svg',
                                                colorFilter: ColorFilter.mode(
                                                  isMale
                                                      ? AppColor.whiteColor
                                                      : AppColor.whiteColor,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.02,
                                              ),
                                              Text(
                                                'Female',
                                                style: GoogleFonts.roboto(
                                                  color:
                                                      isMale
                                                          ? AppColor
                                                              .primaryBlackColor
                                                          : AppColor.whiteColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isMale = true;
                                            _checkForChanges();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isMale
                                                    ? AppColor.primaryBlackColor
                                                    : AppColor.whiteColor,
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/svg_icons/tick_icon.svg',
                                                colorFilter: ColorFilter.mode(
                                                  isMale
                                                      ? AppColor.whiteColor
                                                      : AppColor.whiteColor,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.02,
                                              ),
                                              Text(
                                                'Male',
                                                style: GoogleFonts.roboto(
                                                  color:
                                                      isMale
                                                          ? AppColor.whiteColor
                                                          : AppColor
                                                              .primaryBlackColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  _buildContainer(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SvgPicture.asset(
                            'assets/svg_icons/calender.svg',
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Age',
                                style: GoogleFonts.mulish(
                                  color: AppColor.primaryBlueColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextFormField(
                                controller: _ageController,
                                keyboardType:
                                    TextInputType
                                        .number, // Number-only keyboard
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Allow digits only
                                ],
                                validator: (value) {
                                  value = value?.trim();
                                  if (value == null || value.isEmpty) {
                                    return 'Age should not be empty';
                                  }
                                  final int? age = int.tryParse(value);
                                  if (age == null) {
                                    return 'Age must be a valid number';
                                  }
                                  if (age <= 0) {
                                    return 'Age must be greater than 0';
                                  }
                                  if (age > 110) {
                                    return 'Age must not exceed 110';
                                  }
                                  return null; // No error
                                },
                                onChanged: (value) {
                                  setState(() {
                                    value = value.trimLeft();
                                    _ageController.value = TextEditingValue(
                                      text: value,
                                      selection: TextSelection.collapsed(
                                        offset: value.length,
                                      ),
                                    );

                                    // Dynamic error handling
                                    if (value.isEmpty) {
                                      _ageError = 'Age should not be empty';
                                    } else {
                                      final int? age = int.tryParse(value);
                                      if (age == null) {
                                        _ageError =
                                            'Age must be a valid number';
                                      } else if (age <= 0) {
                                        _ageError =
                                            'Age must be greater than 0';
                                      } else if (age > 110) {
                                        _ageError = 'Age must not exceed 110';
                                      } else {
                                        _ageError = null;
                                      }
                                    }
                                    _checkForChanges();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your age",
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    color: const Color(0xFF737373),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  errorText:
                                      _ageError?.isEmpty == true
                                          ? null
                                          : _ageError,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'in years',
                            style: GoogleFonts.mulish(
                              color: AppColor.primaryBlackColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  _buildContainer(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SvgPicture.asset(
                            'assets/svg_icons/height_icon.svg',
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Height',
                                style: GoogleFonts.mulish(
                                  color: AppColor.primaryBlueColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextFormField(
                                controller: _heightController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: _showHeightPicker,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // cm Option
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'cm',
                                    activeColor: AppColor.primaryBlueColor,
                                    groupValue: selectedUnit,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedUnit = value;
                                        _updateHeight();
                                        _checkForChanges();
                                      });
                                    },
                                  ),
                                  const Text('cm'),
                                ],
                              ),
                              // ft Option
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'ft',
                                    activeColor: AppColor.primaryBlueColor,
                                    groupValue: selectedUnit,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedUnit = value;
                                        _updateHeight();
                                        _checkForChanges();
                                      });
                                    },
                                  ),
                                  const Text('Inches'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  _buildContainer(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SvgPicture.asset(
                            'assets/svg_icons/weight_icon.svg',
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Weight',
                                style: GoogleFonts.mulish(
                                  color: AppColor.primaryBlueColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextFormField(
                                controller: _weightController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: _showWeightPicker,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Kilograms (kg)',
                            style: GoogleFonts.mulish(
                              color: AppColor.primaryBlackColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.075,
                    child: ElevatedButton(
                      onPressed: isSaveButtonEnabled ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        backgroundColor: AppColor.primaryBlueColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Create Profile',
                        style: GoogleFonts.mulish(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColor.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileCreationOption() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.42,
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColor.whiteColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Would you like to Take test',
                style: GoogleFonts.mulish(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildConnectionOption(
                iconPath: 'assets/carbon_usb.svg',
                label: 'Cable',
                onTap: () {
                  Navigator.pop(context);
                  Get.offAll(
                    () => UsbDeviceConnectivity(
                      isClinicalTest: true,
                      profileDetails: widget.profileDetails,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'or',
                style: GoogleFonts.mulish(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.to(() => ClinicalProfileScreen());
                },
                child: Text(
                  "May be later",
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryBlackColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionOption({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.35,
        height: MediaQuery.of(context).size.height * 0.15,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(43),
              blurRadius: 9,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColor.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildContainer(Widget child) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColor.primaryBlueColor),
      ),
      child: child,
    );
  }

  void _showHeightPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      backgroundColor: AppColor.primaryBlueColor,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Do nothing on tapping outside the picker, keeping the current state.
          },
          child: HeightPicker(
            cmValue: _cmValue ?? 0,
            ftValue: _ftValue,
            inchValue: _inchValue,
            initialUnit: selectedUnit!,
            onCmChanged: (int cm) {
              setState(() {
                _cmValue = cm;
                _heightController.text = '$_cmValue cm';
              });

              _checkForChanges(); // Check for height change after it is updated
            },
            onFtInchChanged: (int ft, int inch) {
              setState(() {
                _ftValue = ft;
                _inchValue = inch;
                _heightController.text = '$_ftValue\' $_inchValue"';
              });

              _checkForChanges(); // Check for height change after it is updated
            },
            onDone: () {
              setState(() {
                _checkForChanges();
              });
            },
          ),
        );
      },
    );
  }

  void _showWeightPicker() {
    int tempWeightValue = _weightValue;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
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
                        // Apply changes only when "Done" is pressed
                        setState(() {
                          _weightValue = tempWeightValue;
                          _weightController.text = '$_weightValue kg';

                          _checkForChanges();
                        });
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
                  Text(
                    'Weight in kg',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: AppColor.primaryBlueColor,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  NumberPicker(
                    value: tempWeightValue,
                    minValue: 0,
                    maxValue: 300, // Adjust as needed
                    onChanged: (newValue) {
                      setModalState(() {
                        tempWeightValue = newValue;
                        _weightController.text = '$tempWeightValue kg';
                      });
                      _checkForChanges();
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
                        horizontal: BorderSide(
                          color: AppColor.primaryBlueColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Method to show a dialog box for primary profile deletion attempt
  Future<bool?> _showDiscardChanges() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allows closing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColor.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ), // Rounded corners for the dialog
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icons Row
                Image.asset('assets/warning_icon.png'),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                Text(
                  'Unsaved Changes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryBlackColor,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'You have unsaved changes. If you go back now, your changes will not be saved. Do you still want to go back?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColor.textLightColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                const Divider(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.045,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              AppColor.primaryBlackColor,
                            ),
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Colors.blue.withValues(
                                      alpha: 47,
                                    ); // Background color when pressed
                                  }
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.blue.withValues(
                                      alpha: 26,
                                    ); // Background color on hover
                                  }
                                  return null; // Default transparent
                                }),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primaryBlackColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.045,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pop(context);
                          },
                          style: ButtonStyle(
                            side: WidgetStateProperty.all(
                              const BorderSide(color: Color(0xFFDF2F32)),
                            ),
                            backgroundColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ), // Default background
                            foregroundColor: WidgetStateProperty.all(
                              AppColor.primaryBlackColor,
                            ), // Default text color
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Colors.red.withValues(
                                      alpha: 47,
                                    ); // Background color when pressed
                                  }
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.red.withValues(
                                      alpha: 26,
                                    ); // Background color on hover
                                  }
                                  return null; // Default transparent
                                }),
                          ),
                          child: Text(
                            'Discard Changes',
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: const Color(
                                0xFFEA5455,
                              ), // Logout button color
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
