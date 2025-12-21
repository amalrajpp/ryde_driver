import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String buttonName;
  final Color buttonColor;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final VoidCallback onTap;
  final bool isLoading;
  final IconData? icon;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isBorder;

  const CustomButton({
    super.key,
    required this.buttonName,
    required this.buttonColor,
    required this.textColor,
    this.height = 50,
    this.width,
    this.borderRadius = 8,
    required this.onTap,
    this.isLoading = false,
    this.icon,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.isBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: isLoading ? null : onTap,
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: isBorder
                ? Border.all(color: Colors.grey.shade300, width: 1.5)
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: fontSize + 2),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        buttonName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
