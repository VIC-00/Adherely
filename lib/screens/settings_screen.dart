import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../models.dart';
import '../theme/app_colors.dart';
import '../widgets/success_overlay.dart';
import 'reminders_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _conditionsController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback so context.read is safe after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<SettingsProvider>().profile;

      _nameController.text = profile?.name ?? '';
      _conditionsController.text = profile?.conditions ?? '';

      if (profile?.dob != null && profile!.dob.isNotEmpty) {
        // Try both the current canonical format and common legacy formats
        final formats = [
          DateFormat('MMM dd, yyyy'), // canonical
          DateFormat('MMM d, yyyy'),  // no leading-zero day
          DateFormat('yyyy-MM-dd'),   // ISO (possible old format)
        ];
        for (final fmt in formats) {
          try {
            final parsed = fmt.parse(profile.dob, true);
            setState(() {
              _selectedDate = parsed;
              _dobController.text = DateFormat('MMM dd, yyyy').format(parsed);
            });
            break;
          } catch (_) {}
        }
        // If none matched, keep the raw text so it's visible
        // but _selectedDate stays null — the validator will reject a save
        if (_selectedDate == null) {
          _dobController.text = profile.dob;
        }
      }
    });

    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _conditionsController = TextEditingController();
  }

  @override
  void dispose() {
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: const Color(0xFF7C3AED),
                    onPrimary: Colors.white,
                    surface: AppColors.cardBg,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: const Color(0xFF7C3AED),
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

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink900),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.hairline,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Navigation to Notification Hub Card
              _buildNavigationCard(
                title: 'Notification Hub',
                subtitle: 'Manage medication schedules and reminders',
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Title Header
              Text(
                'PERSONAL INFORMATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Form fields card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'e.g. John Doe',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      hint: 'Click to select',
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Date of birth is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _conditionsController,
                      label: 'Health Conditions',
                      hint: 'e.g. Hypertension, Diabetes (optional)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Changes button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedProfile = Profile(
                      id: 1,
                      name: _nameController.text.trim(),
                      // Always derive from _selectedDate to guarantee
                      // the format is canonical ('MMM dd, yyyy') on every save
                      dob: _selectedDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                          : _dobController.text.trim(),
                      conditions: _conditionsController.text.trim().isEmpty
                          ? 'None'
                          : _conditionsController.text.trim(),
                    );
                    settingsState.updateProfile(updatedProfile);
                    SuccessOverlay.show(
                      context: context,
                      title: 'Profile Updated',
                      message: 'Your personal settings were updated successfully.',
                      icon: Icons.person_rounded,
                      gradientColors: const [
                        Color(0xFF7C3AED),
                        Color(0xFF8B5CF6),
                      ],
                      titleColor: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ink500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: TextStyle(fontSize: 14, color: AppColors.ink900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.ink400),
            filled: true,
            fillColor: AppColors.isDark ? AppColors.screenBg : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
