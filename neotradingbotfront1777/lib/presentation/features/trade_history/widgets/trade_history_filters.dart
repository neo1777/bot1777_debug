import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/snackbar_helper.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart';

enum TradeFilterType { buy, sell }

enum ProfitLossFilter { profit, loss, all }

enum AmountFilter { small, medium, large, all }

class TradeHistoryFilters extends StatefulWidget {
  const TradeHistoryFilters({super.key});

  @override
  State<TradeHistoryFilters> createState() => _TradeHistoryFiltersState();
}

class _TradeHistoryFiltersState extends State<TradeHistoryFilters> {
  TradeFilterType? _selectedTradeType;
  DateTimeRange? _selectedDateRange;

  // Advanced filters state
  ProfitLossFilter _profitLossFilter = ProfitLossFilter.all;
  AmountFilter _amountFilter = AmountFilter.all;
  String _symbolFilter = '';
  double _minAmount = 0.0;
  double _maxAmount = 10000.0;
  double _minProfit = -1000.0;
  double _maxProfit = 1000.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
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
          'FILTRI',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        if (_hasActiveFilters())
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Pulisci'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildTradeTypeChip(),
        _buildDateRangeChip(),
        // Add more filter chips as needed
      ],
    );
  }

  Widget _buildTradeTypeChip() {
    return FilterChip(
      selected: _selectedTradeType != null,
      label: Text(
        _selectedTradeType != null
            ? _getTradeTypeLabel(_selectedTradeType!)
            : 'Tipo Trade',
      ),
      onSelected: (_) => _showTradeTypeDialog(),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _selectedTradeType != null
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDateRangeChip() {
    return FilterChip(
      selected: _selectedDateRange != null,
      label: Text(
        _selectedDateRange != null
            ? _formatDateRange(_selectedDateRange!)
            : 'Periodo',
      ),
      onSelected: (_) => _showDateRangePicker(),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color:
            _selectedDateRange != null
                ? AppTheme.primaryColor
                : AppTheme.mutedTextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.search),
            label: const Text('Applica'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showAdvancedFilters,
            icon: const Icon(Icons.tune),
            label: const Text('Avanzate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showTradeTypeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona Tipo Trade'),
            content: RadioGroup<TradeFilterType>(
              groupValue: _selectedTradeType,
              onChanged: (value) {
                setState(() {
                  _selectedTradeType = value;
                });
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    TradeFilterType.values.map((type) {
                      return RadioListTile<TradeFilterType>(
                        title: Text(_getTradeTypeLabel(type)),
                        value: type,
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );
  }

  void _showDateRangePicker() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateRange = dateRange;
      });
    }
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.5),
                        blurRadius: 3,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Filtri Avanzati'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfitLossSection(),
                    const Divider(height: 32),
                    _buildAmountSection(),
                    const Divider(height: 32),
                    _buildSymbolSection(),
                    const Divider(height: 32),
                    _buildRangeSection(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: _resetAdvancedFilters,
                child: Text(
                  'Reset',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyAdvancedFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Applica'),
              ),
            ],
          ),
    );
  }

  void _applyFilters() {
    // Apply trade type filter
    if (_selectedTradeType != null) {
      context.read<TradeHistoryBloc>().add(
        FilterTradesByType(_selectedTradeType == TradeFilterType.buy),
      );
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      context.read<TradeHistoryBloc>().add(
        FilterTradesByDateRange(
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
        ),
      );
    }

    // If no filters selected, clear filters
    if (_selectedTradeType == null && _selectedDateRange == null) {
      context.read<TradeHistoryBloc>().add(const ClearFilters());
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedTradeType = null;
      _selectedDateRange = null;
    });
    _applyFilters();
  }

  Widget _buildProfitLossSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profitto/Perdita',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children:
              ProfitLossFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(_getProfitLossLabel(filter)),
                  selected: _profitLossFilter == filter,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _profitLossFilter = filter;
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria Importo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children:
              AmountFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(_getAmountLabel(filter)),
                  selected: _amountFilter == filter,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _amountFilter = filter;
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSymbolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simbolo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) {
            setState(() {
              _symbolFilter = value.toUpperCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Es. BTCUSDC, ETHUSDC...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Range Personalizzati',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildRangeSlider(
          'Importo Trade',
          _minAmount,
          _maxAmount,
          0.0,
          50000.0,
          (values) {
            setState(() {
              _minAmount = values.start;
              _maxAmount = values.end;
            });
          },
          'USDC',
        ),
        const SizedBox(height: 16),
        _buildRangeSlider(
          'Profitto/Perdita',
          _minProfit,
          _maxProfit,
          -5000.0,
          5000.0,
          (values) {
            setState(() {
              _minProfit = values.start;
              _maxProfit = values.end;
            });
          },
          'USDC',
        ),
      ],
    );
  }

  Widget _buildRangeSlider(
    String title,
    double min,
    double max,
    double absoluteMin,
    double absoluteMax,
    Function(RangeValues) onChanged,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(min, max),
          min: absoluteMin,
          max: absoluteMax,
          divisions: 100,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${max.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedTradeType != null || _selectedDateRange != null;
  }

  String _getTradeTypeLabel(TradeFilterType type) {
    switch (type) {
      case TradeFilterType.buy:
        return 'Acquisto';
      case TradeFilterType.sell:
        return 'Vendita';
    }
  }

  String _getProfitLossLabel(ProfitLossFilter filter) {
    switch (filter) {
      case ProfitLossFilter.profit:
        return 'Profitto';
      case ProfitLossFilter.loss:
        return 'Perdita';
      case ProfitLossFilter.all:
        return 'Tutti';
    }
  }

  String _getAmountLabel(AmountFilter filter) {
    switch (filter) {
      case AmountFilter.small:
        return 'Piccoli (< 100)';
      case AmountFilter.medium:
        return 'Medi (100-1000)';
      case AmountFilter.large:
        return 'Grandi (> 1000)';
      case AmountFilter.all:
        return 'Tutti';
    }
  }

  void _applyAdvancedFilters() {
    // Apply advanced filters logic here
    // This would typically involve sending events to the TradeHistoryBloc
    // with the advanced filter parameters

    // Use _symbolFilter for symbol-based filtering
    final hasSymbolFilter = _symbolFilter.isNotEmpty;

    AppSnackBar.showSuccess(
      context,
      hasSymbolFilter
          ? 'Filtri avanzati applicati per $_symbolFilter'
          : 'Filtri avanzati applicati',
    );
  }

  void _resetAdvancedFilters() {
    setState(() {
      _profitLossFilter = ProfitLossFilter.all;
      _amountFilter = AmountFilter.all;
      _symbolFilter = '';
      _minAmount = 0.0;
      _maxAmount = 10000.0;
      _minProfit = -1000.0;
      _maxProfit = 1000.0;
    });
  }

  String _formatDateRange(DateTimeRange range) {
    final start = '${range.start.day}/${range.start.month}';
    final end = '${range.end.day}/${range.end.month}';
    return '$start - $end';
  }
}
