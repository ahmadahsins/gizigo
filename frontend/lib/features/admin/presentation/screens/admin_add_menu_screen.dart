import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/admin_remote_data_source.dart';
import '../widgets/ai_loading_dialog.dart';

class AdminAddMenuScreen extends StatefulWidget {
  const AdminAddMenuScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.useMerchantEndpoint = false,
  });

  final String merchantId;
  final String merchantName;
  final bool useMerchantEndpoint;

  @override
  State<AdminAddMenuScreen> createState() => _AdminAddMenuScreenState();
}

class _AdminAddMenuScreenState extends State<AdminAddMenuScreen> {
  static const _categoryOptions = [
    _MenuOption('main_course', 'Main Course'),
    _MenuOption('appetizers', 'Appetizers'),
    _MenuOption('snacks', 'Snacks'),
    _MenuOption('desserts', 'Desserts'),
    _MenuOption('beverages', 'Beverages'),
    _MenuOption('breakfast', 'Breakfast'),
    _MenuOption('lunch', 'Lunch'),
    _MenuOption('dinner', 'Dinner'),
    _MenuOption('salads', 'Salads'),
  ];
  static const _tagOptions = [
    'High Protein',
    'Vegetarian',
    'Low Calories',
    'Gluten Free',
  ];

  final _formKey = GlobalKey<FormState>();
  late final AdminRemoteDataSource _remoteDataSource;
  late final ImagePicker _imagePicker;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _gofoodController = TextEditingController();
  final _grabfoodController = TextEditingController();
  final _shopeefoodController = TextEditingController();
  final List<_IngredientEntry> _ingredients = [_IngredientEntry()];
  final Set<String> _selectedTags = {};

