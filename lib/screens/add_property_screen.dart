import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';
import '../services/property_image_service.dart';
import '../state/property_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/property_photo.dart';

/// Add or edit a rental listing.
///
/// When [property] is null the form creates a new listing. When supplied the
/// form edits that existing local listing.
class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key, this.property});

  final Property? property;

  bool get isEditing => property != null;

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  String _category = PropertyCategory.houses;
  int _bedrooms = 1;
  int _bathrooms = 1;
  List<String> _images = [];
  final Set<String> _newImages = <String>{};
  final Set<String> _removedImages = <String>{};

  late final PropertyImageService _imageService;

  bool _isSaving = false;
  bool _isPicking = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _imageService = context.read<PropertyStore>().imageService;
    final property = widget.property;

    if (property != null) {
      _titleController.text = property.title;
      _neighborhoodController.text = property.neighborhood;
      _priceController.text = property.monthlyRent.toString();
      _descriptionController.text = property.description;
      _ownerNameController.text = property.ownerName;
      _ownerPhoneController.text = property.ownerPhone;
      _category = property.category;
      _bedrooms = property.bedrooms;
      _bathrooms = property.bathrooms;
      _images = List.of(property.imagePaths);
    }
  }

  @override
  void dispose() {
    if (!_submitted) {
      for (final path in _newImages) {
        unawaited(_imageService.deleteIfManaged(path));
      }
    }

    _titleController.dispose();
    _neighborhoodController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhotos() async {
    if (_isPicking) {
      return;
    }

    final remaining = PropertyImageService.maxPhotos - _images.length;
    if (remaining <= 0) {
      _showMessage(
        'You can add up to ${PropertyImageService.maxPhotos} photos.',
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add property photos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Take a photo'),
                  subtitle: const Text('Use your phone camera'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Choose from gallery'),
                  subtitle: Text('Select up to $remaining photo(s)'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    setState(() => _isPicking = true);

    try {
      if (source == ImageSource.camera) {
        final path = await _imageService.pickFromCamera();
        if (path != null && mounted) {
          setState(() {
            _images = [..._images, path];
            _newImages.add(path);
          });
        }
      } else {
        final paths = await _imageService.pickFromGallery(
          remainingSlots: remaining,
        );
        if (paths.isNotEmpty && mounted) {
          setState(() {
            _images = [..._images, ...paths];
            _newImages.addAll(paths);
          });
        }
      }
    } on PhotoPickerException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not add photos. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _removePhoto(String path) async {
    final isNew = _newImages.contains(path);

    setState(() {
      _images = _images.where((item) => item != path).toList();
    });

    if (isNew) {
      _newImages.remove(path);
      await _imageService.deleteIfManaged(path);
    } else {
      _removedImages.add(path);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage('Please complete the highlighted fields.');
      return;
    }

    if (_images.isEmpty) {
      _showMessage('Add at least one photo so renters can see the property.');
      return;
    }

    final store = context.read<PropertyStore>();
    final draft = PropertyDraft(
      title: _titleController.text.trim(),
      category: _category,
      neighborhood: _neighborhoodController.text.trim(),
      city: 'Dire Dawa',
      monthlyRent: int.parse(_priceController.text.trim()),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      description: _descriptionController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      ownerPhone: _ownerPhoneController.text.trim(),
      imagePaths: List.of(_images),
    );

    setState(() => _isSaving = true);

    try {
      final Property? saved;
      if (widget.isEditing) {
        saved = await store.updateProperty(widget.property!.id, draft);
      } else {
        saved = await store.addProperty(draft);
      }

      _submitted = true;
      _newImages.clear();

      for (final path in _removedImages) {
        await store.imageService.deleteIfManaged(path);
      }
      _removedImages.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Listing updated successfully.'
                : 'Listing published locally. It is now visible on Home.',
          ),
        ),
      );

      Navigator.pop(context, saved);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showMessage('Could not save this listing. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit listing' : 'List a property')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              _localNotice(),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Property details',
                subtitle: 'Describe the home renters will see.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Listing title *',
                  hintText: 'e.g. Spacious family house in Sabian',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Enter a listing title';
                  }
                  if (text.length < 5) {
                    return 'Use at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              _CategorySelector(
                value: _category,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Location',
                subtitle: 'RentEasy currently focuses on Dire Dawa.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _neighborhoodController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Neighborhood *',
                  hintText: 'e.g. Sabian, Kefira, Magala',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Enter a neighborhood';
                  }
                  if (text.length < 3) {
                    return 'Use at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: 'Dire Dawa',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  suffixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                  helperText: 'More Ethiopian cities are coming soon.',
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Price and size',
                subtitle: 'Set the monthly rent and room count.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Monthly rent *',
                  hintText: 'e.g. 8500',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'ETB / month',
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Enter the monthly rent';
                  }
                  final rent = int.tryParse(text);
                  if (rent == null || rent <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (rent > 10000000) {
                    return 'Amount looks too high';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CounterField(
                      label: 'Bedrooms',
                      icon: Icons.bed_outlined,
                      value: _bedrooms,
                      min: 1,
                      max: 20,
                      onChanged: (value) => setState(() => _bedrooms = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CounterField(
                      label: 'Bathrooms',
                      icon: Icons.bathtub_outlined,
                      value: _bathrooms,
                      min: 1,
                      max: 20,
                      onChanged: (value) => setState(() => _bathrooms = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Description',
                subtitle: 'Mention condition, utilities and nearby places.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 7,
                maxLength: 800,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'About the property *',
                  hintText:
                      'e.g. Bright two-bedroom apartment with a modern kitchen, '
                      'parking and reliable water supply.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Write a short description';
                  }
                  if (text.length < 20) {
                    return 'Use at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _SectionTitle(
                title: 'Photos',
                subtitle:
                    'Add up to ${PropertyImageService.maxPhotos} photos. '
                    'The first photo is the cover.',
              ),
              const SizedBox(height: 12),
              _photoGrid(),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Contact information',
                subtitle: 'Renters will use this to reach you.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your name or agency *',
                  hintText: 'e.g. Ahmed Ali',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Enter a contact name';
                  }
                  if (text.length < 2) {
                    return 'Name is too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerPhoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone number *',
                  hintText: '09xxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText: 'Ethiopian mobile number',
                ),
                validator: validateEthiopianPhone,
                onFieldSubmitted: (_) {
                  if (!_isSaving) {
                    _submit();
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        editing ? Icons.save_outlined : Icons.publish_rounded,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : editing
                      ? 'Save changes'
                      : 'Publish listing',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _localNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_android_rounded, size: 19, color: AppColors.primary),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Local mode: this listing is saved on this phone only. '
              'Cloud sync and admin verification arrive with the backend phase.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1,
            children: [
              for (var index = 0; index < _images.length; index++)
                _PhotoTile(
                  path: _images[index],
                  isCover: index == 0,
                  onRemove: () => _removePhoto(_images[index]),
                ),
            ],
          ),
        if (_images.isNotEmpty) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isPicking ? null : _pickPhotos,
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _isPicking
                  ? 'Opening...'
                  : _images.isEmpty
                  ? 'Add photos'
                  : 'Add more photos (${_images.length}/${PropertyImageService.maxPhotos})',
            ),
          ),
        ),
        if (_images.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Take a photo or choose from your gallery.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PropertyCategory.all.map((category) {
            final selected = category == value;
            return ChoiceChip(
              label: Text(category),
              avatar: Icon(
                categoryIcon(category),
                size: 17,
                color: selected ? Colors.white : AppColors.primary,
              ),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => onChanged(category),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stepButton(
                Icons.remove_rounded,
                enabled: value > min,
                onPressed: () => onChanged(value - 1),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              _stepButton(
                Icons.add_rounded,
                enabled: value < max,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepButton(
    IconData icon, {
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.isCover,
    required this.onRemove,
  });

  final String path;
  final bool isCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: AppColors.background,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                ),
              );
            },
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
