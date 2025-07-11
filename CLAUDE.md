# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application called "Smareter NEET Mobile" - an educational app for NEET (National Eligibility cum Entrance Test) preparation. The app uses Clerk for authentication and Firebase for backend services.

## Key Architecture

### Authentication & User Management
- **Clerk Authentication**: Uses `clerk_flutter` and `clerk_auth` packages for user authentication
- Main authentication flow handled in `lib/main.dart` with `ClerkAuth` wrapper
- Sign-in and sign-up screens are separate components (`signin_screen.dart`, `signup_screen.dart`)
- Publishable key: `pk_test_Y29udGVudC1yb29zdGVyLTU3LmNsZXJrLmFjY291bnRzLmRldiQ`

### Core Application Structure
- **Main App**: `SmaretneetApp` class in `lib/main.dart` serves as the root widget
- **Navigation**: Uses `ClerkAuthBuilder` to conditionally show signed-in vs signed-out states
- **State Management**: Uses StatefulWidget pattern with setState for local state

### API Integration
- **Base API URL**: `https://dev.smarterneet.com/api/`
- **Subjects API**: `/subjects` endpoint returns subject data in format: `{data: [subject_objects]}`
- **Vercel Protection Bypass**: Configured to bypass Vercel security checkpoints using automation headers
- **Retry Logic**: Implements exponential backoff with jitter for API calls (max 5 retries)
- **Fallback Data**: Static fallback subjects (Physics, Chemistry, Botany, Zoology) for offline scenarios
- **Error Handling**: Comprehensive error handling with visual feedback for network issues

### Firebase Integration
- **Project ID**: `smarter-neet-mobile`
- **Platform Support**: Android and Web configured
- **Configuration**: `firebase.json` and `lib/firebase_options.dart` handle platform-specific settings

## Common Development Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device-id>

# Build for release
flutter build apk                 # Android
flutter build ios                 # iOS

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build files
flutter clean
```

### Code Quality
- **Linting**: Uses `flutter_lints` package with standard Flutter linting rules
- **Analysis**: Configuration in `analysis_options.yaml` with `package:flutter_lints/flutter.yaml`
- **Code Style**: Follow standard Flutter/Dart conventions

## Important Implementation Notes

### API Error Handling Pattern
The app implements a robust retry mechanism in `practice_page.dart`:
- Exponential backoff with jitter (1s, 2s, 4s, 8s, 16s)
- Rate limiting detection (429 responses)
- Automatic fallback to static data on complete failure
- Visual indicators for offline/cached states

### Authentication Flow
1. App starts with `ClerkAuth` wrapper
2. `ClerkAuthBuilder` determines if user is signed in
3. Signed-out users see Sign In/Sign Up buttons
4. Signed-in users see "Welcome Home!" placeholder

### Navigation Flow
1. Practice page shows list of available subjects
2. Tapping a subject navigates to Subject Details screen
3. Subject Details screen shows study options (Practice Tests, Study Materials, etc.)
4. Each study option shows placeholder "coming soon" messages

### Subject Data Structure
```dart
{
  "subject_id": int,
  "subject_name": string,
  "subject_code": string,
  "is_active": boolean
}
```

## Development Notes

### Platform-Specific Configuration
- **iOS**: Requires Podfile configuration, currently untracked
- **Android**: Standard Gradle configuration with Kotlin
- **macOS**: Full desktop support configured
- **Web**: Firebase and basic web support enabled

### Dependencies
- `clerk_flutter` & `clerk_auth`: Authentication (beta versions 0.0.9-beta)
- `firebase_core`: Firebase integration
- `http`: API communication
- `shared_preferences`: Local storage
- `logging`: Debug logging

### Testing
- Uses `flutter_test` for unit testing
- Test files should be placed in `test/` directory
- Run tests with `flutter test`

## Project Structure
```
lib/
├── main.dart                   # App entry point & auth setup
├── signin_screen.dart          # Sign-in UI (ClerkAuthentication widget)
├── signup_screen.dart          # Sign-up UI (custom implementation)
├── practice_page.dart          # Main subjects listing with API integration
├── subject_details_screen.dart # Subject details with study options
├── config.dart                 # App configuration including API settings
└── firebase_options.dart       # Firebase configuration
```

## Common Issues & Solutions

### Vercel Security Checkpoint
**Problem**: API requests blocked by Vercel's security checkpoint with 429 status code.

**Solution**: Configure Vercel Protection Bypass for Automation:
1. Go to your Vercel project settings
2. Navigate to "Functions" > "Protection Bypass for Automation"
3. Generate a bypass secret
4. Update `lib/config.dart`:
   ```dart
   static const String? vercelBypassSecret = 'your-secret-here';
   ```

**Backend CORS Configuration**: See `docs/backend-setup.md` for complete Next.js API setup

**Debugging Tools**:
- Use the debug button (🐛) in the app when `enableApiLogging` is true
- Check Android permissions in `android/app/src/main/AndroidManifest.xml`
- Network diagnostic tool tests connectivity, HTTPS, and API endpoints

### Network Connectivity
- App gracefully handles network failures with retry logic
- Fallback data ensures app remains functional offline
- Visual indicators help users understand connection status

### Authentication State
- Clerk handles authentication state automatically
- Use `ClerkAuthBuilder` to react to auth state changes
- Authentication errors are handled by `ClerkErrorListener`