  String? _selectedCategory;
  Uint8List? _photoBytes;
  String? _photoFilename;
  bool _isAvailable = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AdminRemoteDataSource(DioClient());
    _imagePicker = ImagePicker();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _gofoodController.dispose();
    _grabfoodController.dispose();
    _shopeefoodController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_isSaving) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1280,
    );
    if (image == null || !mounted) return;

    setState(() {
      _photoFilename = image.name.isEmpty ? 'menu-photo.jpg' : image.name;
    });
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    final price = _parsePrice(_priceController.text);
    if (price == null || price <= 0) {
      _showSnackBar('Price harus diisi dengan angka yang valid.');
      return;
    }
    final recipeIngredients = _recipeIngredients();
    if (recipeIngredients.isEmpty) {
      _showSnackBar('Isi minimal satu recipe ingredient yang valid.');
      return;
    }

    final hasPlatformLink = _gofoodController.text.trim().isNotEmpty ||
        _grabfoodController.text.trim().isNotEmpty ||
        _shopeefoodController.text.trim().isNotEmpty;
    if (!hasPlatformLink) {
      _showSnackBar('Isi minimal satu link platform delivery.');
      return;
    }

    setState(() => _isSaving = true);
    showAiLoadingDialog(context);

    try {
      final result = widget.useMerchantEndpoint
          ? await _remoteDataSource.createOwnFood(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              foodCategory: _selectedCategory!,
              basePrice: price,
              healthLabels: _selectedTags.toList(growable: false),
              isAvailable: _isAvailable,
              recipeIngredients: recipeIngredients,
              gofoodLink: _gofoodController.text.trim(),
              grabfoodLink: _grabfoodController.text.trim(),
              shopeefoodLink: _shopeefoodController.text.trim(),
              photoBytes: _photoBytes,
              photoFilename: _photoFilename,
            )
          : await _remoteDataSource.createFood(
              merchantId: widget.merchantId,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              foodCategory: _selectedCategory!,
              basePrice: price,
              healthLabels: _selectedTags.toList(growable: false),
              isAvailable: _isAvailable,
              recipeIngredients: recipeIngredients,
              gofoodLink: _gofoodController.text.trim(),
              grabfoodLink: _grabfoodController.text.trim(),
              shopeefoodLink: _shopeefoodController.text.trim(),
              photoBytes: _photoBytes,
              photoFilename: _photoFilename,
            );

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isSaving = false);
      _showSnackBar(_errorMessage(error));
    }
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientEntry()));
  }

  void _removeIngredient(int index) {
    if (_ingredients.length == 1) {
      _ingredients.first.clear();
      return;
    }

    setState(() {
      final removed = _ingredients.removeAt(index);
      removed.dispose();
    });
  }

  int? _parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits);
  }

  List<Map<String, Object>> _recipeIngredients() {
    return _ingredients
        .map((entry) {
          final name = entry.nameController.text.trim();
          final amount = double.tryParse(
            entry.quantityController.text.replaceAll(',', '.').trim(),
          );
          if (name.isEmpty || amount == null || amount <= 0) return null;

          return <String, Object>{
            'name': name,
            'amount': amount,
            'unit': entry.unit,
          };
        })
        .nonNulls
        .toList(growable: false);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() ?? '' : '';
      if (message.toLowerCase().contains('gemini api is not configured')) {
        return 'Backend Gemini belum dikonfigurasi. Hubungi maintainer backend.';
      }
      if (message.isNotEmpty) return message;

      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return 'Gagal menambahkan menu. Server memberi status $statusCode.';
      }
    }

    return 'Gagal menambahkan menu. Cek data dan coba lagi.';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(34, 26, 34, 32),
            children: [
              _AddMenuHeader(onBack: () => Navigator.of(context).pop(false)),
              const SizedBox(height: 32),
              _FieldLabel('Upload a Photo of the Menu'),
              const SizedBox(height: 10),
              _PhotoPickerBox(
                bytes: _photoBytes,
                filename: _photoFilename,
                onTap: _pickPhoto,
              ),
              const SizedBox(height: 34),
              _FieldLabel('Menu Name'),
              const SizedBox(height: 8),
              _TextInput(
                controller: _nameController,
                hintText: 'Enter Menu Name here',
                maxLength: 50,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Menu name wajib diisi.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              _CharacterCounter(length: _nameController.text.length, max: 50),
              const SizedBox(height: 24),
              _FieldLabel('Description'),
              const SizedBox(height: 8),
              _TextInput(
                controller: _descriptionController,
                hintText:
                    'Tell customers about the taste, main ingredients, or unique features of this menu item.',
                maxLength: 200,
                maxLines: 3,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Description wajib diisi.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              _CharacterCounter(
                length: _descriptionController.text.length,
                max: 200,
              ),
              const SizedBox(height: 24),
              _FieldLabel('Category'),
              const SizedBox(height: 8),
              _CategoryDropdown(
                value: _selectedCategory,
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 24),
              _FieldLabel('Price'),
              const SizedBox(height: 8),
              _TextInput(
                controller: _priceController,
                hintText: 'Example: 25.000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_parsePrice(value ?? '') == null) {
                    return 'Price wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const _FieldLabel('Select Tag'),
                  const Spacer(),
                  Text(
                    'Select one or more',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF696969),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _TagGrid(
                tags: _tagOptions,
                selectedTags: _selectedTags,
                onToggle: (tag) {
                  setState(() {
                    if (!_selectedTags.add(tag)) _selectedTags.remove(tag);
                  });
                },
              ),
              const SizedBox(height: 34),
              _FieldLabel('Recipe Ingredients'),
              const SizedBox(height: 12),
              for (var index = 0; index < _ingredients.length; index++) ...[
                _IngredientRow(
                  index: index,
                  entry: _ingredients[index],
                  onRemove: () => _removeIngredient(index),
                ),
                const SizedBox(height: 10),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: _AddIngredientButton(onPressed: _addIngredient),
              ),
              const SizedBox(height: 34),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    flex: 2,
                    child: _FieldLabel('Delivery Platform Links'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'At least one link required',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF696969),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Add links to your menu on delivery platforms to enable direct ordering.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF696969),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GoFood Link',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 8),
              _TextInput(
                controller: _gofoodController,
                hintText: 'Example: https://gofood.link/...',
              ),
              const SizedBox(height: 16),
              Text(
                'GrabFood Link',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 8),
              _TextInput(
                controller: _grabfoodController,
                hintText: 'Example: https://grab.com/food/...',
              ),
              const SizedBox(height: 16),
              Text(
                'ShopeeFood Link',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 8),
              _TextInput(
                controller: _shopeefoodController,
                hintText: 'Example: https://shopee.co.id/food/...',
              ),
              const SizedBox(height: 34),
              _StatusSwitchRow(
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              const SizedBox(height: 56),
              _PrimaryActionButton(
                text: 'Add Menu',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              _SecondaryActionButton(
                text: 'Cancel',
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOption {
  const _MenuOption(this.value, this.label);

  final String value;
  final String label;
}

class _IngredientEntry {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  String unit = 'pcs';

  void clear() {
    nameController.clear();
    quantityController.clear();
    unit = 'pcs';
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

class _AddMenuHeader extends StatelessWidget {
  const _AddMenuHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 30,
              color: Color(0xFF202020),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Add Menu',
          style: GoogleFonts.inter(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF202020),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF242424),
      ),
    );
  }
}

class _PhotoPickerBox extends StatelessWidget {
  const _PhotoPickerBox({
    required this.bytes,
    required this.filename,
    required this.onTap,
  });

  final Uint8List? bytes;
  final String? filename;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageBytes = bytes;

    return SizedBox(
      height: 202,
      child: Material(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5D5D5), width: 2),
            ),
            child: imageBytes == null
                ? const _PhotoPickerEmpty()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(imageBytes, fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            color: Colors.black.withValues(alpha: 0.48),
                            child: Text(
                              filename ?? 'Selected image',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
    );
  }
}

class _PhotoPickerEmpty extends StatelessWidget {
  const _PhotoPickerEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_rounded, size: 46, color: Color(0xFF303030)),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: const [
                TextSpan(
                  text: 'Choose',
                  style: TextStyle(color: AppColors.primary),
                ),
                TextSpan(text: ' image to upload'),
              ],
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF313131),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF929292),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F1F1),
        contentPadding: EdgeInsets.fromLTRB(13, maxLines == 1 ? 0 : 13, 13, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _CharacterCounter extends StatelessWidget {
  const _CharacterCounter({required this.length, required this.max});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        '$length/$max',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
      validator: (value) => value == null ? 'Category wajib dipilih.' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F1F1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      hint: Text(
        'Select one',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF929292),
        ),
      ),
      items: _AdminAddMenuScreenState._categoryOptions
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.value,
              child: Text(
                option.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _TagGrid extends StatelessWidget {
  const _TagGrid({
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 23,
      runSpacing: 12,
      children: tags
          .map(
            (tag) => _TagButton(
              label: tag,
              isSelected: selectedTags.contains(tag),
              onTap: () => onToggle(tag),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TagButton extends StatelessWidget {
  const _TagButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _TagColors.forLabel(label);

    return SizedBox(
      width: 97,
      height: 28,
      child: Material(
        color: isSelected ? colors.background : const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? colors.foreground : const Color(0xFF676767),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagColors {
  const _TagColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static const _defaultColors = _TagColors(
    background: Color(0xFFEDEDED),
    foreground: Color(0xFF4A4A4A),
  );

  static _TagColors forLabel(String label) {
    return switch (_normalizedKey(label)) {
      'highprotein' => const _TagColors(
        background: Color(0xFFFCDCD8),
        foreground: Color(0xFF9B2825),
      ),
      'vegetarian' || 'vegan' => const _TagColors(
        background: Color(0xFFD1F1EC),
        foreground: Color(0xFF087A5A),
      ),
      'lowcalorie' || 'lowcalories' => const _TagColors(
        background: Color(0xFFF5F6D5),
        foreground: Color(0xFF8A4C17),
      ),
      'glutenfree' => const _TagColors(
        background: Color(0xFFD6E9F8),
        foreground: Color(0xFF235C82),
      ),
      _ => _defaultColors,
    };
  }

  static String _normalizedKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _IngredientRow extends StatefulWidget {
  const _IngredientRow({
    required this.index,
    required this.entry,
    required this.onRemove,
  });

  final int index;
  final _IngredientEntry entry;
  final VoidCallback onRemove;

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _IngredientLayout.fieldHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _IngredientLayout.indexWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.index + 1}.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF242424),
                ),
              ),
            ),
          ),
          const SizedBox(width: _IngredientLayout.gap),
          Expanded(
            child: _IngredientInput(
              controller: widget.entry.nameController,
              hintText: 'Example: Egg',
            ),
          ),
          const SizedBox(width: _IngredientLayout.gap),
          SizedBox(
            width: _IngredientLayout.amountWidth,
            child: _IngredientInput(
              controller: widget.entry.quantityController,
              hintText: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: _IngredientLayout.gap),
          SizedBox(
            width: _IngredientLayout.unitWidth,
            child: _IngredientUnitDropdown(
              value: widget.entry.unit,
              onChanged: (value) {
                setState(() => widget.entry.unit = value);
              },
            ),
          ),
          const SizedBox(width: _IngredientLayout.smallGap),
          SizedBox(
            width: _IngredientLayout.removeWidth,
            child: IconButton(
              onPressed: widget.onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.expand(),
              icon: const Icon(
                Icons.close_rounded,
                size: 22,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientLayout {
  const _IngredientLayout._();

  static const double fieldHeight = 46;
  static const double indexWidth = 18;
  static const double amountWidth = 52;
  static const double unitWidth = 78;
  static const double removeWidth = 24;
  static const double gap = 4;
  static const double smallGap = 3;
  static const double radius = 8;
  static const Color fillColor = Color(0xFFF5F1F1);
  static const Color borderColor = Color(0xFFC8C6C6);
}

class _IngredientUnitDropdown extends StatelessWidget {
  const _IngredientUnitDropdown({required this.value, required this.onChanged});

  static const _units = ['pcs', 'g', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'slice'];

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      initialValue: value,
      tooltip: '',
      constraints: const BoxConstraints(minWidth: 72),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_IngredientLayout.radius),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => _units
          .map(
            (unit) => PopupMenuItem<String>(
              value: unit,
              height: 36,
              child: _UnitText(unit),
            ),
          )
          .toList(growable: false),
      child: Container(
        height: _IngredientLayout.fieldHeight,
        decoration: _ingredientFieldDecoration(),
        padding: const EdgeInsets.only(left: 9, right: 7),
        child: Row(
          children: [
            Expanded(child: _UnitText(value)),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF4A4A4A),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitText extends StatelessWidget {
  const _UnitText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: _ingredientTextStyle(),
      ),
    );
  }
}

class _IngredientInput extends StatelessWidget {
  const _IngredientInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _IngredientLayout.fieldHeight,
      decoration: _ingredientFieldDecoration(),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
        style: _ingredientTextStyle(),
        decoration: _ingredientInputDecoration(hintText: hintText),
      ),
    );
  }
}

InputDecoration _ingredientInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.inter(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF929292),
    ),
    filled: true,
    isDense: true,
    fillColor: Colors.transparent,
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );
}

BoxDecoration _ingredientFieldDecoration() {
  return BoxDecoration(
    color: _IngredientLayout.fillColor,
    borderRadius: BorderRadius.circular(_IngredientLayout.radius),
    border: Border.all(color: _IngredientLayout.borderColor),
  );
}

TextStyle _ingredientTextStyle() {
  return GoogleFonts.inter(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF333333),
  );
}

class _AddIngredientButton extends StatelessWidget {
  const _AddIngredientButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEFF6EF),
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        'Add Ingredient',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusSwitchRow extends StatelessWidget {
  const _StatusSwitchRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Menu Status'),
              const SizedBox(height: 4),
              Text(
                'Visible to customers now',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF696969),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFC8C8C8),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.62),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
