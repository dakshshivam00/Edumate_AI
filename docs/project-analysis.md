# AI Learning Project Analysis

Generated on 2026-05-04 from the local Flutter project at `/Users/shivam/development/apps/ailearning`.

## 1. Executive Summary

This project is a Flutter mobile learning app currently branded in different places as `AI Learning`, `EduMate AI`, `Ailearning`, and `Edumate_AI`. The product idea is an AI-assisted education platform with two roles:

- Students browse courses, continue enrolled courses, watch YouTube lesson playlists, and ask an AI assistant for help.
- Teachers create courses, add YouTube videos, preview course content, and use the same AI assistant.

The app is in a prototype-to-MVP state. Authentication, role routing, YouTube playback, AI chat streaming, FCM token registration, and teacher course creation are implemented at code level. Many content areas still use static or in-memory data, and several UI actions are placeholders.

## 2. Technology Stack

| Area | Current implementation |
| --- | --- |
| App framework | Flutter |
| Language | Dart |
| State style | Mostly local widget state plus singleton service classes |
| Auth | Firebase Auth with email/password and Google Sign-In |
| Push notifications | Firebase Messaging |
| Backend communication | `http` package |
| Video playback | `youtube_player_flutter` |
| Responsive sizing | `flutter_screenutil` with design size `375 x 812` |
| Local storage | `shared_preferences` |
| UI system | Material 3 dark theme |

Important dependencies are declared in `pubspec.yaml`: `firebase_core`, `firebase_auth`, `firebase_messaging`, `google_sign_in`, `youtube_player_flutter`, `shared_preferences`, `http`, `flutter_screenutil`, and `top_snackbar_flutter`.

## 3. Branding And App IDs

The project has several names in different files:

| Location | Value |
| --- | --- |
| `pubspec.yaml` | `ailearning` |
| `MaterialApp.title` | `AI Learning` |
| Android app label | `EduMate AI` |
| Android package / namespace | `com.ailearning` |
| iOS display name | `Ailearning` |
| README heading | `ailearning` and `Edumate_AI` |

Recommendation: choose one public brand name and align Android, iOS, README, and in-app text before release.

## 4. High-Level Architecture

The app starts in `lib/main.dart`.

Startup flow:

1. Flutter binding is initialized.
2. Firebase is initialized.
3. `MyApp` creates the Material app, global navigator key, global scaffold messenger key, and app theme.
4. `AuthWrapper` listens to `FirebaseAuth.instance.authStateChanges()`.
5. If no user is logged in, the app shows `LoginScreen`.
6. If a user is logged in, `UserRoleService.isTeacher()` decides between teacher home and student home.

Key folders:

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | App boot, Firebase init, auth wrapper, role routing |
| `lib/src/authentication` | Login, signup, password reset, Firebase Auth wrapper |
| `lib/src/homescreen/student` | Student bottom tabs, marketplace, enrolled courses, profile |
| `lib/src/homescreen/teacher` | Teacher bottom tabs, course management, AI chat |
| `lib/src/homescreen/services` | Course service and in-memory course lists |
| `lib/src/services` | Chat API and FCM API services |
| `lib/src/screens` | Shared video list and YouTube course player |
| `lib/src/common` | Theme, text field, buttons, snackbars, dialogs, role storage |

## 5. User Roles

### Student

Student role is selected from the login/signup screen toggle. It is stored locally in SharedPreferences as `user_role = student`.

Student navigation tabs:

- `Home`: course marketplace.
- `Enrolled`: enrolled course list with progress and continue button.
- `Chat`: currently wired to `TeacherAIChatScreen`, not the separate static student `ChatScreen`.
- `Profile`: profile, stats, menu placeholders, logout.

Student features currently present:

- Browse a static list of featured courses.
- Search input exists, but the search logic is not connected.
- See static enrolled courses such as `JAVA & DSA`, `Flutter Development`, and `Adobe premiere pro`.
- Continue learning by opening the YouTube playlist player.
- Open an AI assistant from the bottom nav or from the floating action button in the video player.

### Teacher

Teacher role is also selected from the login/signup screen toggle. It is stored locally in SharedPreferences as `user_role = teacher`.

Teacher navigation tabs:

- `My Courses`: course list and course creation.
- `Chat`: AI assistant.
- `Profile`: same student profile implementation is reused.

