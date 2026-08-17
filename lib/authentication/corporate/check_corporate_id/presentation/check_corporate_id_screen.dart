import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/urls.dart';

import '../../../../router/app_routers.dart';
import '../../../../shared/colors.dart';
import '../bloc/clinic_name_check_bloc.dart';
import '../bloc/clinic_name_check_event.dart';
import '../bloc/clinic_name_check_state.dart';
import '../data/repository/clinic_name_check_repository.dart';

class CheckCorporateIdScreen extends StatelessWidget {
  const CheckCorporateIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClinicNameCheckBloc(
        repo: ClinicNameCheckRepository(
          endpointUrl:
          Urls.checkCorporateId,
        ),
      ),
      child: const _CheckCorporateIdView(),
    );
  }
}

class _CheckCorporateIdView extends StatefulWidget {
  const _CheckCorporateIdView();

  @override
  State<_CheckCorporateIdView> createState() => _CheckCorporateIdViewState();
}

class _CheckCorporateIdViewState extends State<_CheckCorporateIdView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
      String hint, {
        String? helperText,
        Color? helperColor,
        Widget? suffixIcon,
      }) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFA1A1A1),
      ),
      filled: true,
      fillColor: Colors.white,

      // ✅ show status message
      helperText: helperText,
      helperStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: helperColor ?? Colors.grey,
      ),

      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF308BF9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEA5455), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEA5455), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocBuilder<ClinicNameCheckBloc, ClinicNameCheckState>(
      builder: (context, state) {
        String? helperText;
        Color? helperColor;

        if (state.status == ClinicNameCheckStatus.loading) {
          helperText = "Checking corporate id...";
          helperColor = const Color(0xFFA1A1A1);
        } else if (state.status == ClinicNameCheckStatus.success) {
          if (state.exists == true) {
            helperText = "Corporate ID found. You can continue.";
            helperColor = const Color(0xFF3EAF58);
          } else {
            helperText = "Corporate ID not found.";
            helperColor = const Color(0xFFEA5455);
          }
        } else if (state.status == ClinicNameCheckStatus.failure) {
          helperText = state.message ?? "Something went wrong";
          helperColor = const Color(0xFFEA5455);
        }

        // ✅ safe check (exists can be null)
        final bool canContinue = state.exists == true;

        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF252525),
              ),
            ),
            centerTitle: true,
            title: SvgPicture.asset("assets/respyr_logo.svg"),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Sign up",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enter the corporate ID your organisation gave you.",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF535359),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    onChanged: (v) {
                      context
                          .read<ClinicNameCheckBloc>()
                          .add(ClinicNameChanged(v));
                    },
                    decoration: _inputDecoration(
                      "Enter corporate id",
                      helperText: helperText,
                      helperColor: helperColor,
                      suffixIcon: state.status == ClinicNameCheckStatus.loading
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 12 + keyboardInset,
            ),
            child: SafeArea(
              top: false,
              // A labelled full-width button (back lives in the app bar now).
              // Enabled only once the ID checks out, matching the login
              // screen's primary action.
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.corporateSignUp,
                            arguments: {"clinic_name": state.clinicName},
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColor.primaryBlueColor,
                    disabledBackgroundColor:
                        const Color(0xFF308BF9).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
