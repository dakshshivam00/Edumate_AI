import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/homescreen/student/screens/enrolled_screen.dart';
import 'package:ailearning/src/homescreen/teacher/screens/ai_chat_screen.dart';
import 'package:ailearning/src/homescreen/student/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CourseMarketplaceScreen(),
    const EnrolledScreen(),
    const TeacherAIChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryColor,
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: AppTheme.textPrimary.withOpacity(
          AppTheme.textTertiaryOpacity,
        ),
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Enrolled'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class CourseMarketplaceScreen extends StatelessWidget {
  const CourseMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar - Pinned at top, not scrollable
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextFormField(
              cursorColor: AppTheme.secondaryColor,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.textTertiaryOpacity,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.textPrimary.withOpacity(
                  AppTheme.containerOpacity,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 16.w,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.borderOpacity,
                    ),
                  ),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.borderOpacity,
                    ),
                  ),
                ),

                hintStyle: TextStyle(
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.textTertiaryOpacity,
                  ),
                  fontSize: 16.sp,
                ),
              ),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16.sp),
              // TODO: Hook up search controller & logic as needed
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Courses
                  Text(
                    'Featured Courses',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Course List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: 6,
                    itemBuilder: (context, index) => CourseCard(
                      title: _courses[index]['title']!,
                      instructor: _courses[index]['instructor']!,
                      price: _courses[index]['price']!,
                      rating: _courses[index]['rating']!,
                      students: _courses[index]['students']!,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Flutter Development',
      'instructor': 'John Doe',
      'price': '\$49.99',
      'rating': 4.8,
      'students': 1234,
    },
    {
      'title': 'Machine Learning',
      'instructor': 'Jane Smith',
      'price': '\$79.99',
      'rating': 4.9,
      'students': 2345,
    },
    {
      'title': 'Web Development',
      'instructor': 'Mike Johnson',
      'price': '\$59.99',
      'rating': 4.7,
      'students': 1876,
    },
    {
      'title': 'Data Science',
      'instructor': 'Sarah Williams',
      'price': '\$89.99',
      'rating': 4.9,
      'students': 3456,
    },
    {
      'title': 'UI/UX Design',
      'instructor': 'David Brown',
      'price': '\$39.99',
      'rating': 4.6,
      'students': 987,
    },
    {
      'title': 'Python Programming',
      'instructor': 'Emily Davis',
      'price': '\$54.99',
      'rating': 4.8,
      'students': 2109,
    },
  ];
}

class CourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String price;
  final double rating;
  final int students;

  const CourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.price,
    required this.rating,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image Placeholder
            Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.containerOpacity * 2,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48.sp,
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.textTertiaryOpacity,
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    instructor,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textSecondaryOpacity,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      Expanded(child: SizedBox()),
                      Icon(
                        Icons.star,
                        size: 14.sp,
                        color: AppTheme.secondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '(${students}k)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textSecondaryOpacity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
