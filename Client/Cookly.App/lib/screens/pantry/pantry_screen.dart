import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../models/pantry_item.dart';
import '../../navigation/sign_out.dart';
import '../../services/inventory_api_service.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_bottom_nav.dart';
import '../../widgets/cookly_top_bar.dart';
import '../../widgets/profile_sheet.dart';
import 'add_pantry_item_sheet.dart';
import 'pantry_item_card.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key, required this.session});

  final CooklySession session;

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  /// Stepper taps are batched into one PATCH per item after this pause.
  static const _quantitySyncDelay = Duration(milliseconds: 500);

  final _api = InventoryApiService.instance;
  final _searchController = TextEditingController();

  List<PantryItem> _items = [];
  bool _isLoading = true;
  String? _loadError;
  PantryCategory? _categoryFilter;

  final Map<int, int> _unsyncedQuantityChanges = {};
  final Map<int, Timer> _quantitySyncTimers = {};
  final Map<int, Future<void>> _quantitySyncsInFlight = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadItems();
  }

  @override
  void dispose() {
    for (final timer in _quantitySyncTimers.values) {
      timer.cancel();
    }
    // Send taps still waiting on the debounce so leaving the screen doesn't drop them.
    for (final itemId in _unsyncedQuantityChanges.keys.toList()) {
      _syncQuantity(itemId);
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final items = await _api.listItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on InventoryApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _handleUnauthorized();
        return;
      }
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    }
  }

  void _handleUnauthorized() {
    signOutAndShowSplash(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
  }

  int _indexOf(int itemId) => _items.indexWhere((item) => item.itemId == itemId);

  void _applyQuantityChange(int itemId, int change) {
    final index = _indexOf(itemId);
    if (index == -1) return;
    setState(() {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + change);
    });
  }

  static int _quantityStep(PantryItem item) {
    final unit = item.unit?.trim().toLowerCase();
    return unit == 'g' || unit == 'ml' ? 50 : 1;
  }

  void _changeQuantity(PantryItem item, {required bool increase}) {
    final step = _quantityStep(item);
    final change = increase ? step : -math.min(step, item.quantity);
    if (change == 0) return;

    _applyQuantityChange(item.itemId, change);
    _unsyncedQuantityChanges.update(item.itemId, (pending) => pending + change, ifAbsent: () => change);
    _quantitySyncTimers[item.itemId]?.cancel();
    _quantitySyncTimers[item.itemId] = Timer(_quantitySyncDelay, () => _syncQuantity(item.itemId));
  }

  /// Chains syncs per item so two PATCHes for the same item never race on the server.
  void _syncQuantity(int itemId) {
    _quantitySyncTimers.remove(itemId)?.cancel();
    final previous = _quantitySyncsInFlight[itemId] ?? Future<void>.value();
    final next = previous.then((_) => _sendQuantityChange(itemId));
    _quantitySyncsInFlight[itemId] = next;
    next.whenComplete(() {
      if (identical(_quantitySyncsInFlight[itemId], next)) _quantitySyncsInFlight.remove(itemId);
    });
  }

  Future<void> _sendQuantityChange(int itemId) async {
    final change = _unsyncedQuantityChanges.remove(itemId);
    if (change == null || change == 0) return;

    try {
      final confirmed = await _api.updateQuantity(itemId: itemId, change: change);
      // Newer taps already applied optimistically will carry their own correction.
      if (!mounted || confirmed == null || _unsyncedQuantityChanges.containsKey(itemId)) return;
      final index = _indexOf(itemId);
      if (index != -1 && _items[index].quantity != confirmed) {
        setState(() => _items[index] = _items[index].copyWith(quantity: confirmed));
      }
    } on InventoryApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _handleUnauthorized();
        return;
      }
      _applyQuantityChange(itemId, -change);
      _showMessage(error.message);
    }
  }

  Future<void> _deleteItem(PantryItem item) async {
    _quantitySyncTimers.remove(item.itemId)?.cancel();
    final unsynced = _unsyncedQuantityChanges.remove(item.itemId) ?? 0;
    final index = _indexOf(item.itemId);
    if (index == -1) return;
    setState(() => _items.removeAt(index));

    try {
      await _api.deleteItem(item.itemId);
      if (mounted) _showMessage('Removed ${item.name} from your pantry');
    } on InventoryApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _handleUnauthorized();
        return;
      }
      setState(() {
        _items.insert(
          math.min(index, _items.length),
          item.copyWith(quantity: item.quantity - unsynced),
        );
      });
      _showMessage(error.message);
    }
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<AddPantryItemResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CooklyColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CooklyRadius.sheet)),
      ),
      builder: (_) => const AddPantryItemSheet(),
    );
    if (!mounted || result == null) return;
    if (result == AddPantryItemResult.unauthorized) {
      _handleUnauthorized();
      return;
    }
    _showMessage('Added to your pantry');
    _loadItems();
  }

  void _onTabSelected(CooklyTab tab) {
    switch (tab) {
      case CooklyTab.kitchen:
        Navigator.of(context).pop();
      case CooklyTab.pantry:
        break;
      case CooklyTab.profile:
        showProfileSheet(context, widget.session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCategories = [
      for (final category in PantryCategory.values)
        if (_items.any((item) => item.category == category)) category,
    ];
    // A filter whose last item was deleted no longer has a pill; fall back to "All".
    final activeFilter = presentCategories.contains(_categoryFilter) ? _categoryFilter : null;
    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = [
      for (final item in _items)
        if ((activeFilter == null || item.category == activeFilter) &&
            (query.isEmpty || item.name.toLowerCase().contains(query)))
          item,
    ];
    final urgentItems = _items
        .where((item) => (item.daysUntilExpiry ?? 99) <= 2)
        .toList()
      ..sort((a, b) => a.daysUntilExpiry!.compareTo(b.daysUntilExpiry!));

    return Scaffold(
      backgroundColor: CooklyColors.surface,
      bottomNavigationBar: CooklyBottomNav(current: CooklyTab.pantry, onSelected: _onTabSelected),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CooklyTopBar(
              session: widget.session,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back, color: CooklyColors.onSurface),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: CooklyColors.primary,
                onRefresh: _loadItems,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    CooklySpacing.marginMobile,
                    CooklySpacing.sm,
                    CooklySpacing.marginMobile,
                    CooklySpacing.lg,
                  ),
                  children: [
                    _PantryHeader(
                      itemCount: _items.length,
                      expiringSoonCount: _items.where((item) => item.isExpiringSoon).length,
                      onAddItem: _openAddSheet,
                    ),
                    const SizedBox(height: CooklySpacing.md),
                    _PantrySearchField(controller: _searchController),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: CooklySpacing.md),
                      _CategoryPills(
                        items: _items,
                        categories: presentCategories,
                        selected: activeFilter,
                        onSelected: (category) => setState(() => _categoryFilter = category),
                      ),
                    ],
                    if (urgentItems.isNotEmpty) ...[
                      const SizedBox(height: CooklySpacing.md),
                      _ExpiryAlertBanner(urgentItems: urgentItems),
                    ],
                    const SizedBox(height: CooklySpacing.md),
                    ..._buildItemsSection(visibleItems),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemsSection(List<PantryItem> visibleItems) {
    if (_isLoading && _items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(color: CooklyColors.primary)),
        ),
      ];
    }
    if (_loadError != null && _items.isEmpty) {
      return [
        _PantryMessage(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your pantry",
          message: _loadError!,
          actionLabel: 'Try again',
          onAction: _loadItems,
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        _PantryMessage(
          icon: Icons.kitchen_outlined,
          title: 'Your pantry is empty',
          message: 'Add the ingredients you have at home so Cookly can plan meals around them.',
          actionLabel: 'Add Item',
          onAction: _openAddSheet,
        ),
      ];
    }
    if (visibleItems.isEmpty) {
      return const [
        _PantryMessage(
          icon: Icons.search_off,
          title: 'No matching items',
          message: 'Try a different search or category.',
        ),
      ];
    }
    return [
      for (final item in visibleItems)
        Padding(
          key: ValueKey(item.itemId),
          padding: const EdgeInsets.only(bottom: 12),
          child: PantryItemCard(
            item: item,
            onDelete: () => _deleteItem(item),
            onIncrease: () => _changeQuantity(item, increase: true),
            onDecrease: item.quantity > 0 ? () => _changeQuantity(item, increase: false) : null,
          ),
        ),
    ];
  }
}

