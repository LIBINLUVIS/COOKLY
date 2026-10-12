import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pantry_item.dart';
import '../../services/inventory_api_service.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';

class AddPantryItemResult {
  const AddPantryItemResult.added({
    required this.itemId,
    required this.isExpiryPending,
  }) : isUnauthorized = false;
  const AddPantryItemResult.unauthorized()
    : itemId = null,
      isExpiryPending = false,
      isUnauthorized = true;

  final int? itemId;

  /// True when no shelf life was chosen and the server is estimating it.
  final bool isExpiryPending;
  final bool isUnauthorized;
}

/// Bottom-sheet form that posts a new item to `POST /api/inventory/add-item`.
/// Pops with an [AddPantryItemResult], or null if the user cancels.
class AddPantryItemSheet extends StatefulWidget {
  const AddPantryItemSheet({super.key});

  @override
  State<AddPantryItemSheet> createState() => _AddPantryItemSheetState();
}

class _AddPantryItemSheetState extends State<AddPantryItemSheet> {
  static const _units = ['pcs', 'g', 'kg', 'ml', 'L', 'bunch', 'pack'];

  /// 0 means "Auto": no expiry is sent and the server estimates it in the background.
  static const _shelfLifeOptions = {
    0: 'Auto (Cookly estimates)',
    2: '2 days (Urgent)',
    5: '5 days (Fresh)',
    10: '10 days',
    30: '30 days',
    90: '90+ days (Dry)',
  };

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  PantryCategory _category = PantryCategory.vegetable;
  String _unit = _units.first;
  int _shelfLifeDays = 0;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final itemId = await InventoryApiService.instance.addItem(
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        unit: _unit,
        category: _category,
        expiresAt: _shelfLifeDays == 0
            ? null
            : DateTime.now().add(Duration(days: _shelfLifeDays)),
      );
      if (mounted) {
        Navigator.of(context).pop(
          AddPantryItemResult.added(
            itemId: itemId,
            isExpiryPending: _shelfLifeDays == 0,
          ),
        );
      }
    } on InventoryApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        Navigator.of(context).pop(const AddPantryItemResult.unauthorized());
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CooklySpacing.marginMobile,
            12,
            CooklySpacing.marginMobile,
            CooklySpacing.marginMobile,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CooklyColors.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(CooklyRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: CooklySpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to Pantry',
                        style: CooklyTextStyles.headlineMd,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      style: IconButton.styleFrom(
                        backgroundColor: CooklyColors.surfaceContainer,
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: CooklyColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CooklySpacing.md),
                _Field(
                  label: 'Ingredient Name',
                  child: TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: _inputStyle,
                    decoration: _decoration(hint: 'e.g. Ripe Hass Avocados'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Item name is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Category',
                        child: DropdownButtonFormField<PantryCategory>(
                          initialValue: _category,
                          isExpanded: true,
                          style: _inputStyle,
                          decoration: _decoration(),
                          icon: const Icon(
                            Icons.expand_more,
                            color: CooklyColors.onSurfaceVariant,
                          ),
                          items: [
                            for (final category in PantryCategory.values)
                              DropdownMenuItem(
                                value: category,
                                child: Text(category.label),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _category = value ?? _category),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Quantity',
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: _inputStyle,
                          decoration: _decoration(hint: 'e.g. 2'),
                          validator: (value) {
                            final quantity = int.tryParse(value?.trim() ?? '');
                            if (quantity == null || quantity <= 0) {
                              return 'Enter a quantity';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Unit',
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          isExpanded: true,
                          style: _inputStyle,
                          decoration: _decoration(),
                          icon: const Icon(
                            Icons.expand_more,
                            color: CooklyColors.onSurfaceVariant,
                          ),
                          items: [
                            for (final unit in _units)
                              DropdownMenuItem(value: unit, child: Text(unit)),
                          ],
                          onChanged: (value) =>
                              setState(() => _unit = value ?? _unit),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Est. Shelf Life',
                        child: DropdownButtonFormField<int>(
                          initialValue: _shelfLifeDays,
                          isExpanded: true,
                          style: _inputStyle,
                          decoration: _decoration(),
                          icon: const Icon(
                            Icons.expand_more,
                            color: CooklyColors.onSurfaceVariant,
                          ),
                          items: [
                            for (final option in _shelfLifeOptions.entries)
                              DropdownMenuItem(
                                value: option.key,
                                child: Text(option.value),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _shelfLifeDays = value ?? _shelfLifeDays,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: CooklyTextStyles.bodySm.copyWith(
                      color: CooklyColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: _buttonStyle(
                          background: CooklyColors.surfaceContainer,
                          foreground: CooklyColors.onSurface,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: _buttonStyle(
                          background: CooklyColors.primary,
                          foreground: CooklyColors.onPrimary,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CooklyColors.onPrimary,
                                ),
                              )
                            : const Text('Save to Pantry'),
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
  }

  TextStyle get _inputStyle =>
      CooklyTextStyles.bodyMd.copyWith(color: CooklyColors.onSurface);

  InputDecoration _decoration({String? hint}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(CooklyRadius.xl),
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: CooklyTextStyles.bodyMd.copyWith(
        color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: CooklyColors.surfaceContainerLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(CooklyColors.primary, 1.5),
      errorBorder: border(CooklyColors.error, 1),
      focusedErrorBorder: border(CooklyColors.error, 1.5),
    );
  }

  ButtonStyle _buttonStyle({
    required Color background,
    required Color foreground,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.6),
      disabledForegroundColor: foreground.withValues(alpha: 0.8),
      minimumSize: const Size.fromHeight(52),
      textStyle: CooklyTextStyles.labelLg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CooklyRadius.xl),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CooklyTextStyles.labelMd.copyWith(
            color: CooklyColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
