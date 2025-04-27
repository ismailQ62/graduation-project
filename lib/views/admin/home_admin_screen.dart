import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome, Admin 🛠️",
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              /* SizedBox(height: 10.h),
              Text(
                "You have full control over the system. Manage users, zones, and channels efficiently.",
                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                textAlign: TextAlign.center,
              ), */
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.manageUsers,
          ); // Navigate to user management
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.supervisor_account, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.verification);
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.manageChannel);
              },
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: Icon(Icons.map, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.map);
              },
            ),
            IconButton(
              icon: Icon(Icons.person, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ],
        ),
      ),
    );
  }
}
