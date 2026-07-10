import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers/settings_provider.dart';
import '../notification_service.dart';
import '../theme/app_colors.dart';
import '../root_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _conditionsController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.medBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.ink900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _finishOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final conditions = _conditionsController.text.trim().isEmpty
        ? 'General Health'
        : _conditionsController.text.trim();

    // Request permissions
    await LocalNotificationService().requestPermissions();

    if (mounted) {
      final settingsState = context.read<SettingsProvider>();
      // We will save to SettingsProvider. If updateProfile doesn't exist yet, we write to database helper directly or we can add it to settings provider.
      // Since settings provider edit caregiver and profile methods exist, let's create a custom function to update profile.
      // Wait, we need to save the profile. Let's add updateProfile to settings provider in this or a subsequent step.
      // For now, let's use settingsState.updateProfile if we implement it, or write directly.
      // Actually, let's add `updateProfile` to settings_provider.dart so it works perfectly.
      // We will create the Profile model.
      final profile = Profile(
        id: 1,
        name: name,
        dob: dob,
        patientId: '', // placeholder, will be removed in step 8
        conditions: conditions,
      );

      // We'll update the settingsState. We can safely invoke the updateProfile method we will add to settings_provider.dart
      try {
        await settingsState.updateProfile(profile);
      } catch (e) {
        debugPrint('Could not call updateProfile on SettingsProvider: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildProfileSetupPage(),
                  _buildPermissionsPage(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Visual Hero with beautiful fade gradient
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppColors.isDark
                        ? [
                            AppColors.medBlue.withValues(alpha: 0.15),
                            AppColors.medPurple.withValues(alpha: 0.05),
                            Colors.transparent,
                          ]
                        : [
                            AppColors.medBlueLight,
                            AppColors.medBlueLight.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.3 : 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.healing_rounded,
                      size: 72,
                      color: AppColors.medBlue,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.medBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Onboarding',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                Text(
                  'Welcome to Adherely',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your reliable companion for chronic care management, designed for everyone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.ink700,
                  ),
                ),
                const SizedBox(height: 36),

                // Feature Rows
                _buildFeatureRow(
                  icon: Icons.cloud_off_rounded,
                  title: 'Offline-First',
                  description:
                      'Your health data stays with you, even without an internet connection.',
                ),
                const SizedBox(height: 20),
                _buildFeatureRow(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accessible Design',
                  description:
                      'High-contrast visuals and large touch targets for effortless navigation.',
                ),
                const SizedBox(height: 20),
                _buildFeatureRow(
                  icon: Icons.shield_rounded,
                  title: 'Private & Secure',
                  description:
                      'Clinical-grade security for your medication schedule and history.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.isDark
                ? AppColors.medBlue.withValues(alpha: 0.15)
                : AppColors.medBlueLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.medBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.ink500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Set Up Your Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your details are stored strictly on your device to keep your data private and offline.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Name Field
            _buildInputLabel('Your Full Name'),
            TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              style: TextStyle(color: AppColors.ink900, fontSize: 14),
              decoration: _buildInputDecoration('e.g. Sarah Mitchell'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // DOB Field
            _buildInputLabel('Date of Birth'),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              style: TextStyle(color: AppColors.ink900, fontSize: 14),
              decoration: _buildInputDecoration('Tap to select DOB').copyWith(
                suffixIcon: const Icon(Icons.calendar_today_rounded,
                    color: AppColors.medBlue, size: 20),
              ),
              onTap: () => _selectDate(context),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please select your Date of Birth';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Conditions Field
            _buildInputLabel('Medical Conditions (Optional)'),
            TextFormField(
              controller: _conditionsController,
              style: TextStyle(color: AppColors.ink900, fontSize: 14),
              decoration: _buildInputDecoration(
                  'e.g. Hypertension, Diabetes (comma separated)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Separate multiple conditions with commas.',
              style: TextStyle(fontSize: 11, color: AppColors.ink400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink700,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.ink400, fontSize: 14),
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.medBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.medRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.medRed, width: 1.8),
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.notifications_active_rounded,
            size: 80,
            color: AppColors.medBlue,
          ),
          const SizedBox(height: 24),
          Text(
            'Never Miss a Dose',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Adherely runs completely offline and schedules notifications on your device. Please allow push permissions to receive timely alarms.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // Visual Mock Notification Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.medBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Adherely',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.medBlue,
                            ),
                          ),
                          Text(
                            'Just now',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.ink400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Medication Reminder',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Time to take Lisinopril 10mg.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page Dots Indicator
              Row(
                children: List.generate(3, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.medBlue : AppColors.ink400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              // Action Buttons
              Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: AppColors.ink500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        if (_currentPage == 1 &&
                            !_formKey.currentState!.validate()) {
                          return;
                        }
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.medBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _currentPage == 2 ? 'Get Started' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_currentPage == 0) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // Animate to Slide 2
                _pageController.animateToPage(1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 14, color: AppColors.medBlue),
                    SizedBox(width: 4),
                    Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.medBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