Teacher features currently present:

- View in-memory teacher courses.
- Add a course through a dialog.
- Call backend `POST /create-course`.
- Add videos to a course by title and YouTube URL.
- Open a course detail screen.
- Delete videos from a course detail screen.
- Preview course videos in the same YouTube player.
- New courses and newly added videos are inserted at the top of their lists for immediate visibility.

Important behavior: teacher course creation calls the backend first, then adds the course to the local in-memory list. Video additions and deletions are currently local only, and local list ordering is newest-first for both courses and videos.

## 6. Authentication And Role Flow

Files:

- `lib/src/authentication/presentation/screens/login_screen.dart`
- `lib/src/authentication/presentation/screens/forgotten_password_screen.dart`
- `lib/src/authentication/application/auth_provider.dart`
- `lib/src/common/user_role_service.dart`

Supported auth methods:

- Email/password signup.
- Email/password login.
- Google Sign-In through Firebase.
- Password reset email.
- Logout from Firebase and Google.

Login/signup UX:

- One screen toggles between login and signup.
- A segmented control switches between Student and Teacher.
- Signup asks for full name, email, password, and confirm password.
- Google sign-in is available in both login and signup modes.
- Validation errors and backend/auth errors are shown through the global top snackbar.

Role storage:

- Role is stored on the device through `SharedPreferences`.
- Missing role defaults to student.
- Existing users can effectively overwrite the local role by choosing a role on the login screen before signing in.

Recommendation: store user role server-side or in Firebase custom claims/profile data. Local-only role storage can become incorrect across devices, app reinstalls, or shared devices.

## 7. Backend And API Integration

Main backend base URL:

```text
http://35.238.224.109
```

Services:

- `ChatService` handles auth token retrieval and AI chat APIs.
- `CourseService` handles auth token retrieval and course creation.
- `FCMService` sends device FCM token data to the backend.

### Auth Token Exchange

Both `ChatService` and `CourseService` call:

```text
POST /auth?user_type=user
POST /auth?user_type=teacher
```

Body:

```json
{
  "firebase_token": "..."
}
```

The response is expected to contain `access_token`, `token`, `accessToken`, or a first string value. The token is cached in SharedPreferences under separate keys:

- `chat_access_token`
- `course_access_token`

If a `401` happens, the cached token is cleared.

### AI Chat

Streaming chat endpoint:

```text
POST /chat
Authorization: Bearer <access token>
Accept: text/event-stream
Content-Type: application/json
```

Body without video:

```json
{
  "query": "student or teacher question"
}
```

Body with video context:

```json
{
  "query": "question about current lesson",
  "video_url": "extracted-youtube-id-or-id-plus-query"
}
```

The app parses Server-Sent Events style chunks beginning with `data: `. It supports JSON chunks with `content`, `text`, or `delta`, and also plain text chunks.

Important note: `sendChatMessageWithVideo` uses a hardcoded ngrok URL, while the streaming video chat path uses the main backend URL. The screen currently uses the streaming method, but this should still be cleaned up.

### Course Creation

Course creation endpoint:

```text
POST /create-course?course_title=<title>&course_description=<description>
Authorization: Bearer <access token>
```

The UI prints the response, shows an error snackbar on failure, and adds the course locally on success.

### FCM Token Registration

After login/signup, `FCMService` requests notification permission, gets the FCM token, gets the Firebase ID token, and sends:

```text
POST /auth?user_type=user
POST /auth?user_type=teacher
```

Body includes:

```json
{
  "firebase_token": "...",
  "device_data": {
    "fcm_token": "...",
    "timezone": "..."
  }
}
```

## 8. UI And Design System

Main theme file:

- `lib/src/common/app_theme.dart`

Current style:

- Dark Material 3 app.
- Primary surface is black.
- Main foreground/accent is white.
- Buttons are usually white with black text.
- Containers use white opacity overlays and thin white borders.
- Cards and inputs use rounded corners, usually `12` or `16`.
- Responsive dimensions use `flutter_screenutil`.

Shared UI components:

- `AuthField`: labeled text field with optional password visibility toggle.
- `CustomElevatedButton`: button with loading state when `onPressed` is null.
- `GradientContainer`: currently just a full-size surface container, not a visible gradient.
- `GlobalScaffoldManager`: global top snackbar with error, success, info, and progress styles.
- `CustomDialogBox`: confirmation dialog used by the profile logout flow.

