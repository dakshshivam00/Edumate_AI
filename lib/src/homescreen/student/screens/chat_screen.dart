import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), centerTitle: true),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _chatList.length,
        itemBuilder: (context, index) => ChatListItem(
          name: _chatList[index]['name']!,
          lastMessage: _chatList[index]['lastMessage']!,
          time: _chatList[index]['time']!,
          unread: _chatList[index]['unread']!,
          isOnline: _chatList[index]['isOnline']!,
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _chatList = [
    {
      'name': 'Course Support Team',
      'lastMessage': 'How can I help you with your course?',
      'time': '10:30 AM',
      'unread': 2,
      'isOnline': true,
    },
    {
      'name': 'John Doe (Instructor)',
      'lastMessage': 'Great question! Let me explain...',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
    },
    {
      'name': 'Jane Smith (Instructor)',
      'lastMessage': 'The assignment looks good!',
      'time': '2 days ago',
      'unread': 0,
      'isOnline': true,
    },
    {
      'name': 'Study Group',
      'lastMessage': 'Anyone available for a quick review?',
      'time': '3 days ago',
      'unread': 5,
      'isOnline': false,
    },
  ];
}

class ChatListItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;

  const ChatListItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundColor: AppTheme.textPrimary.withOpacity(
                AppTheme.containerOpacity * 2,
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.textTertiaryOpacity,
                ),
                size: 28.sp,
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textPrimary.withOpacity(
              AppTheme.textSecondaryOpacity,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.textSecondaryOpacity,
                ),
              ),
            ),
            if (unread > 0) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread.toString(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.buttonForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          // Navigate to chat detail
        },
      ),
    );
  }
}
