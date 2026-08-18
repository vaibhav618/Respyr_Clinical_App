import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/sign_in_state.dart';

/// One role choice as a proper CTA: a full-width labelled button — filled
/// primary for Clinical, outlined secondary for Corporate. The label swaps
/// for a spinner on the button that was pressed while both stay locked.
class SignInOptionButton extends StatelessWidget {
  final SignInState state;
  final String title;
  final bool filled;
  final VoidCallback onClick;

  /// The bloc's role key this button submits ("clinical"/"corporate") —
  /// needed to match the loading spinner now that labels are free-form.
  final String roleKey;

  const SignInOptionButton({
    super.key,
    required this.state,
    required this.title,
    required this.onClick,
    required this.roleKey,
    this.filled = false,
  });

  static const Color _blue = Color(0xFF308BF9);

  @override
  Widget build(BuildContext context) {
    final bool isLoading = state.status == SignInStatus.loading;
    final bool isThisLoading = isLoading && state.selectedType == roleKey;

    final Widget label =
        isThisLoading
            ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: filled ? Colors.white : _blue,
              ),
            )
            : Text(
              title,
              style: GoogleFonts.poppins(
                color: filled ? Colors.white : _blue,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            );

    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child:
          filled
              ? ElevatedButton(
                onPressed: isLoading ? null : onClick,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _blue,
                  disabledBackgroundColor: _blue.withValues(alpha: 0.5),
                  shape: shape,
                ),
                child: label,
              )
              : OutlinedButton(
                onPressed: isLoading ? null : onClick,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color:
                        isLoading && !isThisLoading
                            ? _blue.withValues(alpha: 0.5)
                            : _blue,
                    width: 1.4,
                  ),
                  shape: shape,
                ),
                child: label,
              ),
    );
  }
}
