import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_verification/face_verification.dart';

/// Screen for capturing 3 face verification images during student registration.
/// Each image is captured with different head positions for better matching accuracy.
class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  static const Color primaryColor = Color(0xFF5B8A72);

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing camera...';

  // Captured images for face verification
  final List<File> _capturedImages = [];

  // Current capture step (0, 1, 2)
  int _currentStep = 0;

  // Track validation failures to offer skip option
  int _validationFailCount = 0;

  // Instructions for each capture step
  final List<String> _instructions = [
    'Look straight at the camera',
    'Turn your head slightly to the LEFT',
    'Turn your head slightly to the RIGHT',
  ];

  final List<IconData> _stepIcons = [
    Icons.person,
    Icons.arrow_back,
    Icons.arrow_forward,
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusMessage = 'No camera available');
        return;
      }

      // Use front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = _instructions[_currentStep];
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing...';
    });

    try {
      // Capture image
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      setState(() => _statusMessage = 'Validating face...');
      debugPrint('DEBUG: Captured image at ${photo.path}');

      // Validate: Check if exactly ONE face is detected using face_verification
      // We do this by trying to register the face - it will throw specific errors
      // for "no face" or "multiple faces"
      bool isValid = false;
      String validationError = '';

      try {
        // Use a temporary ID for validation
        final tempId =
            'temp_validation_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('DEBUG: Attempting face registration with tempId: $tempId');
        await FaceVerification.instance.registerFromImagePath(
          id: tempId,
          imagePath: photo.path,
          imageId: 'validation',
        );
        // If we get here, registration succeeded - exactly 1 face detected
        isValid = true;
        debugPrint('DEBUG: Face registration succeeded!');
        // Clean up the temporary registration
        try {
          await FaceVerification.instance.deleteRecord(tempId);
        } catch (_) {}
      } catch (e) {
        debugPrint('DEBUG: Face registration failed with error: $e');
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('multiple') || errorStr.contains('faces')) {
          validationError =
              'Multiple faces detected! Please ensure only YOU are in the frame.';
        } else if (errorStr.contains('no face') ||
            errorStr.contains('noface')) {
          validationError =
              'No face detected. Please position your face clearly in the frame.';
          _validationFailCount++;
        } else {
          // For unknown errors, allow image to be captured (validation may not be supported)
          debugPrint('DEBUG: Unknown error, accepting image anyway');
          isValid = true;
        }
      }

      // After 3 failed attempts, offer to skip validation
      if (!isValid && _validationFailCount >= 3) {
        if (mounted) {
          final shouldSkip = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Face Detection Issue'),
              content: const Text(
                'Face detection is having trouble. Would you like to skip validation and capture the photo anyway?\n\n'
                'Note: This may cause issues during attendance verification later.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Try Again'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Skip Validation'),
                ),
              ],
            ),
          );

          if (shouldSkip == true) {
            isValid = true;
            _validationFailCount = 0;
          }
        }
      }

      if (!isValid) {
        // Show error and let user retry
        setState(() {
          _isProcessing = false;
          _statusMessage = validationError.isNotEmpty
              ? validationError
              : 'Please try again';
        });

        // Show a snackbar with the error
        if (mounted && validationError.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$validationError (Attempt ${_validationFailCount}/3)',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Face validated successfully - save and continue
      _capturedImages.add(imageFile);

      // Move to next step or complete
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
          _isProcessing = false;
          _statusMessage = _instructions[_currentStep];
        });

        // Show success indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image ${_currentStep} captured! ${3 - _currentStep} remaining.',
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // All 3 images captured - return results
        setState(() {
          _isProcessing = false;
          _statusMessage = 'All images captured!';
        });

        // Return results to signup screen
        // Note: We don't extract descriptors here because the face_verification package
        // doesn't expose that method. The camera app will handle verification by
        // downloading and registering the images.
        if (mounted) {
          Navigator.pop(context, {
            'images': _capturedImages,
            'descriptors': <List<double>>[], // Empty - camera app handles this
          });
        }
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Capture failed. Please try again.';
      });
    }
  }

  void _retakeLastImage() {
    if (_capturedImages.isEmpty) return;

    setState(() {
      _capturedImages.removeLast();
      _currentStep = _capturedImages.length;
      _statusMessage = _instructions[_currentStep];
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Face Verification'),
        actions: [
          if (_capturedImages.isNotEmpty)
            TextButton.icon(
              onPressed: _retakeLastImage,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retake',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _cameraController != null)
            Center(child: CameraPreview(_cameraController!))
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Face Frame Overlay
          Center(
            child: Container(
              height: 280,
              width: 220,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.yellow : primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Center(
              child: Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // Progress Indicator (Top)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: _buildProgressIndicator(),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Column(
                children: [
                  // Current instruction with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _stepIcons[_currentStep],
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Captured images preview
                  if (_capturedImages.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < _capturedImages.length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                _capturedImages[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        // Empty placeholders for remaining captures
                        for (int i = _capturedImages.length; i < 3; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey, width: 2),
                              color: Colors.grey.shade800,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Capture Button
                  if (_isInitialized && !_isProcessing)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _captureImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Capture Image ${_currentStep + 1} of 3',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
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
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isCompleted = index < _capturedImages.length;
        final isCurrent = index == _currentStep;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? primaryColor
                      : isCurrent
                      ? Colors.white
                      : Colors.grey.shade700,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent ? primaryColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < 2)
                Container(
                  width: 30,
                  height: 2,
                  color: isCompleted ? primaryColor : Colors.grey.shade700,
                ),
            ],
          ),
        );
      }),
    );
  }
}