UI observations:

- The design is consistent and readable, but very monochrome.
- Several components use `Poppins`, but no font asset is declared in `pubspec.yaml`, so the app will fall back unless the font is provided by the platform.
- Student and teacher profiles share nearly identical code in two files.
- The app uses remote YouTube thumbnail images instead of bundled visual assets.
- Some action icons and menu items exist without behavior yet.

## 9. Screen-By-Screen Functionality

### Login Screen

File: `lib/src/authentication/presentation/screens/login_screen.dart`

Purpose:

- Entry screen for login/signup.
- Lets user choose Student or Teacher.
- Handles email/password auth and Google Sign-In.
- Sends FCM token after auth.

Current gaps:

- Role is stored locally instead of server-side.
- Loading state is represented by disabling buttons, which makes `CustomElevatedButton` show loading text.
- Signup only updates Firebase display name; no app profile is created in a backend user table from this screen.

### Forgotten Password Screen

File: `lib/src/authentication/presentation/screens/forgotten_password_screen.dart`

Purpose:

- Validates email.
- Sends Firebase password reset email.
- Shows success state and back-to-login action.

### Student Home / Marketplace

File: `lib/src/homescreen/student/screens/home_screen.dart`

Purpose:

- Student bottom navigation shell.
- Marketplace screen with search input and featured course cards.

Current gaps:

- Course data is static.
- Search input has a TODO and no controller/filtering.
- Course cards display data but do not navigate to a detail or purchase/enroll flow.

### Enrolled Courses

File: `lib/src/homescreen/student/screens/enrolled_screen.dart`

Purpose:

- Shows static enrolled courses.
- Displays YouTube-derived thumbnails.
- Shows progress bars.
- Opens `CourseVideoPlayerScreen`.

Current gaps:

- Uses its own static list instead of `CourseService.enrolledCourses`.
- Progress is static and not updated from playback.
- No enrollment sync with backend.

### Course Video Player

File: `lib/src/screens/course_video_player_screen.dart`

Purpose:

- Converts YouTube URLs into video IDs.
- Auto-selects a starting lesson based on the course progress value.
- Shows YouTube player and playlist.
- Marks previous lessons as watched based on progress.
- Auto-switches to the next video on video end.
- Opens AI assistant with the current video URL.

Current gaps:

- Watched state is local to the screen session.
- Progress is not saved.
- Lesson titles are generated as `Lesson 1`, `Lesson 2`, etc.
- The overflow menu button has no behavior.

### Teacher Courses

File: `lib/src/homescreen/teacher/screens/home_screen.dart`

Purpose:

- Teacher bottom navigation shell.
- Shows teacher courses.
- Allows adding a course.
- Allows adding videos to a course from the course card.

Current gaps:

- Course list is in-memory and resets when the app restarts.
- Created courses are not fetched from backend.
- Video add dialog validates non-empty fields only, not valid YouTube URLs.
- Uses `print` for debugging output.

### Teacher Course Detail

File: `lib/src/homescreen/teacher/screens/teacher_course_detail_screen.dart`

Purpose:

- Shows selected course info and video list.
- Allows adding videos.
- Allows deleting videos.
- Opens the video player for preview.

Current gaps:

- Deletes mutate the in-memory list only.
- No edit course details flow.
- No reorder video flow.

### AI Assistant

File: `lib/src/homescreen/teacher/screens/ai_chat_screen.dart`

Purpose:

- Chat UI used by both students and teachers.
- Supports normal chat and video-context chat.
- Streams AI response chunks into the current chat bubble.
- Parses JSON responses.
- If the JSON contains a `questions` list, it renders a quiz UI and highlights correct answers.

Current gaps:

- Screen name says teacher even though students also use it.
- Chat history is not persisted.
- No stop-generation action.
- No retry action for failed messages.
- No prompt shortcuts for common learning actions.

### Student Chat Screen

File: `lib/src/homescreen/student/screens/chat_screen.dart`

Purpose:

- Static message list UI for support, instructors, and study group.

Current status:

- This screen is not currently wired into student bottom navigation. The student chat tab uses `TeacherAIChatScreen`.

### Profile

Files:

