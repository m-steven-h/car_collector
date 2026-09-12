import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../localized/localized.dart';

class Brand {
  final String id;
  final String name;
  final String? imagePath;

  Brand({
    required this.id,
    required this.name,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
      };

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String?,
      );

  Brand copyWith({String? id, String? name, String? imagePath}) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class Car {
  final String id;
  final String brandId;
  final String brandName;
  final String name;
  final String engineCapacity;
  final int cylinders;
  final String transmission;
  final int year;
  final String category;
  final double zeroToHundred;
  final double priceEGP;
  final double priceUSD;
  final int horsepower;
  final List<String> imagePaths;
  final DateTime createdAt;

  Car({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.name,
    required this.engineCapacity,
    required this.cylinders,
    required this.transmission,
    required this.year,
    required this.category,
    required this.zeroToHundred,
    required this.priceEGP,
    required this.priceUSD,
    required this.horsepower,
    required this.imagePaths,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brandId': brandId,
        'brandName': brandName,
        'name': name,
        'engineCapacity': engineCapacity,
        'cylinders': cylinders,
        'transmission': transmission,
        'year': year,
        'category': category,
        'zeroToHundred': zeroToHundred,
        'priceEGP': priceEGP,
        'priceUSD': priceUSD,
        'horsepower': horsepower,
        'imagePaths': imagePaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'] as String,
        brandId: json['brandId'] as String,
        brandName: json['brandName'] as String,
        name: json['name'] as String,
        engineCapacity: json['engineCapacity'] as String,
        cylinders: json['cylinders'] as int,
        transmission: json['transmission'] as String,
        year: json['year'] as int,
        category: json['category'] as String,
        zeroToHundred: (json['zeroToHundred'] as num).toDouble(),
        priceEGP: (json['priceEGP'] as num).toDouble(),
        priceUSD: (json['priceUSD'] as num).toDouble(),
        horsepower: json['horsepower'] as int,
        imagePaths: List<String>.from(json['imagePaths'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AppState extends ChangeNotifier {
  String? _username;
  String? _userImagePath;
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';
  List<Brand> _brands = [];
  List<Car> _cars = [];

  String? get username => _username;
  String? get userImagePath => _userImagePath;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  List<Brand> get brands => _brands;
  List<Car> get cars => _cars;

  static const List<String> defaultBrandNames = [];

  AppState() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _username = prefs.getString('username');

      _userImagePath = prefs.getString('userImagePath');

      _language = prefs.getString('language') ?? 'en';

      final themeStr = prefs.getString('themeMode') ?? 'dark';
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }

      final brandsJson = prefs.getString('brands');
      if (brandsJson != null) {
        final List decoded = jsonDecode(brandsJson);
        _brands = decoded.map((e) => Brand.fromJson(e)).toList();
      } else {
        _brands = defaultBrandNames
            .map((name) => Brand(
                  id: DateTime.now().microsecondsSinceEpoch.toString() + name,
                  name: name,
                ))
            .toList();
        _saveBrands();
      }

      final carsJson = prefs.getString('cars');
      if (carsJson != null) {
        final List decoded = jsonDecode(carsJson);
        _cars = decoded.map((e) => Car.fromJson(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> setUsername(String name) async {
    try {
      _username = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', name);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting username: $e');
    }
  }

  Future<void> setUserImage(String? imagePath) async {
    try {
      _userImagePath = imagePath;
      final prefs = await SharedPreferences.getInstance();
      if (imagePath == null || imagePath.isEmpty) {
        await prefs.remove('userImagePath');
      } else {
        await prefs.setString('userImagePath', imagePath);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting user image: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'themeMode',
          mode == ThemeMode.light
              ? 'light'
              : (mode == ThemeMode.system ? 'system' : 'dark'));
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }

  Future<void> setLanguage(String lang) async {
    try {
      _language = lang;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  Future<void> _saveBrands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_brands.map((e) => e.toJson()).toList());
      await prefs.setString('brands', jsonStr);
    } catch (e) {
      debugPrint('Error saving brands: $e');
    }
  }

  Future<void> _saveCars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_cars.map((e) => e.toJson()).toList());
      await prefs.setString('cars', jsonStr);
    } catch (e) {
      debugPrint('Error saving cars: $e');
    }
  }

  Future<Brand> addBrand(String name, {String? imagePath}) async {
    final newBrand = Brand(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      imagePath: imagePath,
    );
    _brands.add(newBrand);
    await _saveBrands();
    notifyListeners();
    return newBrand;
  }

  Future<void> editBrand(String id, String newName, {String? imagePath}) async {
    final index = _brands.indexWhere((b) => b.id == id);
    if (index != -1) {
      _brands[index] = Brand(
        id: id,
        name: newName.trim(),
        imagePath: imagePath ?? _brands[index].imagePath,
      );
      await _saveBrands();
      notifyListeners();
    }
  }

  Future<void> deleteBrand(String id) async {
    _brands.removeWhere((b) => b.id == id);
    await _saveBrands();
    notifyListeners();
  }

  Future<void> addCar(Car car) async {
    _cars.insert(0, car);
    await _saveCars();
    notifyListeners();
  }

  Future<void> updateCar(Car car) async {
    final index = _cars.indexWhere((c) => c.id == car.id);
    if (index != -1) {
      _cars[index] = car;
      await _saveCars();
      notifyListeners();
    }
  }

  Future<void> deleteCar(String id) async {
    _cars.removeWhere((c) => c.id == id);
    await _saveCars();
    notifyListeners();
  }

  int get totalHorsepower => _cars.fold(0, (sum, car) => sum + car.horsepower);

  String get topBrandName {
    if (_cars.isEmpty) return '-';
    final counts = <String, int>{};
    for (var c in _cars) {
      counts[c.brandName] = (counts[c.brandName] ?? 0) + 1;
    }
    var top = '';
    var maxCount = 0;
    counts.forEach((key, val) {
      if (val > maxCount) {
        maxCount = val;
        top = key;
      }
    });
    return top;
  }

  String getCollectorLevel(String lang) {
    final count = _cars.length;
    if (count >= 80) return AppLocalizations.get('level_elite', lang);
    if (count >= 40) return AppLocalizations.get('level_collector', lang);
    if (count >= 20) return AppLocalizations.get('level_fleet', lang);
    if (count >= 10) return AppLocalizations.get('level_builder', lang);
    if (count >= 5) return AppLocalizations.get('level_hunter', lang);
    return AppLocalizations.get('level_new', lang);
  }

  double getNextLevelProgress() {
    final count = _cars.length;
    if (count >= 80) return 1.0;
    if (count >= 40) return (count - 40) / 40;
    if (count >= 20) return (count - 20) / 20;
    if (count >= 10) return (count - 10) / 10;
    if (count >= 5) return (count - 5) / 5;
    return count / 5;
  }

  static bool imageExists(String path) {
    try {
      if (path.isEmpty) return false;
      if (path.startsWith('blob:') || path.startsWith('data:')) {
        return true;
      }
      return File(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  static Future<String> saveImageToAppDirectory(dynamic imageData) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final carImagesDir = Directory('${appDir.path}/car_images');

      if (!await carImagesDir.exists()) {
        await carImagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_image.jpg';
      final savedImage = File('${carImagesDir.path}/$fileName');

      if (imageData is List<int>) {
        await savedImage.writeAsBytes(imageData);
        return savedImage.path;
      } else if (imageData is String) {
        return imageData;
      }

      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return '';
    }
  }
}
