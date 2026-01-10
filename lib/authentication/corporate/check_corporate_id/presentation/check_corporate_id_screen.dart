import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
          "https://humorstech.com/humors_app/app_final/clinical/check_corporate_id.php",
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
      hintStyle: GoogleFonts.roboto(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: const Color(0xFF737373),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),

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

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocBuilder<ClinicNameCheckBloc, ClinicNameCheckState>(
      builder: (context, state) {
        String? helperText;
        Color? helperColor;

        if (state.status == ClinicNameCheckStatus.loading) {
          helperText = "Checking corporate id...";
          helperColor = Colors.grey;
        } else if (state.status == ClinicNameCheckStatus.success) {
          if (state.exists == true) {
            helperText = "Corporate ID found. You can continue.";
            helperColor = Colors.green;
          } else {
            helperText = "Corporate ID not found.";
            helperColor = Colors.red;
          }
        } else if (state.status == ClinicNameCheckStatus.failure) {
          helperText = state.message ?? "Something went wrong";
          helperColor = Colors.red;
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
            title: SvgPicture.asset("assets/respyr_logo.svg"),
          ),
          body: SafeArea(
            child: Padding(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_left_outlined),
                  ),
                  IconButton(
                    onPressed: canContinue
                        ? () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.corporateSignUp,
                        arguments: {"clinic_name": state.clinicName},
                      );
                    }
                        : null,
                    style: IconButton.styleFrom(
                      // ✅ enabled blue, disabled grey (NOT red)
                      backgroundColor: canContinue
                          ? AppColor.primaryBlueColor
                          : Colors.grey,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_right_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
