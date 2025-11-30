# Admin Setup Guide

## Quick Fix for Permission Errors

If you're seeing "Missing or insufficient permissions" errors, follow these steps:

### Step 1: Get Your User UID

1. Sign in to the dashboard
2. Check the browser console (F12) or look at the top right of the dashboard - it should show your email
3. Or check Firebase Console → Authentication → Users to find your User UID

### Step 2: Add Yourself as Admin

1. Go to [Firebase Console](https://console.firebase.google.com/project/ecobuddy-153ba/firestore)
2. Navigate to **Firestore Database**
3. Create or open the `admins` collection
4. Add a new document with:
   - **Document ID**: Your User UID (from Step 1)
   - **Fields**:
     - `email`: your email address
     - `displayName`: your name (optional)
     - `createdAt`: current timestamp

### Step 3: Refresh the Dashboard

1. Sign out and sign back in, OR
2. Hard refresh the page (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)

## Verify Admin Status

You can verify you're an admin by checking:
- Firebase Console → Firestore → `admins` collection
- Your User UID should exist as a document ID in that collection

## Alternative: Use Sign Up

If you just created an account using the Sign Up feature, you should already be added to the `admins` collection automatically. If not, follow Step 2 above.

## Troubleshooting

### Still seeing permission errors?

1. **Check Firestore Rules are deployed:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Verify your UID is in admins collection:**
   - Go to Firebase Console
   - Check Firestore → `admins` collection
   - Your UID should be there

3. **Clear browser cache and refresh**

4. **Sign out and sign back in**

### Need to add multiple admins?

Just add more documents to the `admins` collection with each user's UID as the document ID.

