import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.height = 110});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final assetPath = isDarkMode
        ? 'assets/images/orientaaLogoDark.png'
        : 'assets/images/orientaaLogoLight.png';

    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
    );
  }
}