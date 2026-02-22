import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';

class OrdersFilters extends StatefulWidget {
  const OrdersFilters({super.key});

  @override
  State<OrdersFilters> createState() => _OrdersFiltersState();
}

class _OrdersFiltersState extends State<OrdersFilters> {
  String? _selectedType;
  String? _selectedSide;
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is! OrdersLoaded) {
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
              _buildFilterChips(state),
              const SizedBox(height: 16),
              _buildQuickFilters(),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'FILTRI ORDINI',
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

  Widget _buildFilterChips(OrdersLoaded state) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildTypeFilterChip(state),
        _buildSideFilterChip(state),
        _buildStatusFilterChip(state),
      ],
    );
  }

  Widget _buildTypeFilterChip(OrdersLoaded state) {
    return FilterChip(
      selected: _selectedType != null,
      label: Text(
        _selectedType != null ? 'Tipo: $_selectedType' : 'Tipo Ordine',
      ),
      onSelected: (_) => _showTypeSelectionDialog(state),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _selectedType != null
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildSideFilterChip(OrdersLoaded state) {
    return FilterChip(
      selected: _selectedSide != null,
      label: Text(
        _selectedSide != null ? 'Lato: $_selectedSide' : 'Lato Ordine',
      ),
      onSelected: (_) => _showSideSelectionDialog(state),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _selectedSide != null
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildStatusFilterChip(OrdersLoaded state) {
    return FilterChip(
      selected: _selectedStatus != null,
      label: Text(
        _selectedStatus != null ? 'Stato: $_selectedStatus' : 'Stato Ordine',
      ),
      onSelected: (_) => _showStatusSelectionDialog(state),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _selectedStatus != null
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildQuickFilters() {
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
          runSpacing: 4,
          children: [
            _buildQuickFilterChip('BUY', 'side'),
            _buildQuickFilterChip('SELL', 'side'),
            _buildQuickFilterChip('LIMIT', 'type'),
            _buildQuickFilterChip('MARKET', 'type'),
            _buildQuickFilterChip('FILLED', 'status'),
            _buildQuickFilterChip('PENDING', 'status'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(String value, String filterType) {
    bool isSelected = false;

    switch (filterType) {
      case 'side':
        isSelected = _selectedSide == value;
        break;
      case 'type':
        isSelected = _selectedType == value;
        break;
      case 'status':
        isSelected = _selectedStatus == value;
        break;
    }

    Color chipColor;
    switch (value) {
      case 'BUY':
        chipColor = AppTheme.successColor;
        break;
      case 'SELL':
        chipColor = AppTheme.errorColor;
        break;
      case 'FILLED':
        chipColor = AppTheme.successColor;
        break;
      case 'PENDING':
        chipColor = AppTheme.warningColor;
        break;
      default:
        chipColor = AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: () => _selectQuickFilter(value, filterType, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? chipColor.withValues(alpha: 0.2)
                  : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected
                    ? chipColor
                    : AppTheme.mutedTextColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? chipColor : AppTheme.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showTypeSelectionDialog(OrdersLoaded state) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona Tipo Ordine'),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                groupValue: _selectedType,
                onChanged: (value) {
                  if (value != null) {
                    _selectType(value);
                    Navigator.of(context).pop();
                  }
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.availableTypes.length,
                  itemBuilder: (context, index) {
                    final type = state.availableTypes[index];
                    return RadioListTile<String>(
                      title: Text(type),
                      value: type,
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectType(null);
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

  void _showSideSelectionDialog(OrdersLoaded state) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona Lato Ordine'),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                groupValue: _selectedSide,
                onChanged: (value) {
                  if (value != null) {
                    _selectSide(value);
                    Navigator.of(context).pop();
                  }
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.availableSides.length,
                  itemBuilder: (context, index) {
                    final side = state.availableSides[index];
                    return RadioListTile<String>(
                      title: Text(side),
                      value: side,
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectSide(null);
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

  void _showStatusSelectionDialog(OrdersLoaded state) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona Stato Ordine'),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                groupValue: _selectedStatus,
                onChanged: (value) {
                  if (value != null) {
                    _selectStatus(value);
                    Navigator.of(context).pop();
                  }
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.availableStatuses.length,
                  itemBuilder: (context, index) {
                    final status = state.availableStatuses[index];
                    return RadioListTile<String>(
                      title: Text(status),
                      value: status,
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectStatus(null);
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

  void _selectQuickFilter(String value, String filterType, bool isSelected) {
    switch (filterType) {
      case 'side':
        _selectSide(isSelected ? null : value);
        break;
      case 'type':
        _selectType(isSelected ? null : value);
        break;
      case 'status':
        _selectStatus(isSelected ? null : value);
        break;
    }
  }

  void _selectType(String? type) {
    setState(() {
      _selectedType = type;
    });
    context.read<OrdersBloc>().add(FilterOrdersByType(type));
  }

  void _selectSide(String? side) {
    setState(() {
      _selectedSide = side;
    });
    context.read<OrdersBloc>().add(FilterOrdersBySide(side));
  }

  void _selectStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<OrdersBloc>().add(FilterOrdersByStatus(status));
  }

  void _clearAllFilters() {
    setState(() {
      _selectedType = null;
      _selectedSide = null;
      _selectedStatus = null;
    });
    context.read<OrdersBloc>().add(const ClearOrderFilters());
  }

  bool _hasActiveFilters() {
    return _selectedType != null ||
        _selectedSide != null ||
        _selectedStatus != null;
  }
}