- `lib/src/homescreen/student/screens/profile_screen.dart`
- `lib/src/homescreen/profile_screen.dart`

Purpose:

- Shows Firebase display name and email.
- Shows static stats: courses, progress, certificates.
- Shows menu rows for edit profile, notifications, settings, help, and about.
- Handles logout.

Current gaps:

- Stats are static.
- Menu rows have empty callbacks.
- There are duplicate profile implementations.

## 10. Data Model Today

The current project does not have formal model classes. It mainly uses `Map<String, dynamic>`.

Course-like maps include fields such as:

- `title`
- `description`
- `instructor`
- `price`
- `rating`
- `students`
- `progress`
- `thumbnail`
- `videoUrls`

Video values may be either:

- A raw URL string.
- A map like `{ "title": "...", "url": "..." }`.

Recommendation: introduce typed models such as `Course`, `VideoLesson`, `UserProfile`, and `ChatMessageDto`. This will reduce casting issues and make backend integration easier.

## 11. Platform Configuration

### Android

File: `android/app/src/main/AndroidManifest.xml`

Current settings:

- Internet permission is enabled.
- App label is `EduMate AI`.
- Cleartext traffic is allowed with `android:usesCleartextTraffic="true"`.
- Hardware acceleration is enabled.

File: `android/app/build.gradle.kts`

Current settings:

- Namespace and application ID are `com.ailearning`.
- Google services plugin is applied.
- Release build currently uses debug signing config.

Android Firebase config exists:

- `android/app/google-services.json`

### iOS

File: `ios/Runner/Info.plist`

Current settings:

- Display name is `Ailearning`.
- Portrait and landscape orientations are supported.
- No Firebase `GoogleService-Info.plist` was found in the repo.
- No App Transport Security exception was found for the plain HTTP backend.

Important risk: the backend URL is plain `http://35.238.224.109`. Android explicitly allows cleartext traffic, but iOS may block it unless HTTPS is used or an ATS exception is added.

## 12. Quality And Static Analysis

Command run:

```text
dart analyze
```

Result:

```text
325 issues found
```

Most issues are lints or deprecations, not compile-breaking syntax errors. The most important categories are:

- One warning: unnecessary non-null assertion in `lib/src/homescreen/teacher/screens/ai_chat_screen.dart`.
- Many `withOpacity` deprecation notices. Newer Flutter prefers `withValues()`.
- Many `avoid_print` notices in API services.
- Deprecated Firebase Auth method `fetchSignInMethodsForEmail`.

Testing status:

- The only test file is `test/widget_test.dart`.
- It is still the generated counter app test and does not match this app.
- There are no focused tests for auth routing, role storage, video URL parsing, chat streaming parsing, or course management.

## 13. Main Risks And Gaps

1. Role is local-only.
   A user role should come from backend/Firebase profile data, not only from SharedPreferences.

2. Course data is split and mostly static.
   Student enrolled data, marketplace data, and teacher data are separate local lists.

3. Backend configuration is hardcoded.
   Base URLs, the ngrok URL, and Google web client ID are embedded in source code.

4. iOS backend calls may fail.
   The app uses HTTP backend URLs, but iOS does not show an ATS exception.

5. Production logging is noisy.
   Services print Firebase tokens, FCM tokens, API responses, and stack traces. This is risky for release builds.

6. Navigation has unused or duplicate screens.
   Student `ChatScreen` is not wired in, and profile code exists in two locations.

7. Tests are not meaningful yet.
   The generated widget test should be replaced with tests for the real app.

8. Some product flows are placeholders.
   Search, marketplace course detail, purchase/enroll, edit profile, settings, notifications, help, about, and messaging are not implemented.

9. App naming is inconsistent.
   Public name and platform labels should be aligned.

10. Release readiness is incomplete.
   Android release signing still uses debug config, and iOS Firebase config appears missing.

## 14. Product Ideas To Build Next

### Student Experience

- Real course catalog fetched from backend.
- Course detail page with instructor info, lessons, rating, price, and enroll button.
- Search and filters by category, duration, price, difficulty, and rating.
- Persisted enrollment and progress tracking.
- Continue watching from exact lesson and timestamp.
- AI tutor prompts from video player, such as summarize lesson, explain this concept, generate quiz, create notes, and ask doubts.
- Certificates after course completion.
- Saved notes per video.
- Download/offline mode for allowed content.

