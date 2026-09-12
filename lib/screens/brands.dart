import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';
import 'brand_details.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  static const double _maxContentWidth = 800;
  static const double _maxDialogWidth = 480;

  Color _textColor(bool isDark) => isDark ? Colors.white : Colors.black87;
  Color _subTextColor(bool isDark) =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

  // ═══════════════════════════════════════════════════════════
  //  📢 عرض رسالة فوق كل حاجة (Overlay)
  // ═══════════════════════════════════════════════════════════
  void _showTopMessage(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final msgWidth = screenWidth > 600 ? 500.0 : screenWidth - 32;

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 0,
        right: 0,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: msgWidth),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryRed, Color(0xFFB00710)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  /// ✅ اختيار صورة البراند من معرض/ملفات الجهاز مباشرة (بدون كاميرا)
  Future<String?> _pickAndSaveImage(BuildContext context) async {
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
          _showTopMessage(
            context,
            AppLocalizations.get('image_too_large_5mb', lang),
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
          final brandsDir = Directory('${appDir.path}/brand_images');
          if (!await brandsDir.exists()) {
            await brandsDir.create(recursive: true);
          }
          final fileName = 'brand_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = File('${brandsDir.path}/$fileName');
          await savedImage.writeAsBytes(bytes);
          return savedImage.path;
        } catch (e) {
          debugPrint('Error saving brand image: $e');
          return pickedFile.path;
        }
      }
    } catch (e) {
      debugPrint('Error picking brand image: $e');
      if (context.mounted) {
        _showTopMessage(
          context,
          '${AppLocalizations.get('error', lang)}: ${e.toString()}',
        );
      }
      return null;
    }
  }

  Widget _buildBrandImage(
    String? imagePath,
    Color brandColor,
    bool isDark,
    String brandName,
  ) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildFallbackIcon(brandColor, brandName);
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            width: 48,
            height: 48,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackIcon(brandColor, brandName),
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackIcon(brandColor, brandName),
            ),
          );
        }
      }

      return _buildFallbackIcon(brandColor, brandName);
    } catch (e) {
      return _buildFallbackIcon(brandColor, brandName);
    }
  }

  Widget _buildFallbackIcon(Color brandColor, String brandName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandColor.withOpacity(0.8), brandColor.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDialogBrandImage(String? imagePath, String lang) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(
        Icons.add_business_outlined,
        color: Color(0xFFE50914),
        size: 45,
      );
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            color: Color(0xFFE50914),
            size: 45,
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: 110,
            height: 110,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image,
              color: Color(0xFFE50914),
              size: 45,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error building brand dialog image: $e');
    }

    return const Icon(Icons.broken_image, color: Color(0xFFE50914), size: 45);
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Colors.black87,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton({required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryRed, Color(0xFFB00710)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditBrandDialog(
    BuildContext context,
    AppState appState,
    String lang, {
    Brand? brandToEdit,
  }) {
    final controller = TextEditingController(text: brandToEdit?.name ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? selectedImagePath = brandToEdit?.imagePath;
    bool isPicking = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            /// ✅ فتح معرض الملفات مباشرة لصورة البراند
            Future<void> pickBrandImage() async {
              setDialogState(() => isPicking = true);
              final path = await _pickAndSaveImage(context);
              setDialogState(() {
                if (path != null) {
                  selectedImagePath = path;
                }
                isPicking = false;
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
                child: SingleChildScrollView(
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
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            // ✅ فتح المعرض مباشرة
                            onTap: isPicking ? null : pickBrandImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E28)
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _primaryRed,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed,
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: isPicking
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: _primaryRed,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : _buildDialogBrandImage(
                                            selectedImagePath,
                                            lang,
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
                                        color: isDark ? _darkCard : _lightCard,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryRed,
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.photo_library_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedImagePath == null ||
                                  selectedImagePath!.isEmpty
                              ? AppLocalizations.get('tap_to_add_image', lang)
                              : AppLocalizations.get(
                                  'tap_to_change_image',
                                  lang,
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            color: _subTextColor(isDark),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          brandToEdit == null
                              ? AppLocalizations.get('add_brand', lang)
                              : AppLocalizations.get('edit_brand', lang),
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
                            labelText: AppLocalizations.get('brand_name', lang),
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            prefixIcon: const Icon(
                              Icons.branding_watermark_outlined,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [_primaryRed, Color(0xFFB00710)],
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
                                      final nameEmpty = controller.text
                                          .trim()
                                          .isEmpty;
                                      final imageEmpty =
                                          selectedImagePath == null ||
                                          selectedImagePath!.isEmpty;

                                      if (imageEmpty) {
                                        _showTopMessage(
                                          context,
                                          AppLocalizations.get(
                                            'image_required',
                                            lang,
                                          ),
                                        );
                                        return;
                                      }

                                      if (nameEmpty) {
                                        _showTopMessage(
                                          context,
                                          AppLocalizations.get(
                                            'brand_name_required',
                                            lang,
                                          ),
                                        );
                                        return;
                                      }

                                      if (brandToEdit != null) {
                                        appState.editBrand(
                                          brandToEdit.id,
                                          controller.text.trim(),
                                          imagePath: selectedImagePath,
                                        );
                                      } else {
                                        appState.addBrand(
                                          controller.text.trim(),
                                          imagePath: selectedImagePath,
                                        );
                                      }
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.get('save', lang),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
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
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBrand(
    BuildContext context,
    AppState appState,
    String lang,
    Brand brand,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
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
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFE50914).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: isDark ? Colors.white : const Color(0xFFE50914),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.get('delete_brand', lang),
                  style: TextStyle(
                    color: _textColor(isDark),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppLocalizations.get('delete_brand_confirm', lang)} "${brand.name}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.75)
                        : Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.5,
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
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE50914), Color(0xFFE50914)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              appState.deleteBrand(brand.id);
                              Navigator.pop(ctx);
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
                              AppLocalizations.get('delete', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? _darkBg : _lightBg;
    final textCol = _textColor(isDark);
    final subTextColor = _subTextColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ===== البار العلوي =====
          Container(
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
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.pop(context),
                      isDark: isDark,
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.get('brands', lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildAddButton(
                      onPressed: () =>
                          _showAddEditBrandDialog(context, appState, lang),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== المحتوى =====
          Expanded(
            child: appState.brands.isEmpty
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _primaryRed.withOpacity(0.15),
                                    _primaryRed.withOpacity(0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _primaryRed.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.branding_watermark_outlined,
                                size: 60,
                                color: _primaryRed.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.get('no_brands', lang),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.get('add_first_brand', lang),
                              style: TextStyle(
                                fontSize: 15,
                                color: subTextColor,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _showAddEditBrandDialog(
                                  context,
                                  appState,
                                  lang,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [_primaryRed, Color(0xFFB00710)],
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: _primaryRed,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        AppLocalizations.get(
                                          'add_first_brand',
                                          lang,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: appState.brands.length,
                        itemBuilder: (context, index) {
                          final brand = appState.brands[index];
                          final carCount = appState.cars
                              .where((c) => c.brandName == brand.name)
                              .length;

                          final colors = [
                            const Color(0xFFE74C3C),
                            const Color(0xFF3498DB),
                            const Color(0xFF2ECC71),
                            const Color(0xFFF39C12),
                            const Color(0xFF9B59B6),
                            const Color(0xFF1ABC9C),
                            const Color(0xFFE67E22),
                          ];
                          final brandColor = colors[index % colors.length];

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: isDark ? _darkCard : _lightCard,
                                border: Border.all(
                                  color: isDark ? _darkBorder : _lightBorder,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BrandDetailsScreen(brand: brand),
                                        ),
                                      );
                                    },
                                    splashColor: brandColor.withOpacity(0.1),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: _buildBrandImage(
                                              brand.imagePath,
                                              brandColor,
                                              isDark,
                                              brand.name,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  brand.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                    color: textCol,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .directions_car_rounded,
                                                      size: 14,
                                                      color: isDark
                                                          ? Colors.grey.shade500
                                                          : Colors
                                                                .grey
                                                                .shade400,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$carCount ${AppLocalizations.get('cars', lang)}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: subTextColor,
                                                      ),
                                                    ),
                                                    if (carCount > 0) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        width: 4,
                                                        height: 4,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.grey,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: brandColor
                                                              .withOpacity(
                                                                0.15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          AppLocalizations.get(
                                                            'active',
                                                            lang,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: brandColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: isDark
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 6),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildIconButton(
                                                icon: Icons.edit_outlined,
                                                onPressed: () =>
                                                    _showAddEditBrandDialog(
                                                      context,
                                                      appState,
                                                      lang,
                                                      brandToEdit: brand,
                                                    ),
                                                isDark: isDark,
                                                iconColor: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              _buildIconButton(
                                                icon: Icons
                                                    .delete_outline_rounded,
                                                onPressed: () =>
                                                    _confirmDeleteBrand(
                                                      context,
                                                      appState,
                                                      lang,
                                                      brand,
                                                    ),
                                                isDark: isDark,
                                                iconColor: Colors.redAccent
                                                    .withOpacity(0.7),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ زر أيقونة مساعد
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required Color iconColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 18, color: iconColor),
          onPressed: onPressed,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
