import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/admin_remote_data_source.dart';
import '../../data/models/admin_food.dart';
import '../../data/models/admin_food_detail.dart';

class AdminMenuDetailScreen extends StatefulWidget {
  const AdminMenuDetailScreen({
    super.key,
    required this.food,
    this.useMerchantEndpoint = false,
  });

  final AdminFood food;
  final bool useMerchantEndpoint;

  @override
  State<AdminMenuDetailScreen> createState() => _AdminMenuDetailScreenState();
}

class _AdminMenuDetailScreenState extends State<AdminMenuDetailScreen> {
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
  late Future<AdminFoodDetail> _detailFuture;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final List<_IngredientEntry> _ingredients = [];
  final Set<String> _selectedTags = {};

  AdminFoodDetail? _detail;
  String? _selectedCategory;
  Uint8List? _photoBytes;
  String? _photoFilename;
  bool _isAvailable = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AdminRemoteDataSource(DioClient());
    _imagePicker = ImagePicker();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  Future<AdminFoodDetail> _loadDetail() async {
    try {
      final detail = widget.useMerchantEndpoint
          ? await _remoteDataSource.getOwnFoodDetail(widget.food.id)
          : await _remoteDataSource.getFoodDetail(widget.food.id);
      if (mounted) _applyDetail(detail);
      return detail;
    } catch (_) {
      final fallback = AdminFoodDetail(
        id: widget.food.id,
        name: widget.food.name,
        description: '',
        imageUrl: widget.food.imageUrl,
        basePrice: widget.food.basePrice,
        foodCategory: '',
        healthLabels: const [],
        isAvailable: widget.food.isAvailable,
        ingredients: const [],
      );
      if (mounted) _applyDetail(fallback);
      return fallback;
    }
  }

  void _applyDetail(AdminFoodDetail detail) {
    _detail = detail;
    _nameController.text = detail.name;
    _descriptionController.text = detail.description;
    _priceController.text = detail.basePrice == null
        ? ''
        : detail.basePrice.toString();
    _selectedCategory = detail.foodCategory.isEmpty
        ? null
        : detail.foodCategory;
    _isAvailable = detail.isAvailable;
    _selectedTags
      ..clear()
      ..addAll(detail.healthLabels);
    _photoBytes = null;
    _photoFilename = null;
    _replaceIngredients(detail.ingredients);
  }

  void _replaceIngredients(List<AdminFoodIngredient> ingredients) {
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    _ingredients
      ..clear()
      ..addAll(
        ingredients.isEmpty
            ? [_IngredientEntry()]
            : ingredients.map(
                (ingredient) => _IngredientEntry(
                  name: ingredient.name,
                  quantity: ingredient.quantity,
                  unit: ingredient.unit,
                ),
              ),
      );
  }

  Future<void> _pickPhoto() async {
    if (!_isEditing || _isSaving) return;

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

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    final price = _parsePrice(_priceController.text);
    if (price == null || price <= 0) {
      _showToast('Price harus diisi dengan angka yang valid.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = widget.useMerchantEndpoint
          ? await _remoteDataSource.updateOwnFood(
              foodId: widget.food.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              foodCategory: _selectedCategory!,
              basePrice: price,
              healthLabels: _selectedTags.toList(growable: false),
              isAvailable: _isAvailable,
              photoBytes: _photoBytes,
              photoFilename: _photoFilename,
            )
          : await _remoteDataSource.updateFood(
              foodId: widget.food.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              foodCategory: _selectedCategory!,
              basePrice: price,
              healthLabels: _selectedTags.toList(growable: false),
              isAvailable: _isAvailable,
              photoBytes: _photoBytes,
              photoFilename: _photoFilename,
            );
      if (!mounted) return;

      setState(() {
        _applyDetail(saved);
        _isEditing = false;
        _isSaving = false;
        _hasChanges = true;
      });
      _showToast('Menu berhasil diperbarui.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showToast('Gagal memperbarui menu. Coba lagi.', isError: true);
    }
  }

  void _discardChanges() {
    final detail = _detail;
    if (detail != null) _applyDetail(detail);
    setState(() => _isEditing = false);
  }

  void _deleteMenu() {
    Navigator.of(context).pop('delete');
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientEntry()));
  }

