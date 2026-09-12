import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';
import 'view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  // ✅ الحد الأقصى لعرض المحتوى على الشاشات الكبيرة
  static const double _maxContentWidth = 900;

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
            size: 40,
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
                size: 40,
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
                  size: 40,
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
            size: 40,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building car image: $e');
      return Container(
        color: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.error,
            size: 40,
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

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isDesktop = screenWidth >= 900;
          final isTablet = screenWidth >= 600 && screenWidth < 900;

          // ✅ عدد الأعمدة في شبكة الإحصائيات
          final statsColumns = isDesktop ? 4 : 2;

          // ✅ عدد البطاقات في قسم "آخر السيارات"
          final recentCardsCount = isDesktop ? 4 : (isTablet ? 4 : 3);

          // ✅ ارتفاع بطاقات السيارات
          final carCardHeight = isDesktop ? 260.0 : 230.0;
          final carCardWidth = isDesktop ? 200.0 : 170.0;

          return Stack(
            children: [
              // المحتوى الرئيسي - مع عرض أقصى وتوسيط
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 80,
                      bottom: bottomSpace + 100, // مساحة للـ nav bar
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ============ بطاقة الترحيب ============
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 28 : 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                _primaryRed,
                                Color(0xFFB00710),
                                Color(0xFF8B0000),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 3,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.get('welcome', lang)}, ${appState.username}!',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 26 : 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.get(
                                      'collection_progress',
                                      lang,
                                    ),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${appState.cars.length} ${AppLocalizations.get('cars', lang)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: appState.getNextLevelProgress(),
                                  minHeight: 10,
                                  backgroundColor: Colors.black.withOpacity(
                                    0.3,
                                  ),
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ============ شبكة الإحصائيات ============
                        _buildStatsGrid(
                          appState: appState,
                          lang: lang,
                          isDark: isDark,
                          columns: statsColumns,
                        ),
                        const SizedBox(height: 24),

                        // ============ عنوان "آخر السيارات" ============
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
                              AppLocalizations.get('recent_cars', lang),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ============ قائمة السيارات ============
                        if (appState.cars.isEmpty)
                          _buildEmptyState(
                            lang: lang,
                            isDark: isDark,
                            textCol: textCol,
                            cardColor: cardColor,
                            borderColor: borderColor,
                          )
                        else
                          SizedBox(
                            height: carCardHeight,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: appState.cars.length > recentCardsCount
                                  ? recentCardsCount
                                  : appState.cars.length,
                              itemBuilder: (context, index) {
                                final car = appState.cars[index];
                                return _buildCarCard(
                                  context: context,
                                  car: car,
                                  isDark: isDark,
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  textCol: textCol,
                                  subTextColor: subTextColor,
                                  width: carCardWidth,
                                );
                              },
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
                        AppLocalizations.get('app_title', lang),
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

  // ============ شبكة الإحصائيات ============
  Widget _buildStatsGrid({
    required AppState appState,
    required String lang,
    required bool isDark,
    required int columns,
  }) {
    final stats = [
      {
        'title': AppLocalizations.get('cars_collected', lang),
        'value': appState.cars.length.toString(),
        'icon': Icons.directions_car_rounded,
      },
      {
        'title': AppLocalizations.get('brands_added', lang),
        'value': appState.brands.length.toString(),
        'icon': Icons.branding_watermark_rounded,
      },
      {
        'title': AppLocalizations.get('total_hp', lang),
        'value': '${appState.totalHorsepower} HP',
        'icon': Icons.bolt_rounded,
      },
      {
        'title': AppLocalizations.get('top_brand', lang),
        'value': appState.topBrandName,
        'icon': Icons.star_rounded,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.map((stat) {
            return SizedBox(
              width: itemWidth,
              child: _StatCard(
                title: stat['title'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                isDark: isDark,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============ حالة عدم وجود سيارات ============
  Widget _buildEmptyState({
    required String lang,
    required bool isDark,
    required Color textCol,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                Icons.car_repair_rounded,
                size: 48,
                color: _primaryRed.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('empty_collection', lang),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============ بطاقة سيارة ============
  Widget _buildCarCard({
    required BuildContext context,
    required dynamic car,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textCol,
    required Color subTextColor,
    required double width,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CarDetailsScreen(car: car)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
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
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${car.horsepower} HP',
                              style: const TextStyle(
                                fontSize: 10,
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
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                                  fontSize: 9,
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
                                  fontSize: 13,
                                  color: textCol,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: subTextColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${car.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subTextColor,
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
              fontSize: 18,
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
