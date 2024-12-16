import 'package:base_flutter_framework/utils/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeConfig {
  ThemeConfig();

  static ThemeData createTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color accentColor,
    required Color primaryTextColor,
    required Color secondTextColor,
    required Color thirdTextColor,
    required Color fourthTextColor,
    required Color fifthTextColor,
    required Color primaryBackgroundColor,
    required Color error,
    Color? hintText,
    Color? divider,
    Color? disabled,
    Color? shadowColor,
    Color? primaryBorderColor,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    return ThemeData(
      brightness: brightness,
      // buttonColor: primaryColor,
      primaryColorLight: primaryColor,
      canvasColor: primaryBackgroundColor,
      cardColor: primaryBackgroundColor,
      dividerColor: divider,
      dividerTheme: DividerThemeData(
        color: divider,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardTheme(
        color: primaryBackgroundColor,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 4,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: primaryBorderColor!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        shadowColor: shadowColor,
      ),
      scaffoldBackgroundColor: primaryBackgroundColor,
      primaryColor: primaryColor,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor,
        selectionHandleColor: accentColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(
          color: secondTextColor,
        ),
      ),
      iconTheme: IconThemeData(
        color: secondTextColor,
        size: 16,
      ),
      
     
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
        colorScheme: ColorScheme(
          brightness: brightness,
          primary: primaryColor,
          primaryContainer: accentColor,
          secondary: accentColor,
          secondaryContainer: accentColor,
          surface: primaryBackgroundColor,
          background: primaryColor,
          error: error,
          onPrimary: primaryTextColor,
          onSecondary: primaryTextColor,
          onSurface: primaryTextColor,
          onBackground: primaryTextColor,
          onError: primaryTextColor,
          outline: primaryBorderColor,
          surfaceVariant: primaryBackgroundColor,
          onSurfaceVariant: primaryTextColor,
          inverseSurface: primaryBackgroundColor,
          onInverseSurface: primaryTextColor,
          inversePrimary: accentColor,
          shadow: shadowColor,
          scrim: Colors.black.withOpacity(0.5),
          surfaceTint: primaryColor,
        ),
        padding: const EdgeInsets.all(16),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: TextStyle(color: error),
        labelStyle: TextStyle(
          fontFamily: 'Mulish',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: primaryTextColor.withOpacity(0.5),
        ),
        hintStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w300,
        ),
      ),
      fontFamily: 'Mulish',
      unselectedWidgetColor: Colors.grey,
      textTheme: TextTheme(
        /// displayLarge (formerly headline1)
        displayLarge: baseTextTheme.displayLarge!.copyWith(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        /// displayMedium (formerly headline2)
        displayMedium: baseTextTheme.displayMedium!.copyWith(
          color: secondTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        /// displaySmall (formerly headline3)
        displaySmall: baseTextTheme.displaySmall!.copyWith(
          color: thirdTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        /// headlineMedium (formerly headline4)
        headlineMedium: baseTextTheme.headlineMedium!.copyWith(
          color: fourthTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        /// headlineSmall (formerly headline5)
        headlineSmall: baseTextTheme.headlineSmall!.copyWith(
          color: fifthTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        /// titleLarge (formerly headline6)
        titleLarge: baseTextTheme.titleLarge!.copyWith(
          color: primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),

        /// bodyLarge (formerly bodyText1)
        bodyLarge: baseTextTheme.bodyLarge!.copyWith(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),

        /// bodyMedium (formerly bodyText2)
        bodyMedium: baseTextTheme.bodyMedium!.copyWith(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),

        /// titleMedium (formerly subtitle1)
        titleMedium: baseTextTheme.titleMedium!.copyWith(
          color: primaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),

        /// titleSmall (formerly subtitle2)
        titleSmall: baseTextTheme.titleSmall!.copyWith(
          color: fifthTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),

        /// labelLarge (formerly button)
        labelLarge: baseTextTheme.labelLarge!.copyWith(
          color: secondTextColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),

        /// bodySmall (formerly caption)
        bodySmall: baseTextTheme.bodySmall!.copyWith(
          color: primaryTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w300,
        ),

        /// labelSmall (formerly overline)
        labelSmall: baseTextTheme.labelSmall!.copyWith(
          color: primaryTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => createTheme(
        brightness: Brightness.light,
        primaryColor: AppColor.primaryColorLight,
        primaryBackgroundColor: AppColor.primaryBackgroundColorLight,
        primaryTextColor: AppColor.primaryTextColorLight,
        secondTextColor: AppColor.secondTextColorLight,
        thirdTextColor: AppColor.thirdTextColorLight,
        fourthTextColor: AppColor.fourthTextColorLight,
        fifthTextColor: AppColor.fifthTextColorLight,
        hintText: AppColor.primaryHintColorLight,
        accentColor: AppColor.accentColorLight,
        divider: AppColor.dividerColorLight,
        disabled: AppColor.disabledColorLight,
        shadowColor: AppColor.shadowColorLight,
        primaryBorderColor: AppColor.primaryBorderColorLight,
        error: AppColor.errorColorLight,
      );

// static ThemeData get darkTheme => createTheme(
//       brightness: Brightness.dark,
//       primaryColor: AppColor.primaryColorDark,
//       primaryBackgroundColor: AppColor.primaryBackgroundColorDark,
//       primaryTextColor: AppColor.primaryTextColorDark,
//       secondTextColor: AppColor.secondTextColorDark,
//       hintText: AppColor.primaryHintColorDark,
//       accentColor: AppColor.accentColorDark,
//       divider: AppColor.dividerColorDark,
//       disabled: AppColor.disabledColorDark,
//       shadowColor: AppColor.shadowColorDark,
//       primaryBorderColor: AppColor.primaryBorderColorDark,
//       error: AppColor.errorColorDark,
//     );
}
