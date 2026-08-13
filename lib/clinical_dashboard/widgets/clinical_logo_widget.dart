import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';

class ClinicLogoWidget extends StatelessWidget {
  final String clinicName;
  final double size;

  /// Draws a white ring and a soft shadow around the avatar. On for the app
  /// bar, where the badge needs to separate from the surface behind it.
  final bool elevated;

  const ClinicLogoWidget({
    super.key,
    required this.clinicName,
    this.size = 34,
    this.elevated = false,
  });

  /// One fetch per clinic per app session. Creating the future inside build()
  /// re-downloaded the logo on EVERY rebuild (and blanked the icon while
  /// waiting), which made the app-bar icon blink on unrelated setStates.
  static final Map<String, Future<Uint8List?>> _logoCache = {};

  Color _getColor(String letter) {
    const colorMap = {
      'A': Color(0xFFFF6B6B), 'B': Color(0xFF6BCB77), 'C': Color(0xFF4D96FF),
      'D': Color(0xFFFFB74D), 'E': Color(0xFF9575CD), 'F': Color(0xFF26A69A),
      'G': Color(0xFFFF7043), 'H': Color(0xFF42A5F5), 'I': Color(0xFF66BB6A),
      'J': Color(0xFFFFCA28), 'K': Color(0xFFAB47BC), 'L': Color(0xFF26C6DA),
      'M': Color(0xFFEC407A), 'N': Color(0xFF8D6E63), 'O': Color(0xFF5C6BC0),
      'P': Color(0xFF9CCC65), 'Q': Color(0xFF29B6F6), 'R': Color(0xFFF06292),
      'S': Color(0xFF7986CB), 'T': Color(0xFFD4E157), 'U': Color(0xFF00ACC1),
      'V': Color(0xFFFF8A65), 'W': Color(0xFFBA68C8), 'X': Color(0xFF4DB6AC),
      'Y': Color(0xFFFFD54F), 'Z': Color(0xFF90CAF9),
    };
    return colorMap[letter] ?? Colors.blueGrey;
  }

  /// A slightly deeper version of the same hue, for the gradient's far end.
  /// A flat fill looked like a placeholder; the shift gives the badge some
  /// depth without introducing a second colour.
  Color _deepen(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.08).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = clinicName.isNotEmpty ? clinicName[0].toUpperCase() : 'A';
    final color = _getColor(firstLetter);

    final Widget letterAvatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, _deepen(color)],
        ),
      ),
      child: Text(
        firstLetter,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );

    final Widget avatar = FutureBuilder<Uint8List?>(
      future: _logoCache.putIfAbsent(clinicName, () => _fetchLogo(clinicName)),
      builder: (context, snapshot) {
        // Show the letter avatar (not an empty gap) while the first and only
        // fetch is in flight.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return letterAvatar;
        }

        final logoImage = snapshot.data;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: logoImage != null
              ? Container(
                  key: const ValueKey('logo'),
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    // Uploaded logos are often white-on-transparent, which
                    // vanished against the white app bar.
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.memory(
                      logoImage,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('avatar'),
                  child: letterAvatar,
                ),
        );
      },
    );

    if (!elevated) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: avatar,
    );
  }

  Future<Uint8List?> _fetchLogo(String clinicName) async {
    final uri = Uri.parse(
      "${Urls.fetchLogo}?clinic_name=$clinicName",
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && data['logo_blob'].toString().length > 100) {
          return base64Decode(data['logo_blob']);
        }
      }
    } catch (_) {}
    return null;
  }
}
