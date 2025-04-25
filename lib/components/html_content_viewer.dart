import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

class HtmlContentViewer extends StatelessWidget {
  final String htmlContent;
  final Color? textColor;
  final double? fontSize;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final double? height;

  const HtmlContentViewer({
    Key? key,
    required this.htmlContent,
    this.textColor,
    this.fontSize,
    this.textAlign,
    this.fontWeight,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Eğer içerik HTML etiketleri içermiyorsa normal bir Text widget'ı döndür
    if (!htmlContent.contains('<') && !htmlContent.contains('>')) {
      return Text(
        htmlContent,
        style: GoogleFonts.poppins(
          fontSize: fontSize ?? 15,
          fontWeight: fontWeight ?? FontWeight.w500,
          color: textColor,
          height: height ?? 1.5,
        ),
        textAlign: textAlign ?? TextAlign.center,
      );
    }

    // HTML içeriğini işle
    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          fontSize: FontSize(fontSize ?? 15),
          fontWeight: fontWeight ?? FontWeight.w500,
          color: textColor,
          fontFamily: 'Poppins',
          textAlign: textAlign ?? TextAlign.center,
          lineHeight: LineHeight.percent(height != null ? height! * 100 : 150),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
        "ul": Style(
          margin: Margins.only(left: 16),
        ),
        "ol": Style(
          margin: Margins.only(left: 16),
        ),
        "li": Style(
          margin: Margins.only(bottom: 4),
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "u": Style(
          textDecoration: TextDecoration.underline,
        ),
      },
    );
  }
} 