import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/urls.dart';

import '../../../../clinical_dashboard/utils/user_region_manager.dart';
import '../../../../common/floating_message.dart';
import '../../../../router/app_routers.dart';
import '../../../../shared/colors.dart';
import '../bloc/corporate_signup_bloc.dart';
import '../bloc/corporate_signup_event.dart';
import '../bloc/corporate_signup_state.dart';
import '../data/repository/corporate_signup_repository.dart';

class CorporateSignUp extends StatelessWidget {
  final String clinicName;
  const CorporateSignUp({super.key, required this.clinicName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = CorporateSignUpBloc(
          repo: CorporateSignUpRepository(
            endpointUrl: Urls.insertCorporateProfile,
          ),
        );
        bloc.add(const CorporateGenderChanged("Male"));
        bloc.add(CorporateClinicNameChanged(clinicName));
        return bloc;
      },
      child: const _CorporateSignUpView(),
    );
  }
}

class _CorporateSignUpView extends StatefulWidget {
  const _CorporateSignUpView();

  @override
  State<_CorporateSignUpView> createState() => _CorporateSignUpViewState();
}

class _CorporateSignUpViewState extends State<_CorporateSignUpView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _regionController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  String? _emailServerError;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _regionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ Re-run validators so error text clears immediately while editing
  void _revalidate() {
    _formKey.currentState?.validate();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Email address is required";
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(v)) return "Invalid email format";
    return null;
  }

  String? _validateName(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Please enter your name";
    return null;
  }

  String? _validateHeight(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Required";
    final h = int.tryParse(v);
    if (h == null || h < 50 || h > 250) return "50-250";
    return null;
  }

  String? _validateWeight(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Required";
    final w = double.tryParse(v);
    if (w == null || w < 20 || w > 300) return "20-300";
    return null;
  }

  String? _validateAge(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Required";
    final a = int.tryParse(v);
    if (a == null || a < 18 || a > 100) return "18-100";
    return null;
  }

  String? _validateRegion(String? value) {
    if ((value ?? "").trim().isEmpty) return "Please select a region";
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Password is required";
    if (v.length < 6) return "Minimum 6 characters";
    return null;
  }

  InputDecoration _inputDecoration(
    String hint, {
    String? suffixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: const Color(0xFF737373),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      suffixStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF809BF9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _openRegionBottomSheet() async {
    final manager = UserRegionManager();
    final regionLabels = manager.regionMap.keys.toList();

    final selectedLabel = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (_, controller) => Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: regionLabels.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              regionLabels[index],
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            onTap:
                                () =>
                                    Navigator.pop(context, regionLabels[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );

    if (selectedLabel != null) {
      final actualValue = manager.regionMap[selectedLabel]!;
      _regionController.text = selectedLabel;

      if (!mounted) return;
      context.read<CorporateSignUpBloc>().add(
        CorporateRegionChanged(actualValue),
      );

      // ✅ immediate clear error
      _revalidate();
    }
  }

  bool _allFilled(CorporateSignUpState s) {
    return s.email.isNotEmpty &&
        s.name.isNotEmpty &&
        s.heightCm.isNotEmpty &&
        s.weightKg.isNotEmpty &&
        s.age.isNotEmpty &&
        s.region.isNotEmpty &&
        s.password.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CorporateSignUpBloc, CorporateSignUpState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == CorporateSignUpStatus.failure) {
          final msg = (state.errorMessage ?? "").trim();

          if (msg == 'Signup failed: 409') {
            setState(() => _emailServerError = "Email already exists");
            FloatingMessage.show(
              context,
              message: "Email already exists",
              type: FloatingMessageType.error,
            );
            _revalidate(); // ✅ show immediately
            return;
          }

          FloatingMessage.show(
            context,
            message: state.errorMessage ?? "Failure",
            type: FloatingMessageType.error,
          );
        }

        if (state.status == CorporateSignUpStatus.success) {
          setState(() => _emailServerError = null);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.accountCreationSuccess,
            );
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: SvgPicture.asset("assets/respyr_logo.svg"),
        ),
        body: SafeArea(
          child: BlocBuilder<CorporateSignUpBloc, CorporateSignUpState>(
            builder: (context, state) {
              final isLoading = state.status == CorporateSignUpStatus.loading;

              return AbsorbPointer(
                absorbing: isLoading,
                child: Form(
                  key: _formKey,
                  // ✅ key change: auto revalidate after user interacts
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sign up",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 34,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -2.04,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // EMAIL
                        TextFormField(
                          enabled: !isLoading,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final local = _validateEmail(v);
                            if (local != null) return local;
                            return _emailServerError;
                          },
                          onChanged: (v) {
                            // ✅ clear server error immediately when user edits
                            if (_emailServerError != null) {
                              setState(() => _emailServerError = null);
                            }
                            context.read<CorporateSignUpBloc>().add(
                              CorporateEmailChanged(v),
                            );
                            _revalidate();
                          },
                          decoration: _inputDecoration("Email address"),
                        ),

                        const SizedBox(height: 16),

                        // NAME
                        TextFormField(
                          enabled: !isLoading,
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                          onChanged: (v) {
                            context.read<CorporateSignUpBloc>().add(
                              CorporateNameChanged(v),
                            );
                            _revalidate();
                          },
                          decoration: _inputDecoration("Full name"),
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD
                        TextFormField(
                          enabled: !isLoading,
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          validator: _validatePassword,
                          onChanged: (v) {
                            context.read<CorporateSignUpBloc>().add(
                              CorporatePasswordChanged(v),
                            );
                            _revalidate();
                          },
                          decoration: _inputDecoration(
                            "Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Select gender",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _GenderButton(
                              label: "Male",
                              icon: Icons.male,
                              isSelected: state.gender == "Male",
                              isDisabled: isLoading,
                              onTap:
                                  () => context.read<CorporateSignUpBloc>().add(
                                    const CorporateGenderChanged("Male"),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            _GenderButton(
                              label: "Female",
                              icon: Icons.female,
                              isSelected: state.gender == "Female",
                              isDisabled: isLoading,
                              onTap:
                                  () => context.read<CorporateSignUpBloc>().add(
                                    const CorporateGenderChanged("Female"),
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                enabled: !isLoading,
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                validator: _validateHeight,
                                onChanged: (v) {
                                  context.read<CorporateSignUpBloc>().add(
                                    CorporateHeightChanged(v),
                                  );
                                  _revalidate();
                                },
                                decoration: _inputDecoration(
                                  "Height",
                                  suffixText: "cm",
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                enabled: !isLoading,
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validateWeight,
                                onChanged: (v) {
                                  context.read<CorporateSignUpBloc>().add(
                                    CorporateWeightChanged(v),
                                  );
                                  _revalidate();
                                },
                                decoration: _inputDecoration(
                                  "Weight",
                                  suffixText: "kg",
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          enabled: !isLoading,
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          validator: _validateAge,
                          onChanged: (v) {
                            context.read<CorporateSignUpBloc>().add(
                              CorporateAgeChanged(v),
                            );
                            _revalidate();
                          },
                          decoration: _inputDecoration("Age"),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          enabled: !isLoading,
                          controller: _regionController,
                          readOnly: true,
                          onTap: isLoading ? null : _openRegionBottomSheet,
                          validator: _validateRegion,
                          decoration: _inputDecoration(
                            "Select region",
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: BlocBuilder<CorporateSignUpBloc, CorporateSignUpState>(
        builder: (context, state) {
          final isLoading = state.status == CorporateSignUpStatus.loading;
          final canTap = _allFilled(state) && !isLoading;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                const Spacer(),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed:
                        canTap
                            ? () {
                              if (_formKey.currentState!.validate()) {
                                context.read<CorporateSignUpBloc>().add(
                                  const CorporateSignUpSubmitted(),
                                );
                              }
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryBlueColor,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
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
                              "Create Account",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColor.primaryBlueColor
                    : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? AppColor.primaryBlueColor
                      : const Color(0xFFF0F0F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF535359),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF535359),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
