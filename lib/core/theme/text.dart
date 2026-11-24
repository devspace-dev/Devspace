import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

abstract class DsText {
  // Anton: headings, numbers, buttons. Always render UPPERCASE via .toUpperCase().
  static TextStyle display = GoogleFonts.anton(fontSize: 56, height: 1.0, letterSpacing: 1.5, color: Ds.bone);
  static TextStyle h1      = GoogleFonts.anton(fontSize: 40, height: 1.0, letterSpacing: 1.2, color: Ds.bone);
  static TextStyle h2      = GoogleFonts.anton(fontSize: 28, letterSpacing: 1.0, color: Ds.bone);
  static TextStyle h3      = GoogleFonts.anton(fontSize: 22, letterSpacing: 0.8, color: Ds.bone);
  static TextStyle number  = GoogleFonts.anton(fontSize: 18, letterSpacing: 0.6, color: Ds.aura);
  static TextStyle button  = GoogleFonts.anton(fontSize: 19, letterSpacing: 1.2, color: Ds.onAura);

  // Rubik: everything readable
  static TextStyle question = GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: Ds.bone);
  static TextStyle body     = GoogleFonts.rubik(fontSize: 16, height: 1.45, color: Ds.bone);
  static TextStyle bodySm   = GoogleFonts.rubik(fontSize: 14, height: 1.4, color: Ds.muted);
  static TextStyle label    = GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: Ds.bone);
  static TextStyle caption  = GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: Ds.muted);
}
