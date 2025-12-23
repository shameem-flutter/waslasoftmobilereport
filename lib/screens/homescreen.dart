import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:waslasoftreport/constants/colors.dart';
import 'package:waslasoftreport/screens/salesreport_screen.dart';
import 'package:waslasoftreport/services/api_services/auth_services.dart';
import 'package:waslasoftreport/utilities/gap_func.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});
  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  bool isLoading = false;
  Future<void> _handleLogout() async {
    final authService = AuthService();
    try {
      await authService.logout();
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });
      await Future.delayed(Duration(seconds: 2));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logged out successfully")));
      Navigator.pushReplacementNamed(context, "/login");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to log-out")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        actions: [
          IconButton(onPressed: _handleLogout, icon: Icon(Icons.logout)),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor.withValues(alpha: 0.01), whiteColor],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    vertGap(50),
                    Center(
                      child: Text(
                        "Reports",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.4,
                        ),
                        children: [
                          reportCard(
                            title: "SALES BACKOFFICE REPORTS",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalesreportScreen(),
                                ),
                              );
                            },
                          ),
                          reportCard(title: "CUSTOMER REPORT", onTap: () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

Widget reportCard({required String title, required VoidCallback onTap}) {
  return Padding(
    padding: const EdgeInsets.all(5.0),
    child: InkWell(
      splashColor: primaryColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Card(
        elevation: 3,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                whiteColor.withValues(alpha: 0.95),
                whiteColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
