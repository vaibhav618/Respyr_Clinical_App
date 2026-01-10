// ... keep your imports
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_device_connectivity.dart';
import 'package:respyr_clinical/clinical_dashboard/bloc/health_score_bloc.dart';
import 'package:respyr_clinical/clinical_dashboard/service/overall_data_by_date_service.dart';
import 'package:respyr_clinical/clinical_dashboard/views/clinical_dashboard.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/device_connectivity/presentation/pages/device_connectivity_screen.dart';
import 'package:respyr_clinical/shared/colors.dart';

import 'dart:async'; // ✅ added
import 'package:shared_preferences/shared_preferences.dart'; // ✅ added

import '../../common/floating_message.dart';
import '../../log_manager/log_manager.dart';
import '../../new_result/data/model/result_profile_data_model.dart';
import '../utils/user_region_manager.dart';
import '../widgets/account_creation_success.dart';
import '../widgets/connection_option_sheet.dart';
import '../widgets/region_selector.dart';
import 'create_profile_service.dart';



class CreateProfile extends StatefulWidget {
  final String loginId;
  const CreateProfile({super.key, required this.loginId});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  bool nameError = false;
  bool ageError = false;
  bool heightError = false;
  bool weightError = false;
  bool regionError = false;
  bool isLoading = false;

  String? jwtTokenError;
  String? errorProfileCreation;

  String? selectedGender = 'Male';
  String selectedHeightType = 'cm';
  String? selectedRegionKey = "not_selected";

  bool isTakeTestWindowOpen = false;
  bool _hasInternet = true;
  bool _isNavigating = false;

  final FocusNode bottomButtonFocusNode = FocusNode();

