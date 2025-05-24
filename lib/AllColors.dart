import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AllColors {
  static Color primaryColor = const Color(0xff6e0000);
  static Color secondaryColor = const Color(0xffD4AF37);
  static Color third = const Color(0xFFFFFFFF);
  static Color bodytext = const Color(0xFF654321);
  static Color hintcolor = const Color.fromARGB(255, 132, 110, 91);
  static Color background = const Color(0xffF5F5DC);
  static Color notifactions = const Color(0xFFF2DC8C);
}

class AllIcons {
  static Icon google = Icon(
    Icons.g_mobiledata_sharp,
    color: AllColors.bodytext,
    size: Adaptive.h(5),
  );
  static Icon facebook = Icon(
    Icons.facebook,
    color: AllColors.bodytext,
    size: Adaptive.h(4),
  );
  static Icon search = Icon(
    Icons.search,
    color: AllColors.bodytext,
    size: Adaptive.h(4),
  );
  static Icon menu = Icon(
    Icons.menu,
    color: AllColors.third,
    size: Adaptive.h(4),
  );

}

class Allfonts {
  static TextStyle body = GoogleFonts.poppins(color: AllColors.bodytext)
      .copyWith(fontWeight: FontWeight.w600, fontSize: 15.sp);
  static TextStyle body2 = GoogleFonts.poppins(color: AllColors.secondaryColor)
      .copyWith(fontWeight: FontWeight.w600, fontSize: 15.sp);
  static TextStyle header =
  GoogleFonts.ebGaramond(color: AllColors.primaryColor)
      .copyWith(fontWeight: FontWeight.w600, fontSize: 21.sp);

}