### Teacher Experience

- Teacher dashboard with course count, student count, completion rate, and revenue or engagement metrics.
- Course editor with title, description, thumbnail, category, price, and draft/publish status.
- Lesson manager with reorder, edit, delete, and validation for YouTube URLs.
- Analytics per lesson: views, average watch time, common AI questions, quiz scores.
- AI course builder to generate outline, lesson titles, quizzes, and assignments.
- Notifications to students when new lessons are added.

### AI Experience

- Rename `TeacherAIChatScreen` to a role-neutral name such as `AIAssistantScreen`.
- Persist chat history by course and video.
- Add prompt chips for common actions.
- Add quiz-taking mode instead of only showing correct answers.
- Add citations or timestamps when answering from video context.
- Add retry, regenerate, copy, and clear chat actions.

### Platform And Backend

- Move backend URLs and OAuth client IDs to environment-specific config.
- Use HTTPS for backend APIs.
- Add typed API clients and response models.
- Add refresh/expiry logic for access tokens.
- Add centralized logging that hides tokens and sensitive data.
- Add iOS Firebase config and notification setup if iOS support is required.

## 15. Suggested Implementation Roadmap

### Phase 1: Foundation Cleanup

- Pick one app name and update Android, iOS, README, and `MaterialApp`.
- Replace generated widget test with a basic app smoke test.
- Remove duplicate profile screen.
- Rename AI chat screen to a role-neutral name.
- Move backend URL and client IDs out of source code.
- Stop printing tokens and raw backend responses in production paths.

### Phase 2: Real Data Integration

- Create typed `Course`, `Lesson`, `UserProfile`, and `ChatMessage` models.
- Replace hardcoded student marketplace and enrolled-course lists with backend APIs.
- Fetch teacher courses from backend.
- Persist video add/delete operations through backend.
- Store role/profile data on backend or Firebase.

### Phase 3: Learning Flow

- Add course detail page.
- Add enroll/purchase flow.
- Persist progress by lesson and timestamp.
- Add notes and bookmarks.
- Add better error, loading, and empty states around network calls.

### Phase 4: AI And Teacher Tools

- Add AI prompt shortcuts.
- Add quiz-taking flow with scoring.
- Add teacher analytics.
- Add AI-assisted course/lesson generation.
- Add push notifications for course updates.

## 16. Useful File Reference

| File | Why it matters |
| --- | --- |
| `lib/main.dart` | Firebase init, app shell, auth state routing |
| `lib/src/authentication/application/auth_provider.dart` | Firebase Auth and Google Sign-In wrapper |
| `lib/src/authentication/presentation/screens/login_screen.dart` | Login/signup UI and role selection |
| `lib/src/common/user_role_service.dart` | Local student/teacher role persistence |
| `lib/src/services/chat_service.dart` | Backend auth token exchange and AI chat streaming |
| `lib/src/services/fcm_service.dart` | Push notification token registration |
| `lib/src/homescreen/services/course_service.dart` | Course creation API and in-memory course state |
| `lib/src/homescreen/student/screens/home_screen.dart` | Student navigation and course marketplace |
| `lib/src/homescreen/student/screens/enrolled_screen.dart` | Static enrolled courses and continue learning |
| `lib/src/homescreen/teacher/screens/home_screen.dart` | Teacher course list, add course, add video |
| `lib/src/homescreen/teacher/screens/teacher_course_detail_screen.dart` | Teacher video list and video delete |
| `lib/src/homescreen/teacher/screens/ai_chat_screen.dart` | AI assistant UI, streaming response rendering, quiz JSON rendering |
| `lib/src/screens/course_video_player_screen.dart` | YouTube playlist player and video-context AI entry |
| `lib/src/common/app_theme.dart` | App-wide colors and Material theme |

## 17. Final Product Direction

The strongest direction for this app is:

> An AI-powered mobile learning platform where teachers publish video-based courses and students learn through playlists, progress tracking, quizzes, and a video-aware AI tutor.

The current code already has the right building blocks for that direction: Firebase auth, role routing, course/video management, YouTube playback, chat streaming, quiz rendering, and FCM registration. The next big step is turning the prototype data into real backend-backed entities and tightening the production foundation.