  // ✅ added (cooldown toast timer)
  Timer? _cooldownToastTimer;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    _cooldownToastTimer?.cancel(); // ✅ added
    super.dispose();
  }

  void selectGender(String gender) {
    selectedGender = gender;
    setState(() {});
  }

  void selectHeightType(String type) {
    selectedHeightType = type;
    setState(() {
      heightError = false; // clear visual error when switching units
      selectedHeightType = type;
    });
  }

  InputDecoration getInputDecoration(String hintText, bool isError) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF252525),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isError ? Colors.red : const Color(0xFFE4F0FF),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isError ? Colors.red : const Color(0xFF308BF9),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ✅ added
  Future<int> getRemainingCooldownSeconds({int cooldownSeconds = 40}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_reading_time');
    if (last == null) return 0;

    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(last))
        .inSeconds;

    final remaining = cooldownSeconds - diff;
    return remaining > 0 ? remaining : 0;
  }

  // ✅ added
  Future<void> showCooldownToast(int seconds) async {
    _cooldownToastTimer?.cancel();

    int remaining = seconds;

    if (!mounted) return;
    FloatingMessage.show(
      context,
      message: 'Please wait $remaining seconds before next test',
      type: FloatingMessageType.warning,
      duration: Duration(seconds: remaining + 1),
      fromTop: false,
    );

    _cooldownToastTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      remaining--;

      if (remaining <= 0) {
        t.cancel();
        FloatingMessage.hide();
        return;
      }

      FloatingMessage.update(
        'Please wait $remaining seconds before next test',
        duration: Duration(seconds: remaining + 1),
      );
    });
  }

  Future<void> handleSubmit() async {
    // First validate the form fields
    final formValid = _formKey.currentState?.validate() ?? false;

    final regionSelected =
        selectedRegionKey != null && selectedRegionKey != "not_selected";
    final genderSelected =
        selectedGender != null && selectedGender != 'not_selected';

    if (!formValid || !regionSelected || !genderSelected) {
      setState(() {
        nameError = nameController.text.trim().isEmpty;
        ageError = ageController.text.trim().isEmpty;
        heightError = heightController.text.trim().isEmpty;
        weightError = weightController.text.trim().isEmpty;
        regionError = !regionSelected;
      });
      // Form will show the inline validator messages thanks to autovalidateMode
      return;
    }

    setState(() => isLoading = true);

    try {
      final name = nameController.text.trim();
      final age = ageController.text.trim();
      final height = heightController.text.trim();
      final weight = weightController.text.trim();

      final parsedAge = int.tryParse(age);
      if (parsedAge == null || parsedAge < 18 || parsedAge > 75) {
        showError("Age must be a number between 18 and 75.");
        setState(() {
          ageError = true;
          isLoading = false;
        });
        return;
      }

      final rawHeight = double.tryParse(height);
      if (rawHeight == null) {
        showError("Invalid height format.");
        setState(() => isLoading = false);
        return;
      }

      bool isHeightValid = true;
      if (selectedHeightType == 'cm') {
        if (rawHeight < 43.18 || rawHeight > 304.8) isHeightValid = false;
      } else {
        if (rawHeight < 1.5 || rawHeight > 10.0) isHeightValid = false;
      }

      if (!isHeightValid) {
        showError("Height must be between 43.18-304.8 cm or 1.5-10.0 feet.");
        setState(() {
          heightError = true;
          isLoading = false;
        });
        return;
      }
      final heightInCm =
      selectedHeightType == 'feet' ? rawHeight * 30.48 : rawHeight;

      final rawWeight = double.tryParse(weight);
      if (rawWeight == null) {
        showError("Invalid weight format.");
        setState(() {
          weightError = true;
          isLoading = false;
        });
        return;
      }
      if (rawWeight < 30 || rawWeight > 200) {
        showError("Weight must be between 30-200 kg.");
        setState(() {
          weightError = true;
          isLoading = false;
        });
        return;
      }

      LogManager().logEvent(
        event: 'CREATE_PROFILE_ATTEMPT',
        status: 'ATTEMPT',
        details:
        'User attempting to create profile: $name, gender: $selectedGender, region: $selectedRegionKey',
      );

      final createProfileService = CreateProfileService();
      final result = await createProfileService.createProfile(
        clinicName: widget.loginId,
        profileName: name,
        gender: selectedGender!,
        age: age,
        height: heightInCm.toStringAsFixed(2),
        weight: weight,
        region: selectedRegionKey!,
        phone: "NA",
        email: "NA",
      );

      final statusCode = result['status_code'];
      final body = result['body'];

      if (statusCode == 200 && body['status'] == 'success') {
        final response = CreateProfileResponse.fromJson(body);

        final profileDetails = ResultProfileDataModel(
          subjectId: response.data.subjectId,
          clinicName: response.data.clinicName,
          profileName: response.data.profileName,
          gender: response.data.gender,
          age: response.data.age,
          height: response.data.height,
          weight: response.data.weight,
          region: selectedRegionKey!,
          dttm: response.data.dttm,
        );

        if (mounted) {
          AccountCreationSuccess().showMessage(
            context,
            onContinue: () {
              if (!isTakeTestWindowOpen) {
                _showConnectionOption(profileDetails, context);
              }
            },
            onClosed: () {
              _navigateToDashboard();
            },
          );
        }
      } else {
        final message =
            body['message']?.toString() ?? "Failed to create profile.";

        if (message.toLowerCase().contains("profile name already exists")) {
          setState(() {
            nameError = true;
          });
        }

        showError(message);
      }
    } catch (e) {
      showError("Something went wrong. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => HealthScoreBloc(OverallDataByDateService()),
          child: ClinicalDashboardMain(
            loginId: widget.loginId,
          ),
        ),
      ),
          (route) => false,
    );
  }

  void _showConnectionOption(
      ResultProfileDataModel profileModel,
      BuildContext context,
      ) {
    // ... your bottom sheet code (unchanged)
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConnectionOptionSheet(
          onBluetoothTap: () async {
            isTakeTestWindowOpen = true;
            _isNavigating = true;

            // ✅ added: cooldown check before navigating
            final remaining =
            await getRemainingCooldownSeconds(cooldownSeconds: 40);
            if (remaining > 0) {
              _isNavigating = false;
              await showCooldownToast(remaining);
              return;
            }

            // Navigator.pop(context); // Close the bottom sheet

            await Future.delayed(const Duration(milliseconds: 200));
            _isNavigating = false;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => BluetoothClinicalDeviceConnectivity(
                  // isClinicalTest: true,
                  profileDetails: profileModel,
                ),
              ),
                  (route) => false,
            );
          },
          onUsbTap: () {
            Navigator.pop(context);
            isTakeTestWindowOpen = true;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => UsbDeviceConnectivity(
                  isClinicalTest: true,
                  profileDetails: profileModel,
                ),
              ),
                  (route) => false,
            );
          },
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (jwtTokenError != null) {
      return Scaffold(backgroundColor: Colors.white);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        title: Text(
          "Create new subject",
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: InternetConnectivityHandler(
        isBody: true,
        onConnectivityChanged: (hasInternet) {
          if (_isNavigating) return;
          setState(() {
            _hasInternet = hasInternet;
            _navigateToDashboard();
          });
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: nameController,
                          hint: "Enter your full name *",
                          isError: nameError,
                          validator: (value) {
                            value = value?.trim();
                            if (value == null || value.isEmpty) {
                              return 'Name should not be empty';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters long';
                            }
                            final regex = RegExp(r'^[a-zA-Z0-9\s\-/&]+$');
                            if (!regex.hasMatch(value)) {
                              return 'Only letters, numbers, spaces, -, /, and & are allowed';
                            }
                            return null;
                          },
                          onChanged: () {
                            if (nameError) setState(() => nameError = false);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: ageController,
                          hint: "Enter your age *",
                          isError: ageError,
                          inputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Age is required';
                            }
                            final age = int.tryParse(value.trim());
                            if (age == null) {
                              return 'Enter a valid number for age';
                            }
                            if (age < 18 || age > 75) {
                              return 'Age must be between 18 and 75';
                            }
                            return null;
                          },
                          onChanged: () {
                            if (ageError) setState(() => ageError = false);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildGenderSelector(),
                        const SizedBox(height: 20),
                        _buildHeightField(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: weightController,
                          hint: "Enter your weight (Kg) *",
                          isError: weightError,
                          inputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Weight is required';
                            }
                            final weight = double.tryParse(value.trim());
                            if (weight == null) {
                              return 'Enter a valid number for weight';
                            }
                            if (weight < 30 || weight > 200) {
                              return 'Weight must be between 30 kg and 200 kg';
                            }
                            return null;
                          },
                          onChanged: () {
                            if (weightError) {
                              setState(() => weightError = false);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildRegionSelector(
                          isError: regionError,
                          selectedRegionKey: selectedRegionKey,
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            final result =
                            await RegionSelector.showRegionPicker(
                              context,
                              selectedRegionKey,
                            );
                            if (result != null) {
                              setState(() {
                                selectedRegionKey = result;
                                regionError = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Submit button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildBottomSubmitButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionSelector({
    required bool isError,
    required String? selectedRegionKey,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: isError ? Colors.red : const Color(0xFFF0F0F0),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
            ),
            onPressed: onPressed,
            child: Text(
              selectedRegionKey == null
                  ? "Select Region *"
                  : getRegionLabelFromValue(selectedRegionKey) ??
                  "Select Region *",
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 6),
            child: Text(
              "Please select a region",
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isError,
    required String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.poppins(fontSize: 12),
      decoration: getInputDecoration(hint, isError),
      validator: validator,
      onChanged: (val) {
        if (onChanged != null) onChanged();
      },
    );
  }

  static String? getRegionLabelFromValue(String? value) {
    final match = UserRegionManager().regionMap.entries.firstWhere(
          (entry) => entry.value == value,
      orElse: () => const MapEntry('', ''),
    );
    return match.key.isNotEmpty ? match.key : null;
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select your gender", style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          children: ["Male", "Female"].map((gender) {
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: ElevatedButton(
                onPressed: () => selectGender(gender),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedGender == gender
                      ? const Color(0xFF252525)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF252525)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 0,
                ),
                child: Text(
                  gender,
                  style: GoogleFonts.poppins(
                    color: selectedGender == gender
                        ? Colors.white
                        : const Color(0xFF252525),
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeightField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(fontSize: 12),
            decoration: getInputDecoration(
              "Enter your height *",
              heightError,
            ).copyWith(errorMaxLines: 3),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Height is required';
              }
              final h = double.tryParse(value.trim());
              if (h == null) {
                return 'Enter a valid number for height';
              }
              if (selectedHeightType == 'cm') {
                if (h < 43.18 || h > 304.8) {
                  return 'Height must be between 43.18 cm and 304.8 cm';
                }
              } else {
                if (h < 1.5 || h > 10.0) {
                  return 'Height must be between 1.5 and 10.0 feet';
                }
              }
              return null;
            },
            onChanged: (_) {
              if (heightError) setState(() => heightError = false);
            },
          ),
        ),
        const SizedBox(width: 20),
        ...["cm", "feet"]
            .map(
              (unit) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton(
              onPressed: () => selectHeightType(unit),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedHeightType == unit
                    ? const Color(0xFF252525)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF252525)),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                unit,
                style: GoogleFonts.poppins(
                  color: selectedHeightType == unit
                      ? Colors.white
                      : const Color(0xFF252525),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        )
            .toList(),
      ],
    );
  }

  Widget _buildBottomSubmitButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          focusNode: bottomButtonFocusNode,
          onPressed: isLoading ? null : () => handleSubmit(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF308BF9),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2000),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
          ),
          child: isLoading
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            "Continue",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
