import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';

class AccountFilters extends StatefulWidget {
  const AccountFilters({super.key});

  @override
  State<AccountFilters> createState() => _AccountFiltersState();
}

class _AccountFiltersState extends State<AccountFilters> {
  final _searchController = TextEditingController();
  String? _selectedAsset;
  bool _showOnlyNonZero = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    context.read<AccountBloc>().add(
      FilterBalancesByAsset(query.isEmpty ? null : query.toUpperCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state is! AccountLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterChips(state),
              const SizedBox(height: 16),
              _buildQuickFilters(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tune, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          'FILTRI ASSET',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        if (_hasActiveFilters())
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cerca asset (es. BTC, ETH, USDC...)',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.mutedTextColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.mutedTextColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: AppTheme.cardColor,
      ),
    );
  }

  Widget _buildFilterChips(AccountLoaded state) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildShowNonZeroChip(),
        if (state.availableAssets.isNotEmpty) _buildAssetFilterChip(state),
      ],
    );
  }

  Widget _buildShowNonZeroChip() {
    return FilterChip(
      selected: _showOnlyNonZero,
      label: const Text('Solo con saldo'),
      onSelected: (selected) {
        setState(() {
          _showOnlyNonZero = selected;
        });
        context.read<AccountBloc>().add(ShowOnlyNonZeroBalances(selected));
      },
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _showOnlyNonZero
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildAssetFilterChip(AccountLoaded state) {
    return FilterChip(
      selected: _selectedAsset != null,
      label: Text(
        _selectedAsset != null ? 'Asset: $_selectedAsset' : 'Tutti gli asset',
      ),
      onSelected: (_) => _showAssetSelectionDialog(state),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _selectedAsset != null
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildQuickFilters(AccountLoaded state) {
    final quickAssets = ['BTC', 'ETH', 'USDC', 'BNB'];
    final availableQuickAssets =
        quickAssets
            .where((asset) => state.availableAssets.contains(asset))
            .toList();

    if (availableQuickAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtri Rapidi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              availableQuickAssets.map((asset) {
                final isSelected = _selectedAsset == asset;
                return GestureDetector(
                  onTap: () => _selectAsset(isSelected ? null : asset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.mutedTextColor.withValues(
                                  alpha: 0.3,
                                ),
                      ),
                    ),
                    child: Text(
                      asset,
                      style: TextStyle(
                        color:
                            isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showAssetSelectionDialog(AccountLoaded state) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona Asset'),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                groupValue: _selectedAsset,
                onChanged: (value) {
                  if (value != null) {
                    _selectAsset(value);
                    Navigator.of(context).pop();
                  }
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.availableAssets.length,
                  itemBuilder: (context, index) {
                    final asset = state.availableAssets[index];
                    return RadioListTile<String>(
                      title: Text(
                        asset,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: asset,
                      activeColor: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectAsset(null);
                  Navigator.of(context).pop();
                },
                child: const Text('Tutti'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );
  }

  void _selectAsset(String? asset) {
    setState(() {
      _selectedAsset = asset;
    });
    if (asset != null) {
      _searchController.text = asset;
    } else {
      _searchController.clear();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedAsset = null;
      _showOnlyNonZero = true;
    });
    _searchController.clear();
    context.read<AccountBloc>().add(const FilterBalancesByAsset(null));
    context.read<AccountBloc>().add(const ShowOnlyNonZeroBalances(true));
  }

  bool _hasActiveFilters() {
    return _selectedAsset != null ||
        !_showOnlyNonZero ||
        _searchController.text.isNotEmpty;
  }
}
