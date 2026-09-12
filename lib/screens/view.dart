import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';
import 'edit_car.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  int _selectedImageIndex = 0;
  double? _imageAspectRatio;

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  // ✅ الحد الأقصى لعرض المحتوى على الشاشات الكبيرة
  static const double _maxContentWidth = 900;
  static const double _maxDialogWidth = 480;

  Color _textColor(bool isDark) => isDark ? Colors.white : Colors.black87;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final images = widget.car.imagePaths.where((p) => p.isNotEmpty).toList();
      if (images.isNotEmpty) {
        _loadImageAspectRatio(images.first);
      } else {
        setState(() => _imageAspectRatio = 16 / 9);
      }
    });
  }

  Future<void> _loadImageAspectRatio(String imagePath) async {
    if (imagePath.isEmpty) {
      if (mounted) setState(() => _imageAspectRatio = 16 / 9);
      return;
    }

    try {
      ui.Image image;

      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        final provider = NetworkImage(imagePath);
        final completer = Completer<ui.Image>();
        provider
            .resolve(const ImageConfiguration())
            .addListener(
              ImageStreamListener(
                (info, _) {
                  if (!completer.isCompleted) completer.complete(info.image);
                },
                onError: (_, __) {
                  if (!completer.isCompleted) {
                    completer.completeError('failed');
                  }
                },
              ),
            );
        image = await completer.future;
      } else if (!kIsWeb) {
        final file = File(imagePath);
        if (!file.existsSync()) {
          if (mounted) setState(() => _imageAspectRatio = 16 / 9);
          return;
        }
        final bytes = await file.readAsBytes();
        image = await decodeImageFromList(bytes);
      } else {
        if (mounted) setState(() => _imageAspectRatio = 16 / 9);
        return;
      }

      if (mounted && image.height > 0) {
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _imageAspectRatio = 16 / 9);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    Color? customColor,
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
                color: customColor ?? (isDark ? Colors.white : Colors.black87),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainImage(String imagePath, bool isDark) {
    final aspectRatio = _imageAspectRatio ?? (16 / 9);

    Widget wrapAspect(Widget child) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
          child: child,
        ),
      );
    }

    if (imagePath.isEmpty) {
      return wrapAspect(_buildPlaceholder(isDark));
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return wrapAspect(
          Image.network(
            imagePath,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  color: _primaryRed,
                  strokeWidth: 2.5,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(isDark),
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return wrapAspect(
            Image.file(
              file,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(isDark),
            ),
          );
        }
      }

      return wrapAspect(_buildPlaceholder(isDark));
    } catch (e) {
      return wrapAspect(_buildPlaceholder(isDark));
    }
  }

  Widget _buildThumbImage(String imagePath, bool isDark) {
    if (imagePath.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
        child: Icon(
          Icons.directions_car,
          size: 30,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      );
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
            child: Icon(
              Icons.broken_image,
              size: 20,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
              child: Icon(
                Icons.broken_image,
                size: 20,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          );
        }
      }

      return Container(
        color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
        child: Icon(
          Icons.broken_image,
          size: 20,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      );
    } catch (e) {
      return Container(
        color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
        child: Icon(
          Icons.error,
          size: 20,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      );
    }
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.directions_car,
          size: 80,
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final car = widget.car;
    final images = car.imagePaths.where((path) => path.isNotEmpty).toList();

    if (images.isEmpty) {
      images.add('');
    }

    if (_selectedImageIndex >= images.length) {
      _selectedImageIndex = 0;
    }

    final mainImage = images[_selectedImageIndex];

    final bgColor = isDark ? _darkBg : _lightBg;
    final textCol = _textColor(isDark);

    final topBarHeight = MediaQuery.of(context).padding.top + 60;

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          // ✅ على الديسكتوب: 6 أعمدة، تابلت: 3، موبايل: 3
          final specsColumns = constraints.maxWidth >= 900
              ? 6
              : (constraints.maxWidth >= 600 ? 4 : 3);

          return Stack(
            children: [
              // ✅ المحتوى ممركز بعرض أقصى
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(top: topBarHeight, bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ============ الصورة الرئيسية ============
                        Stack(
                          children: [
                            _buildMainImage(mainImage, isDark),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 120,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        bgColor,
                                        bgColor.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: '${car.year}',
                                    backgroundColor: _primaryRed,
                                  ),
                                  _buildInfoChip(
                                    icon: Icons.category_rounded,
                                    label: car.category,
                                    backgroundColor: _primaryRed,
                                  ),
                                  _buildInfoChip(
                                    icon: Icons.branding_watermark_rounded,
                                    label: car.brandName,
                                    backgroundColor: _primaryRed,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ============ الصور المصغرة ============
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          height: 84,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              final path = images[index];
                              final isSelected = index == _selectedImageIndex;

                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImageIndex = index;
                                      _imageAspectRatio = null;
                                    });
                                    _loadImageAspectRatio(path);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 85,
                                    height: 65,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryRed
                                            : (isDark
                                                  ? _darkBorder
                                                  : _lightBorder),
                                        width: isSelected ? 3 : 1.2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: _primaryRed.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildThumbImage(path, isDark),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ============ السعر + المواصفات ============
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ============ بطاقة السعر ============
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryRed,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.35),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'EGP',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.75,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${car.priceEGP.toStringAsFixed(0)}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            AppLocalizations.get('price', lang),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.25),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Container(
                                              width: 1.5,
                                              color: Colors.white.withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'USD',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.75,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${car.priceUSD.toStringAsFixed(0)}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ============ عنوان المواصفات ============
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _primaryRed,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.get(
                                      'specifications',
                                      lang,
                                    ),
                                    style: TextStyle(
                                      color: textCol,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ============ شبكة المواصفات ============
                              GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: specsColumns,
                                      childAspectRatio: isWide ? 1.25 : 1.1,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                children: [
                                  _ModernSpecTile(
                                    title: AppLocalizations.get(
                                      'horsepower',
                                      lang,
                                    ),
                                    value:
                                        '${car.horsepower} ${AppLocalizations.get('hp', lang)}',
                                    icon: Icons.bolt,
                                    isDark: isDark,
                                  ),
                                  _ModernSpecTile(
                                    title: AppLocalizations.get(
                                      'zero_to_hundred',
                                      lang,
                                    ),
                                    value: '${car.zeroToHundred}s',
                                    icon: Icons.speed,
                                    isDark: isDark,
                                  ),
                                  _ModernSpecTile(
                                    title: AppLocalizations.get('engine', lang),
                                    value: car.engineCapacity,
                                    icon: Icons.tune,
                                    isDark: isDark,
                                  ),
                                  _ModernSpecTile(
                                    title: AppLocalizations.get(
                                      'cylinders',
                                      lang,
                                    ),
                                    value: '${car.cylinders}',
                                    icon: Icons.settings,
                                    isDark: isDark,
                                  ),
                                  _ModernSpecTile(
                                    title: AppLocalizations.get(
                                      'transmission',
                                      lang,
                                    ),
                                    value: car.transmission,
                                    icon: Icons.alt_route,
                                    isDark: isDark,
                                  ),
                                  _ModernSpecTile(
                                    title: AppLocalizations.get(
                                      'category',
                                      lang,
                                    ),
                                    value: car.category,
                                    icon: Icons.category,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
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
                      child: Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.arrow_back_ios_new,
                            onPressed: () => Navigator.pop(context),
                            isDark: isDark,
                          ),
                          Expanded(
                            child: Text(
                              car.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ============ شريط الأزرار السفلي ============
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        bgColor,
                        bgColor.withOpacity(0.95),
                        bgColor.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  // ✅ الأزرار محدودة بعرض المحتوى
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? _darkCard : _lightCard,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? _darkBorder : _lightBorder,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.5 : 0.12,
                              ),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditCarScreen(carToEdit: car),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primaryRed.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.edit_outlined,
                                            color: _primaryRed,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.get('edit', lang),
                                            style: const TextStyle(
                                              color: _primaryRed,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _confirmDelete(context, appState, lang),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE50914),
                                            Color(0xFFE50914),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFFE50914),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.get(
                                              'delete',
                                              lang,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          // ✅ عرض أقصى للديالوج
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
                    color: const Color(0xFFE50914).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE50914),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.get('delete_car', lang),
                  style: TextStyle(
                    color: _textColor(isDark),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.get('delete_confirm', lang),
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            colors: [Color(0xFFE50914), Color(0xFFE50914)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            appState.deleteCar(widget.car.id);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernSpecTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _ModernSpecTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFE0E0E0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 20),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 1),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
