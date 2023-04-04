import 'dart:ui';

import 'package:chitchat/LogUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  late AppLocalizations loc;
  late String copied;

  CodeElementBuilder(this.context){
    loc = AppLocalizations.of(context)!;
    copied = loc.code_copied_to_clipboard;
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }

    double? width;
    if (language.length > 0) {
      width =
          MediaQueryData.fromWindow(WidgetsBinding.instance!.window).size.width;
    }

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () async {
          // Copy code to clipboard when user taps on it
          await Clipboard.setData(ClipboardData(text: element.textContent));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Code copied to clipboard"),
              duration: Duration(milliseconds: 1000),
            ),
          );
        },
        child: HighlightView(
          // The original code to be highlighted
          element.textContent,
          // Specify language
          // It is recommended to give it a value for performance
          language: language,
          // Specify highlight theme
          // All available themes are listed in `themes` folder
          theme: MediaQueryData.fromWindow(WidgetsBinding.instance!.window)
                      .platformBrightness ==
                  Brightness.light
              ? atomOneLightTheme
              : atomOneDarkTheme,
          // Specify padding
          padding: const EdgeInsets.all(8),
          // Specify text style
          textStyle: GoogleFonts.robotoMono(),
        ),
      ),
    );
  }
}
