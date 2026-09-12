import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';
import 'view.dart';

class BrandDetailsScreen extends StatefulWidget {
  final Brand brand;

  const BrandDetailsScreen({super.key, required this.brand});

  @override
  State<BrandDetailsScreen> createState() => _BrandDetailsScreenState();
}

class _BrandDetailsScreenState extends State<BrandDetailsScreen> {
  String _searchQuery = '';

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  // ✅ نفس عرض BrandsScreen تمامًا
  static const double _maxContentWidth = 800;

  Color _textColor(bool isDark) => isDark ? Colors.white : Colors.black87;
  Color _subTextColor(bool isDark) =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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

  Widget _buildBrandImage(String? imagePath, bool isDark) {
    if (imagePath == null || imagePath.isEmpty) {
      return _fallbackImage();
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) => _fallbackImage(),
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => _fallbackImage(),
            ),
          );
        }
      }

      return _fallbackImage();
    } catch (e) {
      return _fallbackImage();
    }
  }

  Widget _fallbackImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryRed, Color(0xFFB00710)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          widget.brand.name.isNotEmpty
              ? widget.brand.name[0].toUpperCase()
              : 'B',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildCarImage(String imagePath, bool isDark) {
    if (imagePath.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.directions_car,
            size: 48,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
        ),
      );
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryRed,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _carFallback(isDark),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => _carFallback(isDark),
          );
        }
      }

      return _carFallback(isDark);
    } catch (e) {
      return _carFallback(isDark);
    }
  }

  Widget _carFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 48,
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

    final bgColor = isDark ? _darkBg : _lightBg;
    final cardColor = isDark ? _darkCard : _lightCard;
    final textCol = _textColor(isDark);
    final subTextColor = _subTextColor(isDark);
    final borderColor = isDark ? _darkBorder : _lightBorder;

    final brandCars = appState.cars
        .where((c) => c.brandName == widget.brand.name)
        .toList();

    final filteredCars = brandCars.where((car) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return car.name.toLowerCase().contains(query) ||
          car.category.toLowerCase().contains(query) ||
          car.year.toString().contains(query);
    }).toList();

    final totalHp = brandCars.fold<int>(0, (sum, c) => sum + c.horsepower);
    final avgYear = brandCars.isEmpty
        ? 0
        : brandCars.fold<int>(0, (sum, c) => sum + c.year) ~/ brandCars.length;

    return Scaffold(
      backgroundColor: bgColor,
      // ✅ Column مع الشريط العلوي في الأعلى — نفس بنية BrandsScreen
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
                        widget.brand.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // ✅ مساحة فارغة بنفس حجم زر الرجوع لتوسيط العنوان
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ),

          // ===== المحتوى =====
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final contentWidth = screenWidth > _maxContentWidth
                    ? _maxContentWidth
                    : screenWidth;

                final crossAxisCount = contentWidth >= 700 ? 3 : 2;

                final childAspectRatio = contentWidth >= 700 ? 0.76 : 0.75;

                return Stack(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: CustomScrollView(
                          slivers: [
                            // ============ بطاقة البراند ============
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_primaryRed, Color(0xFFB00710)],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.35),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: _buildBrandImage(
                                          widget.brand.imagePath,
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.brand.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                _buildStatChip(
                                                  icon: Icons
                                                      .directions_car_rounded,
                                                  label: '${brandCars.length}',
                                                ),
                                                _buildStatChip(
                                                  icon: Icons.bolt_rounded,
                                                  label:
                                                      '$totalHp ${AppLocalizations.get('hp', lang)}',
                                                ),
                                                if (avgYear > 0)
                                                  _buildStatChip(
                                                    icon: Icons
                                                        .calendar_today_rounded,
                                                    label: '$avgYear',
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ============ حقل البحث ============
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.get(
                                        'search_placeholder',
                                        lang,
                                      ),
                                      hintStyle: TextStyle(
                                        color: subTextColor,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.search_rounded,
                                          color: _primaryRed,
                                          size: 22,
                                        ),
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: subTextColor,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                () => _searchQuery = '',
                                              ),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ============ شريط العد ============
                            if (filteredCars.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${filteredCars.length} ${AppLocalizations.get('cars', lang)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryRed.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          widget.brand.name,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _primaryRed,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // ============ حالة عدم وجود سيارات ============
                            if (filteredCars.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 600,
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                color: _primaryRed.withOpacity(
                                                  0.2,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              _searchQuery.isEmpty
                                                  ? Icons
                                                        .directions_car_filled_outlined
                                                  : Icons.search_off_rounded,
                                              size: 60,
                                              color: _primaryRed.withOpacity(
                                                0.6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            _searchQuery.isEmpty
                                                ? AppLocalizations.get(
                                                    'no_cars_for_brand',
                                                    lang,
                                                  )
                                                : AppLocalizations.get(
                                                    'no_matching_results',
                                                    lang,
                                                  ),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: textCol,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _searchQuery.isEmpty
                                                ? AppLocalizations.get(
                                                    'add_first_car_for_brand',
                                                    lang,
                                                  )
                                                : AppLocalizations.get(
                                                    'try_different_search',
                                                    lang,
                                                  ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: subTextColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              // ============ شبكة السيارات ============
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: childAspectRatio,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final car = filteredCars[index];
                                    return _buildCarCard(
                                      car,
                                      isDark,
                                      textCol,
                                      subTextColor,
                                      lang,
                                    );
                                  }, childCount: filteredCars.length),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(
    Car car,
    bool isDark,
    Color textCol,
    Color subTextColor,
    String lang,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CarDetailsScreen(car: car)),
        ),
        child: Hero(
          tag: 'car_${car.id}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCarImage(
                          car.imagePaths.isNotEmpty ? car.imagePaths.first : '',
                          isDark,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${car.horsepower} ${AppLocalizations.get('hp', lang)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.brandName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _primaryRed,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                car.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textCol,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${car.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (car.priceEGP > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${car.priceEGP.toStringAsFixed(0)} EGP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
