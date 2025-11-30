# EcoSustain Admin Dashboard

Admin dashboard for monitoring and managing the eco_buddy sustainability app.

## Features

- **User Analytics**: Track user growth, activity, and engagement
- **Sustainability Metrics**: Monitor sustainability scores and trends
- **Receipt Analytics**: Analyze receipt data and category breakdowns
- **Leaderboard Management**: View and manage user leaderboard
- **Recent Activity**: Monitor recent receipts and user actions
- **A/B Testing**: Configure feature flags and A/B tests
- **System Monitoring**: Check system status and performance
- **Firestore Diagnostics**: Inspect Firestore collections and data

## Setup

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase project set up
- Node.js (for Firebase CLI)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd eco_sustain_admin
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Set up Firebase configuration**:
   
   The `firebase_options.dart` file is excluded from version control for security. You need to generate it:
   
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```
   
   This will generate `lib/firebase_options.dart` with your Firebase configuration.

4. **Deploy Firestore security rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**:
   ```bash
   flutter run -d chrome
   ```

## Security

⚠️ **Important**: The `firebase_options.dart` file contains Firebase API keys and is excluded from version control.

- **Never commit** `lib/firebase_options.dart` to version control
- **Restrict API keys** in Google Cloud Console to your domains
- See `SECURITY_SETUP.md` for detailed security instructions

## Admin Access

To access the dashboard:

1. Create a Firebase Auth account
2. Add your user UID to the `admins` collection in Firestore:
   ```javascript
   // In Firebase Console > Firestore
   // Collection: admins
   // Document ID: <your-user-uid>
   // Fields:
   {
     email: "your-email@example.com",
     displayName: "Your Name",
     createdAt: <timestamp>,
     lastUpdated: <timestamp>
   }
   ```

3. Sign in with your Firebase Auth credentials

## Project Structure

```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
│   ├── auth/       # Authentication screens
│   └── dashboard/  # Dashboard sections
├── services/        # Business logic services
├── utils/           # Utilities and helpers
└── widgets/         # Reusable widgets
```

## Data Sources

The dashboard reads from the following Firestore collections:

- `leaderboard` - User points and rankings
- `users/{userId}/receipts` - User receipt data (subcollection)
- `users` - User profiles (if exists)
- `admins` - Admin user list

## Development

### Running in Development Mode

```bash
flutter run -d chrome --web-port=8080
```

### Building for Production

```bash
flutter build web --release
```

## Troubleshooting

### Permission Denied Errors

- Ensure your user UID is in the `admins` collection
- Verify Firestore rules are deployed: `firebase deploy --only firestore:rules`
- Check that you're signed in with Firebase Auth

### No Data Showing

- Verify collections exist in Firestore
- Check the Diagnostics page to see which collections are accessible
- Ensure Firestore rules allow admin read access

## License

[Your License Here]