class _PantryHeader extends StatelessWidget {
  const _PantryHeader({
    required this.itemCount,
    required this.expiringSoonCount,
    required this.onAddItem,
  });

  final int itemCount;
  final int expiringSoonCount;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Pantry', style: CooklyTextStyles.headlineLgMobile),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: '$itemCount ${itemCount == 1 ? 'item' : 'items'} in stock',
                  children: [
                    if (expiringSoonCount > 0) ...[
                      const TextSpan(text: '  •  '),
                      TextSpan(
                        text: '$expiringSoonCount expiring soon',
                        style: const TextStyle(
                          color: CooklyColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                style: CooklyTextStyles.bodySm,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Item'),
          style: FilledButton.styleFrom(
            backgroundColor: CooklyColors.primary,
            foregroundColor: CooklyColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: CooklySpacing.md, vertical: 10),
            textStyle: CooklyTextStyles.labelMd,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CooklyRadius.xl)),
          ),
        ),
      ],
    );
  }
}

class _PantrySearchField extends StatelessWidget {
  const _PantrySearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: CooklyTextStyles.bodyMd.copyWith(color: CooklyColors.onSurface),
      decoration: InputDecoration(
        hintText: 'Search pantry ingredients...',
        hintStyle: CooklyTextStyles.bodyMd.copyWith(
          color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        prefixIcon: const Icon(Icons.search, size: 20, color: CooklyColors.onSurfaceVariant),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18, color: CooklyColors.onSurfaceVariant),
              ),
        filled: true,
        fillColor: CooklyColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CooklyRadius.card),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.items,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<PantryItem> items;
  final List<PantryCategory> categories;
  final PantryCategory? selected;
  final ValueChanged<PantryCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _pill('All (${items.length})', isSelected: selected == null, onTap: () => onSelected(null)),
          for (final category in categories)
            _pill(
              '${category.label} (${items.where((item) => item.category == category).length})',
              isSelected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, {required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: CooklySpacing.sm),
      child: Material(
        color: isSelected ? CooklyColors.secondary : CooklyColors.surfaceContainer,
        borderRadius: BorderRadius.circular(CooklyRadius.full),
        elevation: isSelected ? 1 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CooklyRadius.full),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CooklySpacing.md, vertical: CooklySpacing.sm),
            child: Text(
              label,
              style: CooklyTextStyles.labelMd.copyWith(
                color: isSelected ? CooklyColors.onSecondary : CooklyColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiryAlertBanner extends StatelessWidget {
  const _ExpiryAlertBanner({required this.urgentItems});

  final List<PantryItem> urgentItems;

  String get _message {
    final names = urgentItems.map((item) => item.name).toList();
    final subject = switch (names.length) {
      1 => '${names[0]} needs',
      2 => '${names[0]} and ${names[1]} need',
      _ => '${names[0]}, ${names[1]} and ${names.length - 2} more need',
    };
    return '$subject love within 48 hours. Ready to cook something delicious?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.primaryFixed.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(CooklyRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: CooklyColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer, size: 20, color: CooklyColors.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Urgent Culinary Check', style: CooklyTextStyles.headlineSm),
                const SizedBox(height: 2),
                Text(_message, style: CooklyTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryMessage extends StatelessWidget {
  const _PantryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CooklySpacing.xl, horizontal: CooklySpacing.md),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CooklyColors.secondaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: CooklyColors.secondary),
          ),
          const SizedBox(height: 12),
          Text(title, style: CooklyTextStyles.headlineSm, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(message, style: CooklyTextStyles.bodySm, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: CooklySpacing.md),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: CooklyColors.primary),
              child: Text(actionLabel!, style: CooklyTextStyles.labelLg.copyWith(color: CooklyColors.primary)),
            ),
          ],
        ],
      ),
    );
  }
}
