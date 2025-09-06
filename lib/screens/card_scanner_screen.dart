import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/card_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String _permissionStatus = 'checking';
  
  // Card scanning state
  String _currentSide = 'front'; // 'front' or 'back'
  XFile? _frontImage;
  XFile? _backImage;
  String? _frontText;
  String? _backText;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      
      // For Android 13+ (API 33+), we need different storage permissions
      PermissionStatus storageStatus;
      if (Platform.isAndroid) {
        // Try photos permission first (Android 13+)
        storageStatus = await Permission.photos.status;
        // If photos permission is not available, fall back to storage
        if (storageStatus == PermissionStatus.denied) {
          storageStatus = await Permission.storage.status;
        }
      } else {
        storageStatus = await Permission.storage.status;
      }
      
      print('Camera permission status: $cameraStatus');
      print('Storage permission status: $storageStatus');
      
      if (cameraStatus.isGranted && storageStatus.isGranted) {
        setState(() {
          _hasPermission = true;
          _permissionStatus = 'granted';
        });
        _initializeCamera();
      } else {
        setState(() {
          _permissionStatus = 'denied';
        });
        // Don't automatically request permissions, show UI first
      }
    } catch (e) {
      setState(() {
        _permissionStatus = 'error';
      });
      print('Error checking permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('Requesting camera and storage permissions...');
      
      final cameraStatus = await Permission.camera.request();
      
      // For Android 13+ (API 33+), we need different storage permissions
      PermissionStatus storageStatus;
      if (Platform.isAndroid) {
        // Try photos permission first (Android 13+)
        storageStatus = await Permission.photos.request();
        // If photos permission is not available, fall back to storage
        if (storageStatus == PermissionStatus.denied) {
          storageStatus = await Permission.storage.request();
        }
      } else {
        // Use storage permission for iOS
        storageStatus = await Permission.storage.request();
      }
      
      print('Camera permission result: $cameraStatus');
      print('Storage permission result: $storageStatus');
      
      if (cameraStatus.isGranted && storageStatus.isGranted) {
        setState(() {
          _hasPermission = true;
          _permissionStatus = 'granted';
        });
        _initializeCamera();
      } else if (cameraStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        setState(() {
          _permissionStatus = 'permanently_denied';
        });
        _showSettingsDialog();
      } else {
        setState(() {
          _hasPermission = false;
          _permissionStatus = 'denied';
        });
      }
    } catch (e) {
      setState(() {
        _permissionStatus = 'error';
      });
      print('Error requesting permissions: $e');
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: const Color(0xFFFF3B30), size: 28),
            const SizedBox(width: 12),
            const Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Camera and storage permissions are required to scan business cards. Please enable them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCC61D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _captureCard() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      if (_currentSide == 'front') {
        _frontImage = image;
        _frontText = await _extractTextFromImage(image);
        setState(() {
          _currentSide = 'back';
        });
      } else {
        _backImage = image;
        _backText = await _extractTextFromImage(image);
        await _saveCardData();
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String> _extractTextFromImage(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }
      
      await textRecognizer.close();
      return extractedText.trim();
    } catch (e) {
      print('Error extracting text: $e');
      return 'Text extraction failed';
    }
  }

  Future<void> _saveCardData() async {
    try {
      // Generate a single cardId for consistency
      final cardId = DateTime.now().millisecondsSinceEpoch.toString();
      final cardsDirPath = await _getCardsDirectory();
      
      final cardData = {
        'frontImagePath': _frontImage?.path,
        'backImagePath': _backImage?.path,
        'frontText': _frontText,
        'backText': _backText,
        'extractedData': _parseCardData(_frontText ?? '', _backText ?? ''),
      };

      // Save images to app directory with consistent naming
      if (_frontImage != null) {
        final frontFile = File('$cardsDirPath/${cardId}_front.jpg');
        await frontFile.writeAsBytes(await _frontImage!.readAsBytes());
        cardData['frontImagePath'] = frontFile.path;
        print('Front image saved to: ${frontFile.path}');
      }
      
      if (_backImage != null) {
        final backFile = File('$cardsDirPath/${cardId}_back.jpg');
        await backFile.writeAsBytes(await _backImage!.readAsBytes());
        cardData['backImagePath'] = backFile.path;
        print('Back image saved to: ${backFile.path}');
      }
      
      // Save card data using storage service
      await CardStorageService.savePhysicalCard(cardData);
      print('Card data saved successfully');
      
    } catch (e) {
      print('Error saving card data: $e');
    }
  }

  Future<String> _getCardsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cardsDir = Directory('${appDir.path}/scanned_cards');
    if (!await cardsDir.exists()) {
      await cardsDir.create(recursive: true);
    }
    return cardsDir.path;
  }



  Map<String, dynamic> _parseCardData(String frontText, String backText) {
    final allText = '$frontText $backText'.toLowerCase();
    
    return {
      'name': _extractName(frontText),
      'company': _extractCompany(allText),
      'email': _extractEmail(allText),
      'phone': _extractPhone(allText),
      'website': _extractWebsite(allText),
      'address': _extractAddress(allText),
      'title': _extractTitle(frontText),
    };
  }

  String _extractName(String text) {
    final lines = text.split('\n');
    for (String line in lines) {
      if (line.trim().isNotEmpty && 
          !line.contains('@') && 
          !line.contains('www') &&
          !line.contains('http') &&
          !RegExp(r'\d{3}[-.]?\d{3}[-.]?\d{4}').hasMatch(line)) {
        return line.trim();
      }
    }
    return 'Unknown';
  }

  String _extractCompany(String text) {
    final companyKeywords = ['inc', 'llc', 'corp', 'ltd', 'company', 'group', 'solutions'];
    final lines = text.split('\n');
    
    for (String line in lines) {
      for (String keyword in companyKeywords) {
        if (line.toLowerCase().contains(keyword)) {
          return line.trim();
        }
      }
    }
    return 'Unknown Company';
  }

  String _extractEmail(String text) {
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final match = emailRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractPhone(String text) {
    final phoneRegex = RegExp(r'(\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})');
    final match = phoneRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractWebsite(String text) {
    final websiteRegex = RegExp(r'(https?://)?(www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final match = websiteRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractAddress(String text) {
    final addressKeywords = ['street', 'st', 'avenue', 'ave', 'road', 'rd', 'drive', 'dr', 'lane', 'ln'];
    final lines = text.split('\n');
    
    for (String line in lines) {
      for (String keyword in addressKeywords) {
        if (line.toLowerCase().contains(keyword)) {
          return line.trim();
        }
      }
    }
    return '';
  }

  String _extractTitle(String text) {
    final titleKeywords = ['manager', 'director', 'ceo', 'president', 'vice', 'senior', 'junior', 'lead', 'head'];
    final lines = text.split('\n');
    
    for (String line in lines) {
      for (String keyword in titleKeywords) {
        if (line.toLowerCase().contains(keyword)) {
          return line.trim();
        }
      }
    }
    return '';
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Card Scanned!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your business card has been successfully scanned and saved.'),
            const SizedBox(height: 16),
            if (_frontText != null) ...[
              Text('Front Text: ${_frontText!.substring(0, _frontText!.length > 50 ? 50 : _frontText!.length)}...'),
              const SizedBox(height: 8),
            ],
            if (_backText != null) ...[
              Text('Back Text: ${_backText!.substring(0, _backText!.length > 50 ? 50 : _backText!.length)}...'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _permissionStatus == 'granted' 
              ? 'Scan ${_currentSide == 'front' ? 'Front' : 'Back'} of Card'
              : 'Camera Permission',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_permissionStatus) {
      case 'checking':
        return _buildPermissionChecking();
      case 'denied':
        return _buildPermissionDenied();
      case 'permanently_denied':
        return _buildPermissionPermanentlyDenied();
      case 'error':
        return _buildPermissionError();
      case 'granted':
        return _isInitialized ? _buildCameraView() : _buildInitializing();
      default:
        return _buildPermissionChecking();
    }
  }

  Widget _buildPermissionChecking() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFCC61D),
          ),
          SizedBox(height: 20),
          Text(
            'Checking permissions...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 50,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To scan business cards, we need access to your camera and storage. Please grant permissions to continue.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC61D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Grant Permissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPermanentlyDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.block,
                size: 50,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permissions Blocked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera and storage permissions have been permanently denied. Please enable them in your device settings to use the card scanner.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC61D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permission Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'There was an error checking camera permissions. Please try again or check your device settings.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC61D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitializing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFCC61D),
          ),
          SizedBox(height: 20),
          Text(
            'Initializing camera...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        
        // Scanning overlay
        Positioned.fill(
          child: CustomPaint(
            painter: CardOverlayPainter(),
          ),
        ),
        
        // Scanning line animation
        if (_isProcessing)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanningLinePainter(_scanAnimation.value),
                );
              },
            ),
          ),
        
        // Instructions
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  _currentSide == 'front' ? Icons.credit_card : Icons.credit_card_outlined,
                  color: const Color(0xFFFCC61D),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _currentSide == 'front' 
                      ? 'Position the front of the card within the frame'
                      : 'Now scan the back of the card',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        // Capture button
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isProcessing ? 0.9 : _pulseAnimation.value,
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _captureCard,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isProcessing 
                            ? Colors.grey 
                            : const Color(0xFFFCC61D),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFCC61D).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Progress indicator
        if (_isProcessing)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Processing...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Card frame (business card size ratio: 3.375:2.125)
    final cardWidth = size.width * 0.8;
    final cardHeight = cardWidth * (2.125 / 3.375);
    final cardRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cardWidth,
      height: cardHeight,
    );

    // Draw card frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
      paint,
    );

    // Draw corner indicators
    final cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFFFCC61D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Top-left corner
    canvas.drawLine(
      Offset(cardRect.left, cardRect.top + cornerLength),
      Offset(cardRect.left, cardRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.left, cardRect.top),
      Offset(cardRect.left + cornerLength, cardRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cardRect.right - cornerLength, cardRect.top),
      Offset(cardRect.right, cardRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.right, cardRect.top),
      Offset(cardRect.right, cardRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cardRect.left, cardRect.bottom - cornerLength),
      Offset(cardRect.left, cardRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.left, cardRect.bottom),
      Offset(cardRect.left + cornerLength, cardRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cardRect.right - cornerLength, cardRect.bottom),
      Offset(cardRect.right, cardRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.right, cardRect.bottom),
      Offset(cardRect.right, cardRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanningLinePainter extends CustomPainter {
  final double progress;

  ScanningLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFCC61D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cardWidth = size.width * 0.8;
    final cardHeight = cardWidth * (2.125 / 3.375);
    final cardRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cardWidth,
      height: cardHeight,
    );

    final lineY = cardRect.top + (cardRect.height * progress);
    
    canvas.drawLine(
      Offset(cardRect.left, lineY),
      Offset(cardRect.right, lineY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
