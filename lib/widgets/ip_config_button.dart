import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:waslasoftreport/widgets/ip_config_dialog.dart';

class IpConfigButton extends StatelessWidget {
  const IpConfigButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const IpConfigDialog(),
        );
      },
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.teal.withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Text(
          'IP',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.teal,
            letterSpacing: 0.5,
          ),
        ),
      ),
      tooltip: 'Configure IP Address',
    );
  }
}
