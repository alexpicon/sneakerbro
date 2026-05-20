import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sneaker.dart';
import '../services/photo_service.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import '../widgets/sneaker_image.dart';

/// The form used both to add a new sneaker and to edit an existing one.
///
/// [sneaker] is the existing pair when editing, or an optional pre-filled
/// pair when adding (for example, one created from a catalog item). When it
/// is null the form starts blank with a fresh id.
class AddEditSneakerScreen extends StatefulWidget {
  const AddEditSneakerScreen({
    super.key,
    this.sneaker,
    this.isEditing = false,
  });

  final Sneaker? sneaker;
  final bool isEditing;

  @override
  State<AddEditSneakerScreen> createState() => _AddEditSneakerScreenState();
}

/// What the user chose in the photo options sheet.
enum _PhotoAction { camera, library, url, remove }

class _AddEditSneakerScreenState extends State<AddEditSneakerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final String _id;
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _colorway;
  late final TextEditingController _size;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _estimatedValue;
  late final TextEditingController _notes;

  late String _condition;
  late bool _isWishlist;
  DateTime? _purchaseDate;

  // The sneaker's image: a local photo path, a remote URL, or empty for the
  // drawn artwork. Held as plain state rather than a text field now that it
  // is set through the photo picker.
  late String _imageUrl;

  // Wear data is carried through an edit untouched - it is tracked on the
  // detail screen, not typed into this form.
  late int _totalSteps;
  late int _wearCount;

  @override
  void initState() {
    super.initState();
    final s = widget.sneaker;
    _id = s?.id ?? CollectionModel.newId();
    _name = TextEditingController(text: s?.name ?? '');
    _brand = TextEditingController(text: s?.brand ?? '');
    _model = TextEditingController(text: s?.model ?? '');
    _colorway = TextEditingController(text: s?.colorway ?? '');
    _size = TextEditingController(text: s?.size ?? '');
    _purchasePrice = TextEditingController(
      text: (s != null && s.purchasePrice > 0)
          ? s.purchasePrice.toStringAsFixed(2)
          : '',
    );
    _estimatedValue = TextEditingController(
      text: (s != null && s.estimatedValue > 0)
          ? s.estimatedValue.toStringAsFixed(2)
          : '',
    );
    _notes = TextEditingController(text: s?.notes ?? '');
    _imageUrl = s?.imageUrl ?? '';
    _condition = s?.condition ?? 'Good';
    _isWishlist = s?.isWishlist ?? false;
    _purchaseDate = s?.purchaseDate;
    _totalSteps = s?.totalSteps ?? 0;
    _wearCount = s?.wearCount ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _colorway.dispose();
    _size.dispose();
    _purchasePrice.dispose();
    _estimatedValue.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  // ---- photo handling ----------------------------------------------------

  Future<void> _showPhotoOptions() async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sneaker photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: kBrandColor),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: kBrandColor),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.library),
            ),
            ListTile(
              leading: const Icon(Icons.link, color: kBrandColor),
              title: const Text('Paste an image URL'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.url),
            ),
            if (_imageUrl.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: kAccentColor),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case _PhotoAction.camera:
        await _capturePhoto(PhotoSource.camera);
      case _PhotoAction.library:
        await _capturePhoto(PhotoSource.library);
      case _PhotoAction.url:
        await _promptForUrl();
      case _PhotoAction.remove:
        setState(() => _imageUrl = '');
    }
  }

  Future<void> _capturePhoto(PhotoSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await PhotoService.pick(source);
      if (path != null && mounted) {
        setState(() => _imageUrl = path);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not add that photo. Check the app has photo access.',
          ),
        ),
      );
    }
  }

  Future<void> _promptForUrl() async {
    final controller = TextEditingController(
      text: _imageUrl.startsWith('http') ? _imageUrl : '',
    );
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Image URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Use URL'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url != null) {
      setState(() => _imageUrl = url);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final sneaker = Sneaker(
      id: _id,
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      colorway: _colorway.text.trim(),
      size: _size.text.trim(),
      condition: _condition,
      purchasePrice: double.tryParse(_purchasePrice.text.trim()) ?? 0,
      estimatedValue: double.tryParse(_estimatedValue.text.trim()) ?? 0,
      purchaseDate: _purchaseDate,
      imageUrl: _imageUrl,
      totalSteps: _totalSteps,
      wearCount: _wearCount,
      notes: _notes.text.trim(),
      isWishlist: _isWishlist,
    );

    context.read<CollectionModel>().upsert(sneaker);
    Navigator.pop(context);
  }

  String? _numberValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // these fields are optional
    if (double.tryParse(text) == null) return 'Enter a valid number';
    if (double.parse(text) < 0) return 'Cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit sneaker' : 'Add a sneaker'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _photoPicker(),
            const SizedBox(height: 18),
            _textField(
              _name,
              'Name *',
              onChanged: (_) => setState(() {}),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            _textField(_brand, 'Brand', onChanged: (_) => setState(() {})),
            _textField(_model, 'Model', onChanged: (_) => setState(() {})),
            _textField(
              _colorway,
              'Colorway',
              onChanged: (_) => setState(() {}),
            ),
            _textField(_size, 'Size (US)'),
            _conditionField(),
            _textField(
              _purchasePrice,
              'Purchase price',
              prefix: '\$ ',
              helperText: 'What you actually paid for this pair',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _numberValidator,
            ),
            _textField(
              _estimatedValue,
              'Market value',
              prefix: '\$ ',
              helperText:
                  'Deadstock market value (the bundled pairs use a '
                  '$kPriceSnapshot price snapshot)',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _numberValidator,
            ),
            _dateField(),
            _textField(_notes, 'Notes', maxLines: 3),
            const SizedBox(height: 4),
            _wishlistSwitch(),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _save,
              child: Text(
                widget.isEditing ? 'Save changes' : 'Add to SneakerBro',
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// The tappable photo at the top of the form. Shows the current photo, or
  /// the drawn artwork as a live preview while there is none.
  Widget _photoPicker() {
    final hasImage = _imageUrl.isNotEmpty;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                SneakerImage(
                  imageUrl: _imageUrl,
                  brand: _brand.text,
                  colorway: _colorway.text,
                  model: _model.text,
                  name: _name.text,
                  size: 140,
                  borderRadius: 20,
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: kBrandColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _showPhotoOptions,
            child: Text(hasImage ? 'Change photo' : 'Add a photo'),
          ),
          if (!hasImage)
            const Text(
              'No photo yet - showing artwork drawn from the colorway',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: kMutedText),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          helperText: helperText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _conditionField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: _condition,
        decoration: InputDecoration(
          labelText: 'Condition',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: kConditionOptions
            .map(
              (condition) => DropdownMenuItem<String>(
                value: condition,
                child: Text(condition),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _condition = value ?? 'Good'),
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Purchase date',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _purchaseDate == null
                      ? 'Not set'
                      : longDate(_purchaseDate),
                  style: TextStyle(
                    color: _purchaseDate == null
                        ? kMutedText
                        : Colors.black87,
                  ),
                ),
              ),
              if (_purchaseDate != null)
                GestureDetector(
                  onTap: () => setState(() => _purchaseDate = null),
                  child: const Icon(Icons.close, size: 18, color: kMutedText),
                )
              else
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: kMutedText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wishlistSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: SwitchListTile(
        value: _isWishlist,
        onChanged: (value) => setState(() => _isWishlist = value),
        title: const Text('Wishlist item'),
        subtitle: const Text("Turn on if you don't own this pair yet"),
        activeThumbColor: kAccentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
