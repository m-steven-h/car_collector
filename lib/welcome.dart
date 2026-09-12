import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'models/app_model.dart';
import 'localized/localized.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToProfile() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF5F5F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1A0A0C),
                    const Color(0xFF0A0A0C),
                    const Color(0xFF050505),
                  ]
                : [
                    const Color(0xFFF5F5F8),
                    Colors.white,
                    const Color(0xFFF5F5F8),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 900;

              final maxContentWidth = isDesktop
                  ? 560.0
                  : isTablet
                  ? 500.0
                  : double.infinity;

              final content = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SettingsPage(onNext: _goToProfile),
                    _ProfilePage(onBack: _goBack),
                  ],
                ),
              );

              return Center(
                child: isDesktop
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xCC121218)
                              : const Color(0xCCFFFFFF),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2A2A35)
                                : const Color(0xFFE0E0E0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: 40,
                              spreadRadius: 2,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: content,
                        ),
                      )
                    : content,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  final VoidCallback onNext;

  const _SettingsPage({required this.onNext});

  static const Color _primaryRed = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 600;
        final headerTop = isCompact ? 16.0 : 24.0;
        final titleSize = isCompact ? 26.0 : 34.0;
        final minHeight = constraints.maxHeight > 500
            ? constraints.maxHeight * 0.55
            : 280.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: headerTop, left: 24, right: 24),
              child: Column(
                children: [
                  Text(
                    lang == 'ar' ? 'الإعدادات' : 'Settings',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryRed, Color(0xFFB00710)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isCompact ? 16 : 32),
                        _buildSectionTitle(
                          icon: Icons.language_outlined,
                          title: AppLocalizations.get('language', lang),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildLanguageSelector(appState, isDark),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          icon: Icons.palette_outlined,
                          title: AppLocalizations.get('theme', lang),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildThemeSelector(appState, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onNext,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryRed, Color(0xFFB00710)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lang == 'ar' ? 'التالي' : 'Next',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(AppState appState, bool isDark) {
    final lang = appState.language;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFE0E0E0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageOption(
              label: 'English',
              flag: '🇬🇧',
              isSelected: lang == 'en',
              onTap: () => appState.setLanguage('en'),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildLanguageOption(
              label: 'العربية',
              flag: '🇸🇦',
              isSelected: lang == 'ar',
              onTap: () => appState.setLanguage('ar'),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_primaryRed, Color(0xFFB00710)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF1E1E28) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _primaryRed
                  : (isDark
                        ? const Color(0xFF2A2A35)
                        : const Color(0xFFE0E0E0)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AppState appState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFE0E0E0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildThemeOption(
              label: AppLocalizations.get('dark', appState.language),
              icon: Icons.nightlight_round,
              isSelected: appState.themeMode == ThemeMode.dark,
              onTap: () => appState.setThemeMode(ThemeMode.dark),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildThemeOption(
              label: AppLocalizations.get('light', appState.language),
              icon: Icons.wb_sunny_rounded,
              isSelected: appState.themeMode == ThemeMode.light,
              onTap: () => appState.setThemeMode(ThemeMode.light),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildThemeOption(
              label: AppLocalizations.get('system', appState.language),
              icon: Icons.android,
              isSelected: appState.themeMode == ThemeMode.system,
              onTap: () => appState.setThemeMode(ThemeMode.system),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_primaryRed, Color(0xFFB00710)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF1E1E28) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _primaryRed
                  : (isDark
                        ? const Color(0xFF2A2A35)
                        : const Color(0xFFE0E0E0)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  final VoidCallback onBack;

  const _ProfilePage({required this.onBack});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? _selectedImagePath;
  bool _isPicking = false;

  static const Color _primaryRed = Color(0xFFE50914);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _pickAndSaveUserImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Maximum 5 MB.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      if (kIsWeb) {
        final base64Image = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64Image';
      } else {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final userDir = Directory('${appDir.path}/user_images');
          if (!await userDir.exists()) {
            await userDir.create(recursive: true);
          }
          final fileName = 'user_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = File('${userDir.path}/$fileName');
          await savedImage.writeAsBytes(bytes);
          return savedImage.path;
        } catch (e) {
          debugPrint('Error saving user image: $e');
          return pickedFile.path;
        }
      }
    } catch (e) {
      debugPrint('Error picking user image: $e');
      return null;
    }
  }

  /// ✅ فتح معرض الصور مباشرة بدون إظهار خيارات
  /// على الويب: معرض الصور
  /// على الجوال: الكاميرا (يمكنك تغييرها إلى gallery إذا أردت)
  Future<void> _pickImageDirectly() async {
    setState(() => _isPicking = true);

    // على الويب نستخدم المعرض، على الجوال نستخدم الكاميرا
    final source = ImageSource.gallery;
    final path = await _pickAndSaveUserImage(source);

    if (!mounted) return;
    setState(() {
      if (path != null) _selectedImagePath = path;
      _isPicking = false;
    });
  }

  void _handleStart(AppState appState) async {
    if (_formKey.currentState!.validate()) {
      await appState.setUsername(_controller.text.trim());
      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
        await appState.setUserImage(_selectedImagePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF5F5F8);
    final cardColor = isDark
        ? const Color(0xFF181820)
        : const Color(0xFFFFFFFF);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark
        ? const Color(0xFF2A2A35)
        : const Color(0xFFE0E0E0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 600;
        final headerTop = isCompact ? 16.0 : 24.0;
        final titleSize = isCompact ? 26.0 : 34.0;
        final avatarSize = isCompact ? 110.0 : 144.0;
        final avatarIconSize = isCompact ? 56.0 : 72.0;
        final minHeight = constraints.maxHeight > 500
            ? constraints.maxHeight * 0.55
            : 280.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: headerTop, left: 24, right: 24),
              child: Column(
                children: [
                  Text(
                    lang == 'ar' ? 'بياناتك' : 'Your Info',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryRed, Color(0xFFB00710)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isCompact ? 16 : 28),
                          MouseRegion(
                            cursor: _isPicking
                                ? SystemMouseCursors.basic
                                : SystemMouseCursors.click,
                            child: GestureDetector(
                              // ✅ الضغط على الصورة يفتح المعرض مباشرة
                              onTap: _isPicking ? null : _pickImageDirectly,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          _primaryRed,
                                          Color(0xFFB00710),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryRed.withOpacity(0.5),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _isPicking
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : _buildUserImageWithSize(
                                              avatarIconSize,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            _primaryRed,
                                            Color(0xFFB00710),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: bgColor,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryRed.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _controller,
                            style: TextStyle(color: textColor, fontSize: 16),
                            textAlign: TextAlign.start,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.get('username', lang),
                              hintStyle: TextStyle(
                                color: subTextColor,
                                fontSize: 15,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: _primaryRed,
                                size: 22,
                              ),
                              filled: true,
                              fillColor: cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: borderColor,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: _primaryRed,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                              errorStyle: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? AppLocalizations.get('fill_required', lang)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: TextButton.icon(
                      onPressed: widget.onBack,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: subTextColor,
                      ),
                      label: Text(
                        lang == 'ar' ? 'رجوع' : 'Back',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _handleStart(appState),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryRed, Color(0xFFB00710)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.get('start_collecting', lang),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // نسخة معدلة من _buildUserImage تدعم حجم ديناميكي للأيقونة
  Widget _buildUserImageWithSize(double iconSize) {
    if (_selectedImagePath == null || _selectedImagePath!.isEmpty) {
      return Icon(
        Icons.person_outline_rounded,
        size: iconSize,
        color: Colors.white,
      );
    }

    try {
      if (_selectedImagePath!.startsWith('data:')) {
        return Image.network(
          _selectedImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.person_outline_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(_selectedImagePath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person_outline_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          );
        }
      }

      return Icon(
        Icons.person_outline_rounded,
        size: iconSize,
        color: Colors.white,
      );
    } catch (e) {
      return Icon(
        Icons.person_outline_rounded,
        size: iconSize,
        color: Colors.white,
      );
    }
  }
}
