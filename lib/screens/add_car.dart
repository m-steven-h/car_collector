import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/app_model.dart';
import '../localized/localized.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _selectedBrandId;
  String? _selectedBrandName;
  int _cylinders = 4;
  String _transmission = 'Automatic';
  int _year = DateTime.now().year;
  String _category = 'Sedan';

  final List<int> _allowedCylinders = [3, 4, 5, 6, 8, 10, 12];
  final List<String> _categories = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Convertible',
    'Truck',
    'Luxury',
    'Crossover',
    'MPV',
  ];

  final _nameController = TextEditingController();
  final _engineController = TextEditingController();
  final _hpController = TextEditingController();
  final _zeroHundredController = TextEditingController();
  final _priceEGPController = TextEditingController();
  final _priceUSDController = TextEditingController();

  List<String?> _images = List.filled(5, null);
  bool _isSaving = false;

  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _darkBg = Color(0xFF0A0A0C);
  static const Color _darkCard = Color(0xFF181820);
  static const Color _darkBorder = Color(0xFF2A2A35);
  static const Color _lightBg = Color(0xFFF5F5F8);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE0E0E0);

  static const double _maxContentWidth = 800;
  static const double _maxDialogWidth = 480;

  @override
  void dispose() {
    _nameController.dispose();
    _engineController.dispose();
    _hpController.dispose();
    _zeroHundredController.dispose();
    _priceEGPController.dispose();
    _priceUSDController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  📢 رسالة فوق كل حاجة (Overlay)
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

  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return true;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return true;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.photos.request();
          if (status.isGranted) return true;
          if (status.isPermanentlyDenied) {
            _showPermissionDialog('photos_access');
            return false;
          }
          return false;
        } else {
          final status = await Permission.storage.request();
          if (status.isGranted) return true;
          if (status.isPermanentlyDenied) {
            _showPermissionDialog('storage_access');
            return false;
          }
          return false;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          _showPermissionDialog('photos_access');
          return false;
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting gallery permission: $e');
      return false;
    }
  }

  void _showPermissionDialog(String permissionKey) {
    if (!mounted) return;
    final lang = Provider.of<AppState>(context, listen: false).language;
    final permissionName = AppLocalizations.get(permissionKey, lang);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.get('permissions_required', lang)),
        content: Text(
          '${AppLocalizations.get('grant_permission', lang)} $permissionName ${AppLocalizations.get('from_device_settings', lang)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.get('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: Text(AppLocalizations.get('settings', lang)),
          ),
        ],
      ),
    );
  }

  /// ✅ اختيار صورة من معرض/ملفات الجهاز مباشرة (بدون كاميرا)
  Future<void> _pickImage(int index, ImageSource source) async {
    final lang = Provider.of<AppState>(context, listen: false).language;

    try {
      // ✅ دائمًا نطلب صلاحية المعرض
      final hasPermission = await _requestGalleryPermission();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.get('insufficient_permissions', lang),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.get('image_too_large', lang)),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      String imagePath;

      if (kIsWeb) {
        final base64Image = base64Encode(bytes);
        imagePath = 'data:image/jpeg;base64,$base64Image';
      } else {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final carImagesDir = Directory('${appDir.path}/car_images');
          if (!await carImagesDir.exists()) {
            await carImagesDir.create(recursive: true);
          }
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
          final savedImage = File('${carImagesDir.path}/$fileName');
          await savedImage.writeAsBytes(bytes);
          imagePath = savedImage.path;
        } catch (e) {
          imagePath = pickedFile.path;
        }
      }

      setState(() {
        _images[index] = imagePath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.get('image_selected', lang)} ${index + 1}',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.get('error_picking_image', lang)}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ اختيار صورة البراند من معرض/ملفات الجهاز مباشرة (بدون كاميرا)
  Future<String?> _pickAndSaveBrandImage(BuildContext context) async {
    final lang = Provider.of<AppState>(context, listen: false).language;

    try {
      final hasPermission = await _requestGalleryPermission();

      if (!hasPermission) {
        if (mounted) {
          _showTopMessage(
            context,
            AppLocalizations.get('insufficient_permissions', lang),
          );
        }
        return null;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
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
      if (mounted) {
        _showTopMessage(
          context,
          '${AppLocalizations.get('error', lang)}: ${e.toString()}',
        );
      }
      return null;
    }
  }

  Widget _buildDialogBrandImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(
        Icons.add_business_outlined,
        color: Color(0xFFE50914),
        size: 40,
      );
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            color: Color(0xFFE50914),
            size: 40,
          ),
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image,
              color: Color(0xFFE50914),
              size: 40,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error building brand dialog image: $e');
    }

    return const Icon(Icons.broken_image, color: Color(0xFFE50914), size: 40);
  }

  /// ✅ فتح معرض الملفات مباشرة لصورة السيارة (بدون نافذة خيارات)
  Future<void> _pickImageDirectly(int index) async {
    await _pickImage(index, ImageSource.gallery);
  }

  void _showQuickAddBrandDialog(AppState appState, String lang) {
    final brandController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? selectedImagePath;
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
              final path = await _pickAndSaveBrandImage(context);
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
                                  width: 100,
                                  height: 100,
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
                                        color: _primaryRed.withOpacity(0.6),
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
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppLocalizations.get('quick_add_brand', lang),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: brandController,
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
                        const SizedBox(height: 24),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
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
                                  onPressed: () async {
                                    if (selectedImagePath == null ||
                                        selectedImagePath!.isEmpty) {
                                      _showTopMessage(
                                        context,
                                        AppLocalizations.get(
                                          'image_required',
                                          lang,
                                        ),
                                      );
                                      return;
                                    }

                                    if (brandController.text.trim().isEmpty) {
                                      _showTopMessage(
                                        context,
                                        AppLocalizations.get(
                                          'brand_name_required',
                                          lang,
                                        ),
                                      );
                                      return;
                                    }

                                    final newBrand = await appState.addBrand(
                                      brandController.text.trim(),
                                      imagePath: selectedImagePath,
                                    );

                                    setState(() {
                                      _selectedBrandId = newBrand.id;
                                      _selectedBrandName = newBrand.name;
                                    });

                                    if (mounted) Navigator.pop(ctx);
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

  void _saveCar(AppState appState, String lang) async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('fill_required', lang))),
      );
      return;
    }

    if (_selectedBrandId == null || _selectedBrandName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('fill_required', lang))),
      );
      return;
    }

    if (_images.any((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('select_5_images', lang))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newCar = Car(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brandId: _selectedBrandId!,
        brandName: _selectedBrandName!,
        name: _nameController.text.trim(),
        engineCapacity: _engineController.text.trim(),
        cylinders: _cylinders,
        transmission: _transmission,
        year: _year,
        category: _category,
        zeroToHundred: double.parse(_zeroHundredController.text.trim()),
        priceEGP: double.parse(_priceEGPController.text.trim()),
        priceUSD: double.parse(_priceUSDController.text.trim()),
        horsepower: int.parse(_hpController.text.trim()),
        imagePaths: _images.cast<String>(),
        createdAt: DateTime.now(),
      );

      await appState.addCar(newCar);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('car_saved', lang))),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.get('error_saving_car', lang)}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildImagePreview(String? imagePath, String lang) {
    if (imagePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.get('add_image', lang),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade500
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    try {
      if (imagePath.startsWith('blob:') || imagePath.startsWith('data:')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: 100,
          height: 110,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, size: 30));
          },
        );
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: 100,
            height: 110,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, size: 30));
            },
          );
        }
      }

      return const Center(child: Icon(Icons.broken_image, size: 30));
    } catch (e) {
      return const Center(child: Icon(Icons.error, size: 30));
    }
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
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
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool isDark = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: _primaryRed.withOpacity(0.7), size: 20)
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      labelStyle: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        fontSize: 13,
      ),
      filled: true,
      fillColor: isDark ? _darkCard : _lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? _darkBorder : _lightBorder,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
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
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          return Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 90,
                      20,
                      40,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            AppLocalizations.get('preselections', lang),
                            isDark,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedBrandId,
                                  isExpanded: true,
                                  dropdownColor: cardColor,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  decoration: _buildInputDecoration(
                                    label: AppLocalizations.get('brands', lang),
                                    icon: Icons.branding_watermark_outlined,
                                    isDark: isDark,
                                  ),
                                  items: appState.brands.map((b) {
                                    return DropdownMenuItem(
                                      value: b.id,
                                      child: Text(
                                        b.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    final b = appState.brands.firstWhere(
                                      (element) => element.id == val,
                                    );
                                    setState(() {
                                      _selectedBrandId = b.id;
                                      _selectedBrandName = b.name;
                                    });
                                  },
                                  validator: (val) => val == null
                                      ? AppLocalizations.get(
                                          'fill_required',
                                          lang,
                                        )
                                      : null,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: subTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 58,
                                width: 90,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          _primaryRed,
                                          Color(0xFFB00710),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryRed.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => _showQuickAddBrandDialog(
                                          appState,
                                          lang,
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  AppLocalizations.get(
                                                    'add',
                                                    lang,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCylindersDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTransmissionDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildYearDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCategoryDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCylindersDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTransmissionDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildYearDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCategoryDropdown(
                                    cardColor,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),

                          _buildSectionTitle(
                            AppLocalizations.get('car_specs', lang),
                            isDark,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: textColor, fontSize: 15),
                            decoration: _buildInputDecoration(
                              label: AppLocalizations.get('car_name', lang),
                              hint: 'M5 CS',
                              icon: Icons.directions_car_outlined,
                              isDark: isDark,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppLocalizations.get('fill_required', lang)
                                : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _engineController,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                  ),
                                  decoration: _buildInputDecoration(
                                    label: AppLocalizations.get('engine', lang),
                                    hint: '4.4L',
                                    icon: Icons.tune_outlined,
                                    isDark: isDark,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? AppLocalizations.get(
                                          'fill_required',
                                          lang,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _hpController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                  ),
                                  decoration: _buildInputDecoration(
                                    label: AppLocalizations.get(
                                      'horsepower',
                                      lang,
                                    ),
                                    hint: '625',
                                    icon: Icons.bolt_outlined,
                                    isDark: isDark,
                                  ),
                                  validator: (v) =>
                                      (v == null ||
                                          int.tryParse(v.trim()) == null)
                                      ? AppLocalizations.get(
                                          'fill_required',
                                          lang,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildZeroToHundredField(
                                    textColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPriceEGPField(
                                    textColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPriceUSDField(
                                    textColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildZeroToHundredField(textColor, isDark, lang),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPriceEGPField(
                                    textColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPriceUSDField(
                                    textColor,
                                    isDark,
                                    lang,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),

                          // ============ معرض الصور ============
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionTitle(
                                  AppLocalizations.get('photo_gallery', lang),
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _primaryRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryRed.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      // ✅ فتح المعرض مباشرة للصورة الرئيسية
                                      onTap: () => _pickImageDirectly(0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.photo_library_outlined,
                                              color: _primaryRed,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppLocalizations.get(
                                                'choose_from_gallery',
                                                lang,
                                              ),
                                              style: const TextStyle(
                                                color: _primaryRed,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
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
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.get('must_add_5_images', lang),
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, idx) {
                                final imgPath = _images[idx];
                                final isMainImage = idx == 0;

                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    width: 105,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E1E28)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isMainImage
                                            ? _primaryRed
                                            : (isDark
                                                  ? _darkBorder
                                                  : _lightBorder),
                                        width: isMainImage ? 2.5 : 1.2,
                                      ),
                                      boxShadow: isMainImage
                                          ? [
                                              BoxShadow(
                                                color: _primaryRed.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: _buildImagePreview(
                                            imgPath,
                                            lang,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              // ✅ فتح المعرض مباشرة
                                              onTap: () =>
                                                  _pickImageDirectly(idx),
                                            ),
                                          ),
                                        ),
                                        if (isMainImage && imgPath == null)
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _primaryRed,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                AppLocalizations.get(
                                                  'main_image',
                                                  lang,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (!isMainImage && imgPath == null)
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.grey.shade800
                                                    : Colors.grey.shade300,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${idx + 1}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade600,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (imgPath != null)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                () => _images[idx] = null,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (imgPath != null)
                                          Positioned(
                                            bottom: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryRed,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: _primaryRed.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () => _saveCar(appState, lang),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.save_rounded,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppLocalizations.get('save', lang),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
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
                              AppLocalizations.get('add_car', lang),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
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

  // ============ Dropdowns مساعدة ============
  Widget _buildCylindersDropdown(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
    String lang,
  ) {
    return DropdownButtonFormField<int>(
      value: _cylinders,
      isExpanded: true,
      dropdownColor: cardColor,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('cylinders', lang),
        icon: Icons.settings_outlined,
        isDark: isDark,
      ),
      items: _allowedCylinders
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(
                '$c',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor),
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() => _cylinders = val);
      },
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
    );
  }

  Widget _buildTransmissionDropdown(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
    String lang,
  ) {
    return DropdownButtonFormField<String>(
      value: _transmission,
      isExpanded: true,
      dropdownColor: cardColor,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('transmission', lang),
        icon: Icons.alt_route_outlined,
        isDark: isDark,
      ),
      items: [
        DropdownMenuItem(
          value: 'Manual',
          child: Text(
            AppLocalizations.get('manual', lang),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
        DropdownMenuItem(
          value: 'Automatic',
          child: Text(
            AppLocalizations.get('automatic', lang),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
      onChanged: (val) {
        if (val == null) return;
        setState(() => _transmission = val);
      },
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
    );
  }

  Widget _buildYearDropdown(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
    String lang,
  ) {
    return DropdownButtonFormField<int>(
      value: _year,
      isExpanded: true,
      dropdownColor: cardColor,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('year', lang),
        icon: Icons.calendar_today_outlined,
        isDark: isDark,
      ),
      items: List.generate(100, (i) => DateTime.now().year - i)
          .map(
            (y) => DropdownMenuItem(
              value: y,
              child: Text(
                '$y',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor),
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() => _year = val);
      },
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
    );
  }

  Widget _buildCategoryDropdown(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
    String lang,
  ) {
    return DropdownButtonFormField<String>(
      value: _category,
      isExpanded: true,
      dropdownColor: cardColor,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('category', lang),
        icon: Icons.category_outlined,
        isDark: isDark,
      ),
      items: _categories
          .map(
            (cat) => DropdownMenuItem(
              value: cat,
              child: Text(
                cat,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor),
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() => _category = val);
      },
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
    );
  }

  // ============ حقول مساعدة ============
  Widget _buildZeroToHundredField(Color textColor, bool isDark, String lang) {
    return TextFormField(
      controller: _zeroHundredController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('zero_to_hundred', lang),
        hint: '3.0',
        icon: Icons.speed_outlined,
        isDark: isDark,
      ),
      validator: (v) => (v == null || double.tryParse(v.trim()) == null)
          ? AppLocalizations.get('fill_required', lang)
          : null,
    );
  }

  Widget _buildPriceEGPField(Color textColor, bool isDark, String lang) {
    return TextFormField(
      controller: _priceEGPController,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('price_egp', lang),
        hint: '5000000',
        icon: Icons.attach_money_outlined,
        isDark: isDark,
      ),
      validator: (v) => (v == null || double.tryParse(v.trim()) == null)
          ? AppLocalizations.get('fill_required', lang)
          : null,
    );
  }

  Widget _buildPriceUSDField(Color textColor, bool isDark, String lang) {
    return TextFormField(
      controller: _priceUSDController,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: _buildInputDecoration(
        label: AppLocalizations.get('price_usd', lang),
        hint: '160000',
        icon: Icons.attach_money_outlined,
        isDark: isDark,
      ),
      validator: (v) => (v == null || double.tryParse(v.trim()) == null)
          ? AppLocalizations.get('fill_required', lang)
          : null,
    );
  }
}
