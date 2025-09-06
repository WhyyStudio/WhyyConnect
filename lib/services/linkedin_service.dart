import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import '../config/linkedin_config.dart';

class LinkedInService {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authenticate with LinkedIn and fetch user data
  Future<LinkedInUserData?> authenticateAndFetchData(BuildContext context) async {
    try {
      // Check if LinkedIn is properly configured
      if (!LinkedInConfig.isConfigured) {
        _showConfigurationError(context);
        return null;
      }

      // Start real LinkedIn OAuth flow
      final authCode = await _startLinkedInOAuth(context);
      if (authCode == null) {
        return null;
      }

      // Exchange authorization code for access token
      final accessToken = await _exchangeCodeForToken(authCode);
      if (accessToken == null) {
        _showErrorDialog(context, 'Failed to get access token from LinkedIn');
        return null;
      }

      // Fetch user profile data
      final profileData = await _fetchLinkedInProfileData(accessToken);
      if (profileData == null) {
        _showErrorDialog(context, 'Failed to fetch LinkedIn profile data');
        return null;
      }

      // Create LinkedIn user data
      final linkedInData = LinkedInUserData(
        id: profileData['id'] ?? '',
        firstName: profileData['firstName'] ?? '',
        lastName: profileData['lastName'] ?? '',
        email: profileData['email'] ?? '',
        profilePicture: profileData['profilePicture'] ?? '',
        headline: profileData['headline'] ?? '',
        industry: profileData['industry'] ?? '',
        location: profileData['location'] ?? '',
        summary: profileData['summary'] ?? '',
        currentPosition: profileData['currentPosition'] ?? '',
        company: profileData['company'] ?? '',
        experience: profileData['experience'] ?? [],
        education: profileData['education'] ?? [],
        skills: profileData['skills'] ?? [],
        accessToken: accessToken,
        linkedInProfile: 'https://www.linkedin.com/in/${profileData['id']}',
      );

      // Store LinkedIn data in Firestore
      await _storeLinkedInData(linkedInData);
      
      return linkedInData;
    } catch (e) {
      print('LinkedIn authentication error: $e');
      _showErrorDialog(context, 'LinkedIn authentication failed: $e');
      return null;
    }
  }

