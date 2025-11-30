# Security Setup Guide

## Firebase Configuration

The `firebase_options.dart` file contains Firebase configuration including API keys. This file is excluded from version control for security reasons.

### Setting Up Firebase Configuration

1. **Install FlutterFire CLI** (if not already installed):
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configure Firebase for your project**:
   ```bash
   flutterfire configure
   ```
   
   This will:
   - Detect your Firebase projects
   - Generate `lib/firebase_options.dart` with your configuration
   - Set up Firebase for all platforms

3. **Verify the file was created**:
   ```bash
   ls lib/firebase_options.dart
   ```

### Important Security Notes

- **API Key Restrictions**: Even though client-side API keys are public, you should restrict them in Firebase Console:
  1. Go to [Google Cloud Console](https://console.cloud.google.com/)
  2. Select your project (`ecobuddy-153ba`)
  3. Navigate to "APIs & Services" > "Credentials"
  4. Find your API key and click "Edit"
  5. Under "Application restrictions", add your domain (e.g., `localhost`, your production domain)
  6. Under "API restrictions", restrict to only Firebase APIs

- **Never commit `firebase_options.dart`**: This file is in `.gitignore` and should never be pushed to version control.

- **For Team Members**: Each developer should run `flutterfire configure` to generate their own `firebase_options.dart` file.

### Alternative: Using Environment Variables

If you prefer to use environment variables, you can modify `firebase_options.dart` to read from environment variables:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  appId: String.fromEnvironment('FIREBASE_APP_ID'),
  // ... etc
);
```

Then run with:
```bash
flutter run --dart-define=FIREBASE_API_KEY=your_key --dart-define=FIREBASE_APP_ID=your_id
```

## Firestore Security Rules

Make sure your Firestore security rules are properly configured. See `firestore.rules` for the current rules.

Deploy rules with:
```bash
firebase deploy --only firestore:rules
```

