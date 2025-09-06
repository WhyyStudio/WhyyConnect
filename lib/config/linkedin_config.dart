/// LinkedIn Configuration
/// 
/// To set up LinkedIn integration:
/// 1. Create a LinkedIn app at https://www.linkedin.com/developers/
/// 2. Get your Client ID, Client Secret, and App ID
/// 3. Replace the values below with your actual credentials
/// 4. Follow the setup guide in LINKEDIN_SETUP.md

class LinkedInConfig {
  // Replace with your actual LinkedIn app Client ID
  static const String clientId = '86gqj8q8q8q8q8'; // Example - replace with your actual Client ID
  
  // Replace with your actual LinkedIn app Client Secret
  static const String clientSecret = 'YOUR_LINKEDIN_CLIENT_SECRET'; // Replace with your actual Client Secret
  
  // Replace YOUR_APP_ID with your actual LinkedIn app ID
  static const String redirectUrl = 'https://www.linkedin.com/developers/apps/YOUR_APP_ID/auth'; // Replace with your actual redirect URL
  
  // LinkedIn API endpoints
  static const String profileApiUrl = 'https://api.linkedin.com/v2/people/~';
  static const String emailApiUrl = 'https://api.linkedin.com/v2/emailAddress';
  static const String positionsApiUrl = 'https://api.linkedin.com/v2/people/~:(positions)';
  
  // Required scopes for LinkedIn API access
  static const List<String> requiredScopes = [
    'r_liteprofile',
    'r_emailaddress',
    'w_member_social',
  ];
  
  // Check if configuration is properly set up
  static bool get isConfigured {
    return clientId != 'YOUR_LINKEDIN_CLIENT_ID' &&
           clientId != '86gqj8q8q8q8q8' && // Remove example client ID
           clientSecret != 'YOUR_LINKEDIN_CLIENT_SECRET' &&
           redirectUrl.contains('YOUR_APP_ID') == false;
  }
  
  // Get configuration status message
  static String get configurationStatus {
    if (isConfigured) {
      return 'LinkedIn configuration is properly set up';
    } else {
      return 'LinkedIn configuration needs to be completed. Please update lib/config/linkedin_config.dart with your LinkedIn app credentials.';
    }
  }
}
