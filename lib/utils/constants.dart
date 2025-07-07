import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryAccentColor = Color(0xFF39FF14);
const Color kCardBackgroundColor = Color(0xFF1A1A1A);
const Color kBackgroundColor = Color(0xFF1A2E27); 
const Color kAccentColor = Color(0xFF90E24A);
const Color kCardColor = Color(0xFF2C3E36);       
const Color kWhiteColor = Color(0xFFF5F5F5);      
const Color kSecondaryTextColor = Color(0xFFB0C4B1); 


final TextStyle kAppTitleStyle = GoogleFonts.montserrat(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kWhiteColor,
);

final TextStyle kSectionTitleStyle = GoogleFonts.playfairDisplay(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: kWhiteColor,
);

final TextStyle kStatValueStyle = GoogleFonts.montserrat(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: kAccentColor,
);

final TextStyle kStatTitleStyle = GoogleFonts.montserrat(
  fontSize: 14,
  color: kSecondaryTextColor,
);


final TextStyle kBodyTextStyle = GoogleFonts.montserrat(
  fontSize: 16,
  color: kWhiteColor,
  height: 1.5,
);

final TextStyle kSecondaryBodyTextStyle = GoogleFonts.montserrat(
  fontSize: 14,
  color: kSecondaryTextColor,
);

final TextStyle kButtonTextStyle = GoogleFonts.montserrat(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: kBackgroundColor,
);