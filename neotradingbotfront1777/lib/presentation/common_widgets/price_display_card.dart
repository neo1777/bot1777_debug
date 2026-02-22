import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/core/utils/price_formatter.dart';

class PriceDisplayCard extends StatefulWidget {
  const PriceDisplayCard({required this.symbol, super.key, this.priceData});

  final String symbol;
  final PriceData? priceData;

  @override
  State<PriceDisplayCard> createState() => _PriceDisplayCardState();
}

class _PriceDisplayCardState extends State<PriceDisplayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PriceDisplayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.priceData?.currentPrice != widget.priceData?.currentPrice) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPriceInfo(),
            const SizedBox(height: 16),
            _buildPriceStats(),
          ],
        ),
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
        Expanded(
          child: Text(
            'PREZZO ${widget.symbol}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppTheme.textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (widget.priceData != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriceChangeColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getPriceChangeColor().withValues(alpha: 0.3),
              ),
            ),
            child: Tooltip(
              message: 'Variazione prezzo nelle ultime 24 ore',
              child: Text(
                '24H',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getPriceChangeColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    if (widget.priceData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '—',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedTextColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.trending_flat,
                color: AppTheme.mutedTextColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '0.00%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mutedTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${PriceFormatter.format(widget.priceData!.currentPrice)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                widget.priceData!.priceChange24h >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: _getPriceChangeColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.priceData!.priceChange24h >= 0 ? '+' : ''}${widget.priceData!.priceChange24h.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _getPriceChangeColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${PriceFormatter.format(widget.priceData!.priceChangeAbsolute24h)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getPriceChangeColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStats() {
    if (widget.priceData == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Alto 24h',
                '\$${PriceFormatter.format(widget.priceData!.highPrice24h)}',
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Basso 24h',
                '\$${PriceFormatter.format(widget.priceData!.lowPrice24h)}',
                AppTheme.errorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Volume 24h',
                _formatVolume(widget.priceData!.volume24h),
                AppTheme.mutedTextColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Ultimo aggiornamento',
                _formatTimestamp(widget.priceData!.timestamp),
                AppTheme.mutedTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getPriceChangeColor() {
    if (widget.priceData == null) return AppTheme.mutedTextColor;
    return widget.priceData!.priceChange24h >= 0
        ? AppTheme.successColor
        : AppTheme.errorColor;
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toStringAsFixed(2);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s fa';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m fa';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
