// ... keep your imports
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
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
import '../helper/abort_device_manager.dart';
import '../widgets/check_abort_sheet.dart';
import '../../new_result/data/model/result_profile_data_model.dart';
import '../utils/user_region_manager.dart';
import '../widgets/account_creation_success.dart';
import '../widgets/connection_option_sheet.dart';
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

  // Height/weight are chosen from a wheel picker. The wheel starts at these
  // sensible defaults, but the bar shows a hint until the user actually picks a
  // value (tracked by the *Set flags).
  double heightValue = 170; // cm by default
  double weightValue = 70; // kg
  bool _heightSet = false;
  bool _weightSet = false;

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

  // Inline pickers that expand under the Height / Weight / Region bars.
  bool _heightPickerOpen = false;
  bool _weightPickerOpen = false;
  bool _regionPickerOpen = false;
  final GlobalKey _heightPickerKey = GlobalKey();
  final GlobalKey _weightPickerKey = GlobalKey();
  final GlobalKey _regionPickerKey = GlobalKey();

  final FocusNode bottomButtonFocusNode = FocusNode();

  // Collapsing title: the large "Subject details" header cross-fades into the
  // app bar as it scrolls under. Driven by a ValueNotifier so only the two
  // fading widgets rebuild on scroll — a full setState per scroll frame
  // rebuilds the whole form and janks the scroll.
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleT = ValueNotifier<double>(0);

  // Scroll offsets over which the hand-off happens. Below _fadeStart the title
  // lives entirely in the body; above _fadeEnd it lives entirely in the app bar.
  static const double _fadeStart = 12;
  static const double _fadeEnd = 52;

  // ✅ added (cooldown toast timer)
  Timer? _cooldownToastTimer;

  // ── Theme tokens (same palette, centralised for the refreshed UI) ──────────
  static const Color _fieldFill = Color(0xFFF9FCFF);
  static const Color _fieldBorder = Color(0xFFE4F0FF);
  static const Color _hintColor = Color(0xFF9AA0A6);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final double offset =
        _scrollController.hasClients ? _scrollController.offset : 0;
    _titleT.value = ((offset - _fadeStart) / (_fadeEnd - _fadeStart)).clamp(
      0.0,
      1.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleT.dispose();
    nameController.dispose();
    ageController.dispose();
    _cooldownToastTimer?.cancel(); // ✅ added
    super.dispose();
  }

  void selectGender(String gender) {
    selectedGender = gender;
    setState(() {});
  }

  void selectHeightType(String type) {
    if (type == selectedHeightType) return;
    setState(() {
      // Convert the current value so the slider position stays meaningful.
      if (type == 'feet' && selectedHeightType == 'cm') {
        heightValue = double.parse(
          (heightValue / 30.48).toStringAsFixed(1),
        ).clamp(3.0, 8.0);
      } else if (type == 'cm' && selectedHeightType == 'feet') {
        heightValue = (heightValue * 30.48).roundToDouble().clamp(100, 220);
      }
      selectedHeightType = type;
      heightError = false; // clear visual error when switching units
    });
  }

  InputDecoration getInputDecoration(
    String hintText,
    bool isError, {
    IconData? prefixIcon,
    String? suffixText,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.3),
      borderRadius: BorderRadius.circular(12),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: _hintColor),
      filled: true,
      fillColor: _fieldFill,
      prefixIcon:
          prefixIcon == null
              ? null
              : Icon(
                prefixIcon,
                size: 20,
                color: isError ? Colors.red : AppColor.primaryBlueColor,
              ),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColor.textLightColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(isError ? Colors.red : _fieldBorder),
      focusedBorder: border(isError ? Colors.red : AppColor.primaryBlueColor),
      errorStyle: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
      errorBorder: border(Colors.red),
      focusedErrorBorder: border(Colors.red),
    );
  }

  // ✅ added
  Future<int> getRemainingCooldownSeconds({int cooldownSeconds = 60}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_reading_time');
    if (last == null) return 0;

    final diff =
        DateTime.now()
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

    if (!formValid ||
        !regionSelected ||
        !genderSelected ||
        !_heightSet ||
        !_weightSet) {
      setState(() {
        nameError = nameController.text.trim().isEmpty;
        ageError = ageController.text.trim().isEmpty;
        regionError = !regionSelected;
        heightError = !_heightSet;
        weightError = !_weightSet;
      });
      // Form will show the inline validator messages thanks to autovalidateMode
      return;
    }

    setState(() => isLoading = true);

    try {
      final name = nameController.text.trim();
      final age = ageController.text.trim();

      final parsedAge = int.tryParse(age);
      if (parsedAge == null || parsedAge < 18 || parsedAge > 75) {
        showError("Age must be a number between 18 and 75.");
        setState(() {
          ageError = true;
          isLoading = false;
        });
        return;
      }

      // Height/weight come from sliders, so they're always within valid range.
      final double heightInCm =
          selectedHeightType == 'feet' ? heightValue * 30.48 : heightValue;

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
        weight: weightValue.toStringAsFixed(0),
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
        builder:
            (_) => BlocProvider(
              create: (_) => HealthScoreBloc(OverallDataByDateService()),
              child: ClinicalDashboardMain(loginId: widget.loginId),
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

            // Cool-down before another test: the sheet for an aborted one, a
            // message for a completed one.
            if (await AbortDeviceManager.getAbortStatus()) {
              _isNavigating = false;
              if (context.mounted) CheckAbortSheet.show(context: context);
              return;
            }

            final remaining =
                await AbortDeviceManager.completedRemainingSeconds();
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
                builder:
                    (_) => BluetoothClinicalDeviceConnectivity(
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
                builder:
                    (_) => UsbDeviceConnectivity(
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
        scrolledUnderElevation: 0,
        elevation: 0,
        title: ValueListenableBuilder<double>(
          valueListenable: _titleT,
          builder: (context, t, _) {
            return Opacity(
              opacity: t,
              // Slides up a few px as it fades in, so it reads as rising into
              // the bar rather than blinking on.
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 6),
                child: Text(
                  "Subject details",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryBlackColor,
                  ),
                ),
              ),
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F4FA)),
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
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Fades out in lock-step with the app bar title fading
                        // in, so the two titles cross-fade during the collapse.
                        ValueListenableBuilder<double>(
                          valueListenable: _titleT,
                          builder: (context, t, child) {
                            return Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: child,
                            );
                          },
                          child: _buildHeader(),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: nameController,
                          label: "Full name",
                          icon: Icons.person_outline_rounded,
                          hint: "Enter subject's full name",
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
                        const SizedBox(height: 18),
                        _buildTextField(
                          controller: ageController,
                          label: "Age",
                          icon: Icons.calendar_today_outlined,
                          hint: "Enter age",
                          suffixText: "yrs",
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
                        const SizedBox(height: 18),
                        _buildGenderSelector(),
                        const SizedBox(height: 18),
                        _buildHeightField(),
                        const SizedBox(height: 18),
                        _buildWeightField(),
                        const SizedBox(height: 18),
                        _buildRegionSelector(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Submit button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xFFF0F4FA), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: _buildBottomSubmitButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColor.primaryBlueColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColor.primaryBlueColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subject details",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.primaryBlackColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Fill in the details below to create a new profile.",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColor.textLightColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColor.primaryBlackColor,
        ),
      ),
    );
  }

  Widget _buildRegionSelector() {
    final String? label =
        selectedRegionKey == null || selectedRegionKey == "not_selected"
            ? null
            : getRegionLabelFromValue(selectedRegionKey);
    final bool hasValue = label != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Region"),
        _selectorBar(
          icon: Icons.location_on_outlined,
          valueText: hasValue ? label : "Select region",
          open: _regionPickerOpen,
          isError: regionError,
          isPlaceholder: !hasValue,
          onTap: _toggleRegionPicker,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              _regionPickerOpen
                  ? _inlineRegionPicker()
                  : const SizedBox(width: double.infinity),
        ),
        if (regionError && !_regionPickerOpen)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 6),
            child: Text(
              "Please select a region",
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _inlineRegionPicker() {
    final entries = UserRegionManager().regionMap.entries.toList();
    return Container(
      key: _regionPickerKey,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder, width: 1.3),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: entries.length,
        separatorBuilder:
            (_, __) => Divider(
              height: 1,
              color: _fieldBorder,
              indent: 14,
              endIndent: 14,
            ),
        itemBuilder: (ctx, i) {
          final entry = entries[i];
          final bool selected = entry.value == selectedRegionKey;
          return InkWell(
            onTap: () {
              setState(() {
                selectedRegionKey = entry.value;
                regionError = false;
                _regionPickerOpen = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            selected
                                ? AppColor.primaryBlueColor
                                : AppColor.primaryBlackColor,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColor.primaryBlueColor,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isError,
    required String? Function(String?)? validator,
    String? label,
    IconData? icon,
    String? suffixText,
    TextInputType inputType = TextInputType.text,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColor.primaryBlackColor,
          ),
          decoration: getInputDecoration(
            hint,
            isError,
            prefixIcon: icon,
            suffixText: suffixText,
          ),
          validator: validator,
          onChanged: (val) {
            if (onChanged != null) onChanged();
          },
        ),
      ],
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
        _fieldLabel("Gender"),
        Row(
          children: [
            _genderCard("Male", Icons.male_rounded),
            const SizedBox(width: 14),
            _genderCard("Female", Icons.female_rounded),
          ],
        ),
      ],
    );
  }

  Widget _genderCard(String gender, IconData icon) {
    final bool selected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => selectGender(gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColor.primaryBlueColor : _fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1.3,
              color: selected ? AppColor.primaryBlueColor : _fieldBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColor.textLightColor,
              ),
              const SizedBox(width: 8),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColor.primaryBlackColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // After a picker expands, scroll it into view so it isn't hidden below the
  // fold (waits for the expand animation to finish first).
  void _revealPicker(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _toggleHeightPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _heightPickerOpen = !_heightPickerOpen;
      if (_heightPickerOpen) {
        _weightPickerOpen = false;
        _regionPickerOpen = false;
      }
    });
    if (_heightPickerOpen) _revealPicker(_heightPickerKey);
  }

  void _toggleWeightPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _weightPickerOpen = !_weightPickerOpen;
      if (_weightPickerOpen) {
        _heightPickerOpen = false;
        _regionPickerOpen = false;
      }
    });
    if (_weightPickerOpen) _revealPicker(_weightPickerKey);
  }

  void _toggleRegionPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _regionPickerOpen = !_regionPickerOpen;
      if (_regionPickerOpen) {
        _heightPickerOpen = false;
        _weightPickerOpen = false;
      }
    });
    if (_regionPickerOpen) _revealPicker(_regionPickerKey);
  }

  Widget _inlineHeightPicker() {
    final bool isCm = selectedHeightType == 'cm';
    return Container(
      key: _heightPickerKey,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder, width: 1.3),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _unitPills(
              selected: selectedHeightType,
              onChanged: (u) => selectHeightType(u),
            ),
          ),
          const SizedBox(height: 4),
          isCm
              ? NumberPicker(
                value: heightValue.round().clamp(100, 220).toInt(),
                minValue: 100,
                maxValue: 220,
                itemCount: 3,
                itemHeight: 44,
                textMapper: (v) => "$v cm",
                selectedTextStyle: _pickerSelectedStyle,
                textStyle: _pickerUnselectedStyle,
                decoration: _pickerHighlightDecoration,
                onChanged:
                    (v) => setState(() {
                      heightValue = v.toDouble();
                      _heightSet = true;
                      heightError = false;
                    }),
              )
              : DecimalNumberPicker(
                value: heightValue.clamp(3.0, 8.0).toDouble(),
                minValue: 3,
                maxValue: 8,
                decimalPlaces: 1,
                itemCount: 3,
                itemHeight: 44,
                selectedTextStyle: _pickerSelectedStyle,
                textStyle: _pickerUnselectedStyle,
                integerDecoration: _pickerHighlightDecoration,
                decimalDecoration: _pickerHighlightDecoration,
                onChanged:
                    (v) => setState(() {
                      heightValue = v;
                      _heightSet = true;
                      heightError = false;
                    }),
              ),
        ],
      ),
    );
  }

  Widget _inlineWeightPicker() {
    return Container(
      key: _weightPickerKey,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder, width: 1.3),
      ),
      // Wrap in a Column (like the Height card) so the wheel keeps its natural
      // centered width instead of stretching full-width — that way only the
      // centre captures the scroll and the sides scroll the screen.
      child: Column(
        children: [
          NumberPicker(
            value: weightValue.round().clamp(30, 200).toInt(),
            minValue: 30,
            maxValue: 200,
            itemCount: 3,
            itemHeight: 44,
            textMapper: (v) => "$v kg",
            selectedTextStyle: _pickerSelectedStyle,
            textStyle: _pickerUnselectedStyle,
            decoration: _pickerHighlightDecoration,
            onChanged:
                (v) => setState(() {
                  weightValue = v.toDouble();
                  _weightSet = true;
                  weightError = false;
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightField() {
    final bool isCm = selectedHeightType == 'cm';
    final String valueText =
        !_heightSet
            ? "Enter height"
            : isCm
            ? "${heightValue.round()} cm"
            : "${heightValue.toStringAsFixed(1)} ft";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Height"),
        _selectorBar(
          icon: Icons.height_rounded,
          valueText: valueText,
          open: _heightPickerOpen,
          onTap: _toggleHeightPicker,
          isError: heightError,
          isPlaceholder: !_heightSet,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              _heightPickerOpen
                  ? _inlineHeightPicker()
                  : const SizedBox(width: double.infinity),
        ),
        if (heightError && !_heightPickerOpen)
          _fieldError("Please select height"),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Weight"),
        _selectorBar(
          icon: Icons.monitor_weight_outlined,
          valueText: !_weightSet ? "Enter weight" : "${weightValue.round()} kg",
          open: _weightPickerOpen,
          onTap: _toggleWeightPicker,
          isError: weightError,
          isPlaceholder: !_weightSet,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              _weightPickerOpen
                  ? _inlineWeightPicker()
                  : const SizedBox(width: double.infinity),
        ),
        if (weightError && !_weightPickerOpen)
          _fieldError("Please select weight"),
      ],
    );
  }

  Widget _fieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 6),
      child: Text(
        message,
        style: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
      ),
    );
  }

  Widget _selectorBar({
    required IconData icon,
    required String valueText,
    required bool open,
    required VoidCallback onTap,
    bool isError = false,
    bool isPlaceholder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1.3,
            color:
                isError
                    ? Colors.red
                    : (open ? AppColor.primaryBlueColor : _fieldBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isError ? Colors.red : AppColor.primaryBlueColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                valueText,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isPlaceholder ? _hintColor : AppColor.primaryBlackColor,
                ),
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColor.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitPills({
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fieldBorder, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            ["cm", "feet"].map((unit) {
              final bool sel = selected == unit;
              return GestureDetector(
                onTap: () => onChanged(unit),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColor.primaryBlueColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: sel ? Colors.white : AppColor.textLightColor,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  TextStyle get _pickerSelectedStyle => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColor.primaryBlueColor,
  );

  TextStyle get _pickerUnselectedStyle =>
      GoogleFonts.poppins(fontSize: 15, color: const Color(0xFFB0B7C3));

  BoxDecoration get _pickerHighlightDecoration => BoxDecoration(
    border: Border.symmetric(
      horizontal: BorderSide(
        color: AppColor.primaryBlueColor.withValues(alpha: 0.35),
        width: 1.3,
      ),
    ),
  );

  Widget _buildBottomSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        focusNode: bottomButtonFocusNode,
        onPressed: isLoading ? null : () => handleSubmit(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryBlueColor,
          disabledBackgroundColor: AppColor.primaryBlueColor.withValues(
            alpha: 0.6,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  "Continue",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,

                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
