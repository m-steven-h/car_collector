import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'models/app_model.dart';
import 'welcome.dart';
import 'screens/home.dart';
import 'screens/collection.dart';
import 'screens/profile.dart';
import 'screens/add_car.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة window_manager لـ Windows
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(420, 900),
    minimumSize: Size(360, 640),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: 'Car Collector',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // ✅ دالة تبديل الشاشة الكاملة
  Future<void> toggleFullScreen() async {
    final isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
  }

  // ✅ الاستماع لمفتاح F11
  ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      toggleFullScreen();
      return true;
    }
    // ✅ الخروج من الشاشة الكاملة بـ Escape
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      windowManager.isFullScreen().then((value) {
        if (value) windowManager.setFullScreen(false);
      });
    }
    return false;
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          final isArabic = appState.language == 'ar';

          final darkTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE50914),
              brightness: Brightness.dark,
              primary: const Color(0xFFE50914),
              surface: const Color(0xFF121216),
              background: const Color(0xFF0A0A0C),
            ),
            scaffoldBackgroundColor: const Color(0xFF09090C),
            cardTheme: CardThemeData(
              color: const Color(0xFF181820),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textTheme: GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme)
                .copyWith(
                  headlineLarge: GoogleFonts.exo2(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  headlineMedium: GoogleFonts.exo2(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  titleLarge: GoogleFonts.exo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  bodyLarge: GoogleFonts.exo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  bodyMedium: GoogleFonts.exo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                  labelLarge: GoogleFonts.exo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
          );

          final lightTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF181820),
              brightness: Brightness.light,
              primary: const Color(0xFFE50914),
              surface: const Color(0xFFF5F5F8),
              background: const Color(0xFFEFEFF4),
            ),
            scaffoldBackgroundColor: const Color(0xFFEFEFF4),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textTheme: GoogleFonts.exo2TextTheme(ThemeData.light().textTheme)
                .copyWith(
                  headlineLarge: GoogleFonts.exo2(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  headlineMedium: GoogleFonts.exo2(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  titleLarge: GoogleFonts.exo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  bodyLarge: GoogleFonts.exo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  bodyMedium: GoogleFonts.exo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                  labelLarge: GoogleFonts.exo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
          );

          return MaterialApp(
            title: 'Car Collector',
            debugShowCheckedModeBanner: false,
            themeMode: appState.themeMode,
            theme: lightTheme,
            darkTheme: darkTheme,
            builder: (context, child) {
              return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            home: appState.username == null
                ? const WelcomeScreen()
                : const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // ✅ مقاسات ثابتة
  static const double _barHeight = 68;
  static const double _addButtonSize = 68;
  static const double _bottomMargin = 16;
  static const double _sideMargin = 16;
  static const double _gap = 12;
  static const double _maxTotalWidth = 500;

  final List<Widget> _pages = const [
    HomeScreen(),
    CollectionScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottomSpace = _barHeight + _bottomMargin + bottomPadding;

    return Scaffold(
      body: Stack(
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(
                context,
              ).padding.copyWith(bottom: totalBottomSpace),
            ),
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),

          // ✅ الشريط بمقاس ثابت
          Positioned(
            left: 0,
            right: 0,
            bottom: _bottomMargin + bottomPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxTotalWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _sideMargin),
                  child: SizedBox(
                    height: _barHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildFloatingNavigationBar(lang)),
                        const SizedBox(width: _gap),
                        _buildAddButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavigationBar(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A24).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(_barHeight / 2),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_barHeight / 2),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: _getLocalized('home', lang),
                  index: 0,
                  isSelected: _selectedIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.directions_car_outlined,
                  selectedIcon: Icons.directions_car,
                  label: _getLocalized('collection', lang),
                  index: 1,
                  isSelected: _selectedIndex == 1,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: _getLocalized('profile', lang),
                  index: 2,
                  isSelected: _selectedIndex == 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCarScreen()),
          );
        },
        child: SizedBox(
          width: _addButtonSize,
          height: _addButtonSize,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFB00710)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 34),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedIndex = index);
          },
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: _barHeight - 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? primary : Colors.grey.shade500,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        color: isSelected ? primary : Colors.grey.shade500,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalized(String key, String lang) {
    const translations = {
      'home': {'en': 'Home', 'ar': 'الرئيسية'},
      'collection': {'en': 'Collection', 'ar': 'المجموعة'},
      'profile': {'en': 'Profile', 'ar': 'الملف الشخصي'},
    };

    return translations[key]?[lang] ?? translations[key]?['en'] ?? key;
  }
}
