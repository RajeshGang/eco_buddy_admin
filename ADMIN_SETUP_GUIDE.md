# Admin Dashboard Setup Guide

## Overview

This is a **private admin dashboard** for monitoring and managing your eco_buddy platform. It is **NOT** a public-facing application. Only pre-approved administrators can access it.

## How Admin Access Works

### The Correct Flow

1. **First Admin Setup** (One-time):
   - Create a Firebase Auth account for yourself (via Firebase Console or programmatically)
   - Manually add your User UID to the `admins` collection in Firestore
   - Sign in to the dashboard using your email and password

2. **Adding Additional Admins**:
   - Create Firebase Auth accounts for other admins
   - Manually add their User UIDs to the `admins` collection in Firestore
   - They can then sign in to the dashboard

3. **Sign-In Only**:
   - The dashboard only allows sign-in (no public sign-up)
   - Users must already exist in Firebase Auth
   - Users must have their UID in the `admins` collection

## Step-by-Step Setup

### Step 1: Create Your First Admin Account

**Option A: Via Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/project/ecobuddy-153ba/authentication/users)
2. Click "Add user"
3. Enter email and password
4. Copy the User UID that's generated

**Option B: Via Firebase CLI**
```bash
# Create user via Firebase Admin SDK or CLI
# (Requires Firebase Admin SDK setup)
```

### Step 2: Add to Admins Collection

1. Go to [Firestore Database](https://console.firebase.google.com/project/ecobuddy-153ba/firestore)
2. Navigate to the `admins` collection
3. Click "Add document"
4. Set the **Document ID** to your User UID (from Step 1)
5. Add these fields:
   ```json
   {
     "email": "your-email@example.com",
     "displayName": "Your Name",
     "createdAt": [timestamp - use the timestamp icon],
     "lastUpdated": [timestamp - use the timestamp icon]
   }
   ```

### Step 3: Sign In to Dashboard

1. Open the admin dashboard
2. Enter your email and password
3. You should now have full access!

## Adding More Admins

To add additional administrators:

1. **Create their Firebase Auth account** (via Console or programmatically)
2. **Add their UID to `admins` collection**:
   - Document ID = their User UID
   - Fields: `email`, `displayName`, `createdAt`, `lastUpdated`
3. **They can now sign in** to the dashboard

## Security Notes

- ✅ **No public sign-up** - prevents unauthorized access
- ✅ **Firestore rules** enforce admin-only access to data
- ✅ **Manual admin management** - you control who has access
- ✅ **Separate from main app** - admin dashboard is isolated

## Troubleshooting

### "Access denied. Admin privileges required."
- Your User UID is not in the `admins` collection
- Solution: Add your UID to the `admins` collection in Firestore

### "No user found for that email"
- The email doesn't exist in Firebase Auth
- Solution: Create the user account first (via Firebase Console)

### Can't see any data
- Check the Diagnostics page to see what collections exist
- Verify your eco_buddy app is writing to the expected collections
- Ensure Firestore rules are deployed: `firebase deploy --only firestore:rules`

## Best Practices

1. **Limit Admin Access**: Only add trusted team members to the `admins` collection
2. **Use Strong Passwords**: Enforce strong passwords for admin accounts
3. **Monitor Access**: Regularly review who has admin access
4. **Separate Accounts**: Use separate Firebase Auth accounts for admin vs. regular users