  void _removeIngredient(int index) {
    if (_ingredients.length == 1) {
      _ingredients.first.clear();
      setState(() {});
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

  String _categoryLabel(String value) {
    return _categoryOptions
        .firstWhere(
          (option) => option.value == value,
          orElse: () => _MenuOption(value, value),
        )
        .label;
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FutureBuilder<AdminFoodDetail>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _detail == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final detail = _detail;
              if (detail == null) {
                return const Center(child: Text('Failed to load menu detail.'));
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
                  children: [
                    _Header(
                      title: _isEditing ? 'Edit Menu' : 'Detail Menu',
                      onBack: () => Navigator.of(context).pop(_hasChanges),
                    ),
                    const SizedBox(height: 32),
                    const _FieldLabel('Menu Photo'),
                    const SizedBox(height: 12),
                    _MenuPhoto(
                      imageUrl: detail.imageUrl,
                      bytes: _photoBytes,
                      isEditing: _isEditing,
                      onTap: _pickPhoto,
                    ),
                    const SizedBox(height: 36),
                    const _FieldLabel('Menu Name'),
                    const SizedBox(height: 8),
                    _MenuTextField(
                      controller: _nameController,
                      hintText: 'Enter Menu Name here',
                      enabled: _isEditing,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Menu name wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    const _FieldLabel('Description'),
                    const SizedBox(height: 8),
                    _MenuTextField(
                      controller: _descriptionController,
                      hintText: 'Tell customers about this menu.',
                      enabled: _isEditing,
                      maxLines: 2,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Description wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    const _FieldLabel('Category'),
                    const SizedBox(height: 8),
                    _isEditing
                        ? _CategoryDropdown(
                            value: _selectedCategory,
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                          )
                        : _ReadonlyBox(
                            text: _selectedCategory == null
                                ? '-'
                                : _categoryLabel(_selectedCategory!),
                          ),
                    const SizedBox(height: 22),
                    const _FieldLabel('Price'),
                    const SizedBox(height: 8),
                    _MenuTextField(
                      controller: _priceController,
                      hintText: 'Example: 25.000',
                      enabled: _isEditing,
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
                        if (_isEditing)
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
                      tags: _isEditing
                          ? _tagOptions
                          : _selectedTags.toList(growable: false),
                      selectedTags: _selectedTags,
                      enabled: _isEditing,
                      onToggle: (tag) {
                        setState(() {
                          if (!_selectedTags.add(tag)) {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 34),
                    const _FieldLabel('Recipe Ingredients'),
                    const SizedBox(height: 12),
                    for (
                      var index = 0;
                      index < _ingredients.length;
                      index++
                    ) ...[
                      _IngredientRow(
                        index: index,
                        entry: _ingredients[index],
                        enabled: _isEditing,
                        onRemove: () => _removeIngredient(index),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_isEditing)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _AddIngredientButton(onPressed: _addIngredient),
                      ),
                    const SizedBox(height: 34),
                    _StatusSwitchRow(
                      value: _isAvailable,
                      enabled: _isEditing,
                      onChanged: (value) {
                        setState(() => _isAvailable = value);
                      },
                    ),
                    const SizedBox(height: 56),
                    if (_isEditing) ...[
                      _PrimaryActionButton(
                        text: 'Save Changes',
                        isLoading: _isSaving,
                        onPressed: _saveChanges,
                      ),
                      const SizedBox(height: 16),
                      _SecondaryActionButton(
                        text: 'Discard Changes',
                        onPressed: _isSaving ? null : _discardChanges,
                      ),
                    ] else ...[
                      _PrimaryActionButton(
                        text: 'Edit',
                        isLoading: false,
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                      const SizedBox(height: 16),
                      _DangerActionButton(
                        text: 'Delete',
                        onPressed: _deleteMenu,
                      ),
                    ],
                  ],
                ),
              );
            },
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
  _IngredientEntry({String name = '', String quantity = '', this.unit = 'pcs'})
    : nameController = TextEditingController(text: name),
      quantityController = TextEditingController(text: quantity);

  final TextEditingController nameController;
  final TextEditingController quantityController;
  String unit;

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

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
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
          title,
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

class _MenuPhoto extends StatelessWidget {
  const _MenuPhoto({
    required this.imageUrl,
    required this.bytes,
    required this.isEditing,
    required this.onTap,
  });

  final String imageUrl;
  final Uint8List? bytes;
  final bool isEditing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 202,
      child: Material(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isEditing ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5D5D5), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PhotoImage(imageUrl: imageUrl, bytes: bytes),
                  if (isEditing)
                    ColoredBox(
                      color: Colors.white.withValues(alpha: 0.46),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image_rounded,
                              size: 46,
                              color: Color(0xFF303030),
                            ),
                            const SizedBox(height: 18),
                            Text.rich(
                              TextSpan(
                                children: const [
                                  TextSpan(text: 'Drag & drop or '),
                                  TextSpan(
                                    text: 'choose',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  TextSpan(text: ' a new image to update'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF313131),
                              ),
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

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.imageUrl, required this.bytes});

  final String imageUrl;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final imageBytes = bytes;
    if (imageBytes != null) return Image.memory(imageBytes, fit: BoxFit.cover);
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const _PhotoFallback(),
      );
    }
    return const _PhotoFallback();
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7EFE8),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }
}

class _MenuTextField extends StatelessWidget {
  const _MenuTextField({
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
      decoration: _fieldDecoration(hintText: hintText, maxLines: maxLines),
    );
  }
}

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C6C6)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF929292),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  required int maxLines,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF929292),
    ),
    filled: true,
    fillColor: const Color(0xFFF5F1F1),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
    ),
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
  );
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
      decoration: _fieldDecoration(hintText: 'Select one', maxLines: 1),
      hint: Text(
        'Select one',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF929292),
        ),
      ),
      items: _AdminMenuDetailScreenState._categoryOptions
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
    required this.enabled,
    required this.onToggle,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final bool enabled;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.isEmpty ? const ['-'] : tags;
    return Wrap(
      spacing: 23,
      runSpacing: 12,
      children: visibleTags
          .map(
            (tag) => _TagButton(
              label: tag,
              isSelected: selectedTags.contains(tag),
              enabled: enabled && tag != '-',
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
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
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
          onTap: enabled ? onTap : null,
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
    required this.enabled,
    required this.onRemove,
  });

  final int index;
  final _IngredientEntry entry;
  final bool enabled;
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
              enabled: widget.enabled,
            ),
          ),
          const SizedBox(width: _IngredientLayout.gap),
          SizedBox(
            width: _IngredientLayout.amountWidth,
            child: _IngredientInput(
              controller: widget.entry.quantityController,
              hintText: '0',
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: _IngredientLayout.gap),
          SizedBox(
            width: _IngredientLayout.unitWidth,
            child: _IngredientUnitDropdown(
              value: widget.entry.unit,
              enabled: widget.enabled,
              onChanged: (value) {
                setState(() => widget.entry.unit = value);
              },
            ),
          ),
          const SizedBox(width: _IngredientLayout.smallGap),
          SizedBox(
            width: _IngredientLayout.removeWidth,
            child: widget.enabled
                ? IconButton(
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.expand(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Color(0xFF4A4A4A),
                    ),
                  )
                : const SizedBox.shrink(),
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
  static const double amountWidth = 62;
  static const double unitWidth = 78;
  static const double removeWidth = 24;
  static const double gap = 4;
  static const double smallGap = 3;
  static const double radius = 8;
  static const Color fillColor = Color(0xFFF5F1F1);
  static const Color borderColor = Color(0xFFC8C6C6);
}

class _IngredientUnitDropdown extends StatelessWidget {
  const _IngredientUnitDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  static const _units = ['pcs', 'g', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'slice'];

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _IngredientBox(child: _UnitText(value.isEmpty ? 'pcs' : value));
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      initialValue: value,
      tooltip: '',
      constraints: const BoxConstraints(minWidth: 78),
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
      child: _IngredientBox(
        child: Row(
          children: [
            Expanded(child: _UnitText(value.isEmpty ? 'pcs' : value)),
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

class _IngredientInput extends StatelessWidget {
  const _IngredientInput({
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return _IngredientBox(
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
        style: _ingredientTextStyle(),
        decoration: InputDecoration(
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
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _IngredientBox extends StatelessWidget {
  const _IngredientBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _IngredientLayout.fieldHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _IngredientLayout.fillColor,
        borderRadius: BorderRadius.circular(_IngredientLayout.radius),
        border: Border.all(color: _IngredientLayout.borderColor),
      ),
      child: child,
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
  const _StatusSwitchRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
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
              if (enabled) ...[
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
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFC8C8C8),
          onChanged: enabled ? onChanged : (_) {},
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCC1B1F),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
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
