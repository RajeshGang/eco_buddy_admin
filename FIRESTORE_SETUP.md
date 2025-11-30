# Firestore Setup Instructions

## Overview

This dashboard reads data from your **eco_buddy** app's Firestore database. The dashboard tracks:

- **Users** from the `users` collection
- **Scans** from the `scans` collection  
- **Sustainability Assessments** from the `sustainability_assessments` collection
- **Feature Flags** from the `feature_flags` collection

## Required Collections

Your eco_buddy app should be writing to these Firestore collections:

### 1. Users Collection (`users`)
Each user document should have:
```json
{
  "email": "user@example.com",
  "displayName": "User Name",
  "createdAt": Timestamp,
  "lastActive": Timestamp,
  "isActive": boolean
}
```

### 2. Scans Collection (`scans`)
Each scan document should have:
```json
{
  "userId": "user_id",
  "productName": "Product Name",
  "success": boolean,
  "status": "success" | "failed",
  "timestamp": Timestamp,
  "createdAt": Timestamp
}
```

### 3. Sustainability Assessments Collection (`sustainability_assessments`)
Each assessment document should have:
```json
{
  "userId": "user_id",
  "score": number (0-100),
  "sustainabilityScore": number,
  "environmentalImpact": {
    "carbon": number,
    "water": number,
    "waste": number
  },
  "timestamp": Timestamp,
  "createdAt": Timestamp
}
```

## Deploy Firestore Security Rules

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Deploy the security rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

   Or if you're in the eco_sustain_admin directory:
   ```bash
   cd /Users/rahulrajesh/coding/eco_sustain_admin
   firebase deploy --only firestore:rules
   ```

## Security Rules Summary

The rules allow:
- **Admins** (users in `admins` collection) can read/write all collections
- **Regular users** can read/write their own data
- **All authenticated users** can read feature flags

## Verify Setup

1. Make sure you're logged in as an admin user
2. Check that your admin user's UID exists in the `admins` collection in Firestore
3. Verify the collections exist and have data from your eco_buddy app
4. The dashboard will automatically calculate metrics from the raw data

## Troubleshooting

### Permission Denied Error
- Make sure you're logged in as an admin
- Verify your user UID is in the `admins` collection
- Deploy the Firestore rules: `firebase deploy --only firestore:rules`

### No Data Showing
- Check that your eco_buddy app is writing to the correct collections
- Verify the collection names match exactly: `users`, `scans`, `sustainability_assessments`
- Check that the field names match the expected structure

### Collections Don't Exist
- The dashboard will show empty states if collections don't exist
- Create test data in Firestore to verify the dashboard is working
- The dashboard calculates metrics in real-time from the collections

