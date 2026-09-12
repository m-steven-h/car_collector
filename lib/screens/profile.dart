import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';
import 'brands.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  static const double _maxContentWidth = 720;

  Color _textColor(bool isDark) => isDark ? Colors.white : Colors.black87;
  Color _subTextColor(bool isDark) =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

  /// ✅ اختيار صورة المستخدم من معرض/ملفات الجهاز مباشرة (بدون كاميرا)
  Future<String?> _pickAndSaveUserImage(BuildContext context) async {
    final lang = Provider.of<AppState>(context, listen: false).language;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.get('image_too_large_5mb', lang)),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.get('error', lang)}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// ✅ فتح معرض الملفات مباشرة لصورة البروفايل
  Future<void> _pickUserImageDirectly(
    BuildContext context,
    AppState appState,
  ) async {
    final path = await _pickAndSaveUserImage(context);
    if (path != null) {
      await appState.setUserImage(path);
    }
  }

  Widget _buildUserImage(String? imagePath, String? username) {
    if (imagePath == null || imagePath.isEmpty) {
      return _fallbackAvatar(username);
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return ClipOval(
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) =>
                _fallbackAvatar(username),
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipOval(
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  _fallbackAvatar(username),
            ),
          );
        }
      }

      return _fallbackAvatar(username);
    } catch (e) {
      return _fallbackAvatar(username);
    }
  }

  Widget _fallbackAvatar(String? username) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_primaryRed, Color(0xFFB00710)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          (username != null && username.isNotEmpty)
              ? username[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showEditUsernameDialog(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final controller = TextEditingController(text: appState.username);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? _darkCard : _lightCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? _darkBorder : _lightBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _primaryRed.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: _primaryRed,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppLocalizations.get('edit_profile', lang),
                    style: TextStyle(
                      color: _textColor(isDark),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.get('username', lang),
                      labelStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: _primaryRed,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E28)
                          : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? _darkBorder : _lightBorder,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryRed,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            AppLocalizations.get('cancel', lang),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryRed, Color(0xFFB00710)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                appState.setUsername(controller.text.trim());
                                Navigator.pop(ctx);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              AppLocalizations.get('save_changes', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                    : (isDark ? _darkBorder : _lightBorder),
                width: isSelected ? 2 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.4),
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
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
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
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                    : (isDark ? _darkBorder : _lightBorder),
                width: isSelected ? 2 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.4),
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
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? _darkBg : _lightBg;
    final cardColor = isDark ? _darkCard : _lightCard;
    final textCol = _textColor(isDark);
    final subTextColor = _subTextColor(isDark);
    final borderColor = isDark ? _darkBorder : _lightBorder;

    final bottomSpace = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 700;

          return Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 80,
                      bottom: bottomSpace + 100,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      children: [
                        // ============ بطاقة الملف الشخصي ============
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isCompact ? 20 : 24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.2 : 0.06,
                                ),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  // ✅ فتح المعرض مباشرة
                                  onTap: () =>
                                      _pickUserImageDirectly(context, appState),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _primaryRed.withOpacity(0.5),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryRed.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipOval(
                                          child: _buildUserImage(
                                            appState.userImagePath,
                                            appState.username,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                _primaryRed,
                                                Color(0xFFB00710),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cardColor,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _primaryRed.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.photo_library_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      appState.username ?? 'User',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: textCol,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => _showEditUsernameDialog(
                                        context,
                                        appState,
                                        lang,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _primaryRed.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          color: _primaryRed,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ============ بطاقات الإحصائيات ============
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: AppLocalizations.get(
                                  'cars_collected',
                                  lang,
                                ),
                                value: '${appState.cars.length}',
                                icon: Icons.directions_car_rounded,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: AppLocalizations.get(
                                  'brands_added',
                                  lang,
                                ),
                                value: '${appState.brands.length}',
                                icon: Icons.branding_watermark_rounded,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ============ بطاقة الإعدادات ============
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.2 : 0.06,
                                ),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _primaryRed,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.get('settings', lang),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textCol,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: borderColor),

                              // ============ الثيم ============
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _primaryRed.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.palette_outlined,
                                            color: _primaryRed,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.get('theme', lang),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textCol,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _buildThemeOption(
                                          label: AppLocalizations.get(
                                            'dark',
                                            lang,
                                          ),
                                          icon: Icons.nightlight_round,
                                          isSelected:
                                              appState.themeMode ==
                                              ThemeMode.dark,
                                          onTap: () => appState.setThemeMode(
                                            ThemeMode.dark,
                                          ),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildThemeOption(
                                          label: AppLocalizations.get(
                                            'light',
                                            lang,
                                          ),
                                          icon: Icons.wb_sunny_rounded,
                                          isSelected:
                                              appState.themeMode ==
                                              ThemeMode.light,
                                          onTap: () => appState.setThemeMode(
                                            ThemeMode.light,
                                          ),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildThemeOption(
                                          label: AppLocalizations.get(
                                            'system',
                                            lang,
                                          ),
                                          icon: Icons.android,
                                          isSelected:
                                              appState.themeMode ==
                                              ThemeMode.system,
                                          onTap: () => appState.setThemeMode(
                                            ThemeMode.system,
                                          ),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: borderColor),

                              // ============ اللغة ============
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _primaryRed.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.language_outlined,
                                            color: _primaryRed,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.get(
                                            'language',
                                            lang,
                                          ),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textCol,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _buildLanguageOption(
                                          label: AppLocalizations.get(
                                            'english',
                                            lang,
                                          ),
                                          flag: '🇬🇧',
                                          isSelected: appState.language == 'en',
                                          onTap: () =>
                                              appState.setLanguage('en'),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildLanguageOption(
                                          label: AppLocalizations.get(
                                            'arabic',
                                            lang,
                                          ),
                                          flag: '🇸🇦',
                                          isSelected: appState.language == 'ar',
                                          onTap: () =>
                                              appState.setLanguage('ar'),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ============ بطاقة إدارة البراندات ============
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.2 : 0.06,
                                ),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BrandsScreen(),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              _primaryRed,
                                              Color(0xFFB00710),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryRed.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.branding_watermark_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.get(
                                                'manage_brands',
                                                lang,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: textCol,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${appState.brands.length} ${AppLocalizations.get('brands_added', lang)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: subTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: subTextColor,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ============ الشريط العلوي ============
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 14,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: Text(
                        AppLocalizations.get('profile', lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final textCol = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _darkCard : _lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? _darkBorder : _lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryRed, Color(0xFFB00710)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: subTextColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
