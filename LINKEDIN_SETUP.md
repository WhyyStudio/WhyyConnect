# LinkedIn Integration Setup Guide

This guide will help you set up LinkedIn integration for your Whyy Connect app.

## Step 1: Create a LinkedIn App

1. Go to [LinkedIn Developer Portal](https://www.linkedin.com/developers/)
2. Click "Create App"
3. Fill in the required information:
   - **App Name**: Whyy Connect
   - **LinkedIn Page**: Select your LinkedIn page
   - **Privacy Policy URL**: Your app's privacy policy URL
   - **App Logo**: Upload your app logo
   - **Legal Agreement**: Accept the terms

## Step 2: Configure OAuth Settings

1. In your LinkedIn app dashboard, go to "Auth" tab
2. Add the following redirect URLs:
   - For Android: `https://www.linkedin.com/developers/apps/YOUR_APP_ID/auth`
   - For iOS: `https://www.linkedin.com/developers/apps/YOUR_APP_ID/auth`
   - For Web: `https://www.linkedin.com/developers/apps/YOUR_APP_ID/auth`

## Step 3: Request API Access

1. Go to "Products" tab in your LinkedIn app
2. Request access to the following products:
   - **Sign In with LinkedIn using OpenID Connect**
   - **Share on LinkedIn**
   - **LinkedIn Profile API**

## Step 4: Get Your Credentials

1. Go to "Auth" tab
2. Copy your **Client ID** and **Client Secret**
3. Note your **App ID** for the redirect URL

## Step 5: Update Your App Configuration

1. Open `lib/services/linkedin_service.dart`
2. Replace the placeholder values:

```dart
static const String _clientId = 'YOUR_ACTUAL_CLIENT_ID';
static const String _clientSecret = 'YOUR_ACTUAL_CLIENT_SECRET';
static const String _redirectUrl = 'https://www.linkedin.com/developers/apps/YOUR_ACTUAL_APP_ID/auth';
```

## Step 6: Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following inside the `<application>` tag:

```xml
<activity
    android:name="com.linkedin.android.litr.LinkedInAuthActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https"
              android:host="www.linkedin.com"
              android:path="/developers/apps/YOUR_APP_ID/auth" />
    </intent-filter>
</activity>
```

## Step 7: iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Add the following inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>linkedin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
```

## Step 8: Test the Integration

1. Run your app
2. Go to "My Cards" screen
3. Tap "Connect LinkedIn"
4. Complete the LinkedIn authentication flow
5. Verify that your LinkedIn profile data is imported

## Troubleshooting

### Common Issues:

1. **"Invalid redirect URI"**: Make sure your redirect URL matches exactly what you configured in LinkedIn app
2. **"App not approved"**: Some LinkedIn API products require approval. Use basic profile access for testing
3. **"Scope not granted"**: Make sure you've requested the correct API products in your LinkedIn app

### Testing with Limited Access:

If you don't have full API access, you can test with basic profile information:

```dart
// In _fetchLinkedInProfileData method, you can use mock data for testing
return {
  'email': 'test@example.com',
  'headline': 'Software Engineer',
  'industry': 'Technology',
  'location': 'San Francisco, CA',
  'summary': 'Test profile summary',
  'currentPosition': 'Senior Software Engineer',
  'company': 'Test Company',
  'experience': [],
  'education': [],
  'skills': [],
};
```

## Security Notes

- Never commit your Client Secret to version control
- Use environment variables or secure storage for sensitive credentials
- Implement proper error handling for authentication failures
- Consider implementing token refresh logic for long-term access

## Support

For LinkedIn API issues, refer to:
- [LinkedIn API Documentation](https://docs.microsoft.com/en-us/linkedin/)
- [LinkedIn Developer Support](https://www.linkedin.com/help/linkedin/answer/a1344233)
