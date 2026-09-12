import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';
import 'view.dart';
import 'add_car.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _searchQuery = '';

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  // ✅ الحد الأقصى لعرض المحتوى على الشاشات الكبيرة
  static const double _maxContentWidth = 1100;

  Color _textColor(bool isDark) => isDark ? Colors.white : Colors.black87;
  Color _subTextColor(bool isDark) =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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
                  color: _primaryRed,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
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
            errorBuilder: (context, error, stackTrace) => Container(
              color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
            ),
          );
        }
      }

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
    } catch (e) {
      return Container(
        color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.error,
            size: 48,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
        ),
      );
    }
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

    List<Car> filteredCars = appState.cars.where((car) {
      final query = _searchQuery.toLowerCase();
      return car.name.toLowerCase().contains(query) ||
          car.brandName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ حساب عرض المحتوى الفعلي (المحدود بـ maxWidth)
          final screenWidth = constraints.maxWidth;
          final contentWidth = screenWidth > _maxContentWidth
              ? _maxContentWidth
              : screenWidth;

          // ✅ عدد الأعمدة محسوب من عرض المحتوى الفعلي
          final crossAxisCount = contentWidth >= 1000
              ? 4
              : contentWidth >= 700
              ? 3
              : 2;

          // ✅ نسبة العرض/الارتفاع تتغير حسب حجم الشاشة
          final childAspectRatio = contentWidth >= 1000
              ? 0.78
              : contentWidth >= 700
              ? 0.76
              : 0.75;

          return Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 80),
                  // ✅ البحث في وسط المحتوى
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
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
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
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
                                      onPressed: () =>
                                          setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ✅ شريط العد في وسط المحتوى
                  if (filteredCars.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  AppLocalizations.get('all_vehicles', lang),
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
                    ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filteredCars.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            lang: lang,
                            textCol: textCol,
                            subTextColor: subTextColor,
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _maxContentWidth,
                              ),
                              child: GridView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  bottomSpace + 100,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: childAspectRatio,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                    ),
                                itemCount: filteredCars.length,
                                itemBuilder: (context, index) {
                                  final car = filteredCars[index];
                                  return _buildCarCard(
                                    context: context,
                                    car: car,
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    textCol: textCol,
                                    subTextColor: subTextColor,
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              // ✅ الشريط العلوي محدود بعرض المحتوى
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
                        AppLocalizations.get('collection', lang),
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

  // ============ حالة عدم وجود سيارات ============
  Widget _buildEmptyState({
    required bool isDark,
    required String lang,
    required Color textCol,
    required Color subTextColor,
  }) {
    return Center(
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
                  _searchQuery.isEmpty
                      ? Icons.directions_car_filled_outlined
                      : Icons.search_off_rounded,
                  size: 60,
                  color: _primaryRed.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty
                    ? AppLocalizations.get('empty_collection', lang)
                    : 'لا توجد نتائج مطابقة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? AppLocalizations.get('start_first_car', lang)
                    : 'جرب البحث بكلمات مختلفة',
                style: TextStyle(
                  fontSize: 15,
                  color: subTextColor,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_searchQuery.isEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCarScreen()),
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
                            AppLocalizations.get('add_first_car', lang),
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
    );
  }

  // ============ بطاقة سيارة ============
  Widget _buildCarCard({
    required BuildContext context,
    required Car car,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textCol,
    required Color subTextColor,
  }) {
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
              color: cardColor,
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
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
                              '${car.horsepower} HP',
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                    color: subTextColor,
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
