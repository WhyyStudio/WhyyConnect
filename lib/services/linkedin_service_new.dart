import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedin_login/linkedin_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/linkedin_config.dart';

class LinkedInService {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authenticate with LinkedIn and fetch user data
  Future<LinkedInUserData?> authenticateAndFetchData(BuildContext context) async {
    try {
      // Check if LinkedIn is properly configured
      if (!LinkedInConfig.isConfigured) {
        // Show demo mode option
        final useDemo = await _showDemoModeDialog(context);
        if (useDemo == true) {
          return _createDemoLinkedInData();
        }
        return null;
      }

      // Show LinkedIn login dialog
      final result = await showDialog<LinkedInUserModel?>(
        context: context,
        builder: (context) => LinkedInAuthCodeLogin(
          redirectUrl: LinkedInConfig.redirectUrl,
          clientId: LinkedInConfig.clientId,
          clientSecret: LinkedInConfig.clientSecret,
          projection: [
            ProjectionParameters.id,
            ProjectionParameters.firstName,
            ProjectionParameters.lastName,
            ProjectionParameters.profilePicture,
          ],
          onGetUserProfile: (LinkedInUserModel user) async {
            Navigator.of(context).pop(user);
          },
          onError: (LinkedInAuthException error) {
            Navigator.of(context).pop();
            print('LinkedIn Auth Error: ${error.toString()}');
          },
        ),
      );

      if (result == null) {
        return null;
      }

      // Fetch additional profile data using the access token
      final profileData = await _fetchLinkedInProfileData(result.token.accessToken);
      
      // Create LinkedIn user data
      final linkedInData = LinkedInUserData(
        id: result.userId ?? '',
        firstName: result.firstName?.localized?.label ?? '',
        lastName: result.lastName?.localized?.label ?? '',
        email: profileData?['email'] ?? '',
        profilePicture: result.profilePicture?.displayImage?.elements?.last.identifiers?.first.identifier ?? '',
        headline: profileData?['headline'] ?? '',
        industry: profileData?['industry'] ?? '',
        location: profileData?['location'] ?? '',
        summary: profileData?['summary'] ?? '',
        currentPosition: profileData?['currentPosition'] ?? '',
        company: profileData?['company'] ?? '',
        experience: profileData?['experience'] ?? [],
        education: profileData?['education'] ?? [],
        skills: profileData?['skills'] ?? [],
        accessToken: result.token.accessToken,
        linkedInProfile: 'https://www.linkedin.com/in/${result.userId}',
      );

      // Store LinkedIn data in Firestore
      await _storeLinkedInData(linkedInData);
      
      return linkedInData;
    } catch (e) {
      print('LinkedIn authentication error: $e');
      return null;
    }
  }

  // Fetch additional LinkedIn profile data using the access token
  Future<Map<String, dynamic>?> _fetchLinkedInProfileData(String accessToken) async {
    try {
      // Fetch basic profile info
      final profileResponse = await http.get(
        Uri.parse('${LinkedInConfig.profileApiUrl}:(id,firstName,lastName,headline,industry,location,summary)'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Restli-Protocol-Version': '2.0.0',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        
        // Fetch current position
        final positionResponse = await http.get(
          Uri.parse(LinkedInConfig.positionsApiUrl),
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

        // Fetch email address
        final emailResponse = await http.get(
          Uri.parse('${LinkedInConfig.emailApiUrl}?q=members&projection=(elements*(handle~))'),
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

        return {
          'email': email,
          'headline': profileData['headline'] ?? '',
          'industry': profileData['industry'] ?? '',
          'location': profileData['location'] ?? '',
          'summary': profileData['summary'] ?? '',
          'currentPosition': currentPosition,
          'company': company,
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

  // Show demo mode dialog
  Future<bool?> _showDemoModeDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LinkedIn Configuration Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LinkedIn integration is not properly configured.'),
            const SizedBox(height: 16),
            const Text('You can:'),
            const SizedBox(height: 8),
            const Text('• Set up real LinkedIn integration (see setup guide)'),
            const Text('• Use demo mode to test the feature'),
            const SizedBox(height: 16),
            const Text(
              'Demo mode will create a sample LinkedIn profile for testing purposes.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use Demo Mode'),
          ),
        ],
      ),
    );
  }

  // Create demo LinkedIn data for testing
  Future<LinkedInUserData> _createDemoLinkedInData() async {
    final demoData = LinkedInUserData(
      id: 'demo_linkedin_id_${DateTime.now().millisecondsSinceEpoch}',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      profilePicture: '',
      headline: 'Senior Software Engineer',
      industry: 'Technology',
      location: 'San Francisco, CA',
      summary: 'Passionate software engineer with 5+ years of experience in mobile development, specializing in Flutter and cross-platform solutions.',
      currentPosition: 'Senior Software Engineer',
      company: 'Tech Innovations Inc.',
      experience: [
        {
          'title': 'Senior Software Engineer',
          'company': 'Tech Innovations Inc.',
          'duration': '2020 - Present',
          'description': 'Leading mobile app development using Flutter and React Native.',
        },
        {
          'title': 'Software Engineer',
          'company': 'StartupXYZ',
          'duration': '2018 - 2020',
          'description': 'Developed and maintained mobile applications for iOS and Android.',
        },
      ],
      education: [
        {
          'school': 'University of Technology',
          'degree': 'Bachelor of Computer Science',
          'year': '2018',
          'field': 'Computer Science',
        },
      ],
      skills: ['Flutter', 'Dart', 'Mobile Development', 'Firebase', 'React Native', 'JavaScript', 'TypeScript'],
      accessToken: 'demo_access_token',
      linkedInProfile: 'https://www.linkedin.com/in/john-doe-demo',
    );

    // Store demo data in Firestore
    await _storeLinkedInData(demoData);
    
    return demoData;
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