  // Start LinkedIn OAuth flow
  Future<String?> _startLinkedInOAuth(BuildContext context) async {
    try {
      // Generate state parameter for CSRF protection
      final state = _generateRandomString(32);
      
      // Build LinkedIn authorization URL
      final authUrl = Uri.parse(
        'https://www.linkedin.com/oauth/v2/authorization'
        '?response_type=code'
        '&client_id=${LinkedInConfig.clientId}'
        '&redirect_uri=${Uri.encodeComponent(LinkedInConfig.redirectUrl)}'
        '&state=$state'
        '&scope=${Uri.encodeComponent('r_liteprofile r_emailaddress')}'
      );

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Launch LinkedIn authorization URL
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show instruction dialog
        return await _showAuthInstructionDialog(context, state);
      } else {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'Could not launch LinkedIn authorization');
        return null;
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('LinkedIn OAuth error: $e');
      return null;
    }
  }

  // Show instruction dialog for user to complete OAuth
  Future<String?> _showAuthInstructionDialog(BuildContext context, String state) async {
    final TextEditingController codeController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete LinkedIn Authorization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please complete the LinkedIn authorization in your browser.'),
            const SizedBox(height: 16),
            const Text('After authorization, LinkedIn will redirect you to a URL.'),
            const SizedBox(height: 8),
            const Text('Copy the "code" parameter from the URL and paste it below:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Authorization Code',
                hintText: 'Paste the code from LinkedIn here',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop(code);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Exchange authorization code for access token
  Future<String?> _exchangeCodeForToken(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.linkedin.com/oauth/v2/accessToken'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': LinkedInConfig.redirectUrl,
          'client_id': LinkedInConfig.clientId,
          'client_secret': LinkedInConfig.clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        print('Token exchange failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Token exchange error: $e');
      return null;
    }
  }

  // Fetch LinkedIn profile data using access token
  Future<Map<String, dynamic>?> _fetchLinkedInProfileData(String accessToken) async {
    try {
      // Fetch basic profile info
      final profileResponse = await http.get(
        Uri.parse('https://api.linkedin.com/v2/people/~:(id,firstName,lastName,headline,industry,location,summary)'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Restli-Protocol-Version': '2.0.0',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        
        // Fetch email address
        final emailResponse = await http.get(
          Uri.parse('https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'X-Restli-Protocol-Version': '2.0.0',
          },
        );

        String email = '';
        if (emailResponse.statusCode == 200) {
          final emailData = json.decode(emailResponse.body);
          if (emailData['elements'] != null && emailData['elements'].isNotEmpty) {
            email = emailData['elements'][0]['handle~']['emailAddress'] ?? '';
          }
        }

        // Fetch current position
        final positionResponse = await http.get(
          Uri.parse('https://api.linkedin.com/v2/people/~:(positions)'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'X-Restli-Protocol-Version': '2.0.0',
          },
        );

        String currentPosition = '';
        String company = '';
        if (positionResponse.statusCode == 200) {
          final positionData = json.decode(positionResponse.body);
          if (positionData['positions'] != null && positionData['positions']['values'] != null) {
            final positions = positionData['positions']['values'] as List;
            if (positions.isNotEmpty) {
              final currentPos = positions.first;
              currentPosition = currentPos['title'] ?? '';
              company = currentPos['companyName'] ?? '';
            }
          }
        }

        return {
          'id': profileData['id'] ?? '',
          'firstName': profileData['firstName']?['localized']?['en_US'] ?? '',
          'lastName': profileData['lastName']?['localized']?['en_US'] ?? '',
          'email': email,
          'headline': profileData['headline'] ?? '',
          'industry': profileData['industry'] ?? '',
          'location': profileData['location']?['name'] ?? '',
          'summary': profileData['summary'] ?? '',
          'currentPosition': currentPosition,
          'company': company,
          'profilePicture': '', // LinkedIn API v2 doesn't provide profile pictures easily
          'experience': [],
          'education': [],
          'skills': [],
        };
      }
      
      return null;
    } catch (e) {
      print('Error fetching LinkedIn profile data: $e');
      return null;
    }
  }

  // Generate random string for state parameter
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Show configuration error dialog
  void _showConfigurationError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LinkedIn Configuration Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LinkedIn integration is not properly configured.'),
            const SizedBox(height: 16),
            const Text('To set up LinkedIn integration:'),
            const SizedBox(height: 8),
            const Text('1. Create a LinkedIn app at https://www.linkedin.com/developers/'),
            const Text('2. Get your Client ID, Client Secret, and App ID'),
            const Text('3. Update lib/config/linkedin_config.dart'),
            const Text('4. Follow the setup guide in LINKEDIN_SETUP.md'),
            const SizedBox(height: 16),
            Text(
              LinkedInConfig.configurationStatus,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LinkedIn Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  // Store LinkedIn data in Firestore
  Future<void> _storeLinkedInData(LinkedInUserData userData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final cardData = {
        'cardType': 'LinkedIn',
        'cardColor': 'diamond', // Default color for LinkedIn cards
        'name': '${userData.firstName} ${userData.lastName}',
        'firstName': userData.firstName,
        'lastName': userData.lastName,
        'email': userData.email,
        'profilePicture': userData.profilePicture,
        'headline': userData.headline,
        'industry': userData.industry,
        'location': userData.location,
        'summary': userData.summary,
        'currentPosition': userData.currentPosition,
        'company': userData.company,
        'linkedInProfile': 'https://www.linkedin.com/in/${userData.id}',
        'experience': userData.experience,
        'education': userData.education,
        'skills': userData.skills,
        'linkedInId': userData.id,
        'accessToken': userData.accessToken,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'LinkedIn',
        'isLinkedInCard': true,
      };

      // Store in user's cards collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .add(cardData);

      // Also store in top-level cards collection for home screen queries
      await _firestore
          .collection('cards')
          .add({
            ...cardData,
            'userId': user.uid,
          });

      print('LinkedIn data stored successfully');
    } catch (e) {
      print('Error storing LinkedIn data: $e');
      rethrow;
    }
  }

  // Create a shareable LinkedIn card
  Map<String, dynamic> createShareableLinkedInCard(LinkedInUserData userData) {
    return {
      'cardId': 'linkedin_${userData.id}_${DateTime.now().millisecondsSinceEpoch}',
      'cardType': 'LinkedIn',
      'name': '${userData.firstName} ${userData.lastName}',
      'company': userData.company,
      'email': userData.email,
      'phone': '', // LinkedIn doesn't provide phone numbers
      'website': userData.linkedInProfile ?? '',
      'address': userData.location,
      'position': userData.currentPosition,
      'cardColor': 'diamond',
      'social': {
        'linkedin': userData.linkedInProfile ?? '',
        'instagram': '',
        'facebook': '',
        'twitter': '',
        'behance': '',
        'pinterest': '',
      },
      'linkedInData': {
        'headline': userData.headline,
        'industry': userData.industry,
        'summary': userData.summary,
        'experience': userData.experience,
        'education': userData.education,
        'skills': userData.skills,
        'profilePicture': userData.profilePicture,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'source': 'LinkedIn',
    };
  }

}

// LinkedIn user data model
class LinkedInUserData {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String profilePicture;
  final String headline;
  final String industry;
  final String location;
  final String summary;
  final String currentPosition;
  final String company;
  final List<Map<String, dynamic>> experience;
  final List<Map<String, dynamic>> education;
  final List<String> skills;
  final String accessToken;
  final String? linkedInProfile;

  LinkedInUserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profilePicture,
    required this.headline,
    required this.industry,
    required this.location,
    required this.summary,
    required this.currentPosition,
    required this.company,
    required this.experience,
    required this.education,
    required this.skills,
    required this.accessToken,
    this.linkedInProfile,
  });
}