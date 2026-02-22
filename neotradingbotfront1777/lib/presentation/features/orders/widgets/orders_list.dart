import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/snackbar_helper.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';

class OrdersList extends StatelessWidget {
  const OrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrdersLoaded && state.actionMessage != null) {
          if (state.actionMessage!.contains('Errore')) {
            AppSnackBar.showError(context, state.actionMessage!);
          } else {
            AppSnackBar.showSuccess(context, state.actionMessage!);
          }
        }
      },
      child: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is! OrdersLoaded) {
            return const SizedBox.shrink();
          }

          // Caso 1: La lista di ordini *totale* è vuota.
          if (state.orders.isEmpty) {
            return _buildEmptyState(
              title: 'Nessun Ordine Aperto',
              message:
                  'Non ci sono ordini aperti attualmente sull\'exchange per il simbolo selezionato.',
            );
          }

          // Caso 2: La lista filtrata è vuota, ma ci sono ordini totali.
          if (state.filteredOrders.isEmpty) {
            return _buildEmptyState(
              title: 'Nessun Ordine Trovato',
              message:
                  'Nessun ordine corrisponde ai criteri di filtro selezionati.',
            );
          }

          return Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isActionLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
                _buildListHeader(context, state),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.filteredOrders.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder:
                      (context, index) => _buildOrderItem(
                        context,
                        state.filteredOrders[index],
                        index,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppTheme.mutedTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(BuildContext context, OrdersLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LISTA ORDINI (${state.filteredOrders.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (state.filteredOrders.isNotEmpty)
            TextButton.icon(
              onPressed:
                  () => _showCancelAllOrdersDialog(
                    context,
                    state.currentSymbol ?? '',
                  ),
              icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
              label: const Text(
                'CANCELLA TUTTI',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Builder(builder: (context) => _buildSortButton(context)),
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: AppTheme.mutedTextColor),
      tooltip: 'Ordina per',
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'time_desc',
              child: Row(
                children: [
                  Icon(Icons.access_time),
                  SizedBox(width: 8),
                  Text('Più Recenti'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'time_asc',
              child: Row(
                children: [
                  Icon(Icons.access_time),
                  SizedBox(width: 8),
                  Text('Più Vecchi'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'price_desc',
              child: Row(
                children: [
                  Icon(Icons.monetization_on),
                  SizedBox(width: 8),
                  Text('Prezzo Decrescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'price_asc',
              child: Row(
                children: [
                  Icon(Icons.monetization_on),
                  SizedBox(width: 8),
                  Text('Prezzo Crescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'quantity_desc',
              child: Row(
                children: [
                  Icon(Icons.bar_chart),
                  SizedBox(width: 8),
                  Text('Quantità Decrescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'quantity_asc',
              child: Row(
                children: [
                  Icon(Icons.bar_chart),
                  SizedBox(width: 8),
                  Text('Quantità Crescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'fill_desc',
              child: Row(
                children: [
                  Icon(Icons.pie_chart),
                  SizedBox(width: 8),
                  Text('Fill % Decrescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'fill_asc',
              child: Row(
                children: [
                  Icon(Icons.pie_chart),
                  SizedBox(width: 8),
                  Text('Fill % Crescente'),
                ],
              ),
            ),
          ],
      onSelected: (value) {
        OrderSortType sortType;
        switch (value) {
          case 'time_asc':
            sortType = OrderSortType.timeAsc;
            break;
          case 'time_desc':
            sortType = OrderSortType.timeDesc;
            break;
          case 'price_asc':
            sortType = OrderSortType.priceAsc;
            break;
          case 'price_desc':
            sortType = OrderSortType.priceDesc;
            break;
          case 'quantity_asc':
            sortType = OrderSortType.quantityAsc;
            break;
          case 'quantity_desc':
            sortType = OrderSortType.quantityDesc;
            break;
          case 'fill_asc':
            sortType = OrderSortType.fillAsc;
            break;
          case 'fill_desc':
            sortType = OrderSortType.fillDesc;
            break;
          default:
            sortType = OrderSortType.timeDesc;
        }

        BlocProvider.of<OrdersBloc>(context).add(SortOrders(sortType));
      },
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderStatus order, int index) {
    final isBuy = order.side == 'BUY';
    final sideColor = isBuy ? AppTheme.successColor : AppTheme.errorColor;
    final sideIcon = isBuy ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Order Side Indicator
              Tooltip(
                message: isBuy ? 'Ordine di ACQUISTO' : 'Ordine di VENDITA',
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sideColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(sideIcon, color: sideColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),

              // Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: sideColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.side,
                            style: TextStyle(
                              color: sideColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.type,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildStatusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Prezzo: ${order.price.toStringAsFixed(8)}',
                          style: TextStyle(
                            color: AppTheme.mutedTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Qtà: ${order.origQty.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: AppTheme.mutedTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order Value & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${(order.price * order.origQty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Valore',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!order.isCompleted && !order.isCancelled)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      tooltip: 'Azioni ordine',
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cancella'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'modify',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Modifica'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info, size: 18),
                                  SizedBox(width: 8),
                                  Text('Dettagli'),
                                ],
                              ),
                            ),
                          ],
                      onSelected:
                          (action) =>
                              _handleOrderAction(context, order, action),
                    ),
                ],
              ),
            ],
          ),

          // Progress Bar for Partially Filled Orders
          if (order.executedQty > 0 && !order.isCompleted) ...[
            const SizedBox(height: 12),
            _buildFillProgressBar(order),
          ],

          // Order Details Row
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOrderDetailChip(
                'ID: ${order.orderId}',
                Icons.tag,
                AppTheme.mutedTextColor,
              ),
              const SizedBox(width: 8),
              _buildOrderDetailChip(
                'Eseguito: ${order.executedQty.toStringAsFixed(6)}',
                Icons.check_circle,
                AppTheme.successColor,
              ),
              const Spacer(),
              Text(
                _formatTimestamp(order.time),
                style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    String statusLabel;

    switch (status.toUpperCase()) {
      case 'FILLED':
        statusColor = AppTheme.successColor;
        statusLabel = 'Completato';
        break;
      case 'PARTIALLY_FILLED':
        statusColor = AppTheme.warningColor;
        statusLabel = 'Parziale';
        break;
      case 'NEW':
      case 'PENDING':
        statusColor = AppTheme.primaryColor;
        statusLabel = 'In Attesa';
        break;
      case 'CANCELED':
      case 'CANCELLED':
        statusColor = AppTheme.errorColor;
        statusLabel = 'Cancellato';
        break;
      case 'EXPIRED':
        statusColor = AppTheme.mutedTextColor;
        statusLabel = 'Scaduto';
        break;
      default:
        statusColor = AppTheme.mutedTextColor;
        statusLabel = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildFillProgressBar(OrderStatus order) {
    final fillPercentage = order.filledPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progresso Riempimento',
              style: TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${fillPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: fillPercentage / 100,
          backgroundColor: AppTheme.mutedTextColor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            fillPercentage < 50
                ? AppTheme.warningColor
                : fillPercentage < 100
                ? AppTheme.primaryColor
                : AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}g fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m fa';
    } else {
      return 'Ora';
    }
  }

  void _handleOrderAction(
    BuildContext context,
    OrderStatus order,
    String action,
  ) {
    switch (action) {
      case 'cancel':
        _showCancelOrderDialog(context, order);
        break;
      case 'modify':
        _showModifyOrderDialog(context, order);
        break;
      case 'details':
        _showOrderDetailsDialog(context, order);
        break;
    }
  }

  void _showCancelOrderDialog(BuildContext context, OrderStatus order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancella Ordine'),
            content: Text(
              'Sei sicuro di voler cancellare l\'ordine ${order.orderId}?\n\n'
              '${order.side} ${order.origQty} ${order.symbol} a ${order.price}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<OrdersBloc>().add(
                    CancelOrder(symbol: order.symbol, orderId: order.orderId),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text(
                  'Cancella',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showCancelAllOrdersDialog(BuildContext context, String symbol) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancella Tutti gli Ordini'),
            content: Text(
              'Sei sicuro di voler cancellare TUTTI gli ordini aperti per $symbol?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<OrdersBloc>().add(
                    CancelAllOrders(symbol: symbol),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text(
                  'Cancella Tutto',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showModifyOrderDialog(BuildContext context, OrderStatus order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifica Ordine'),
            content: const Text(
              'La funzionalità per modificare gli ordini sarà disponibile presto.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, OrderStatus order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Dettagli Ordine ${order.orderId}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Simbolo', order.symbol),
                  _buildDetailRow('Lato', order.side),
                  _buildDetailRow('Tipo', order.type),
                  _buildDetailRow('Stato', order.status),
                  _buildDetailRow('Prezzo', order.price.toStringAsFixed(8)),
                  _buildDetailRow(
                    'Quantità Originale',
                    order.origQty.toStringAsFixed(6),
                  ),
                  _buildDetailRow(
                    'Quantità Eseguita',
                    order.executedQty.toStringAsFixed(6),
                  ),
                  _buildDetailRow(
                    'Fill %',
                    '${order.filledPercentage.toStringAsFixed(1)}%',
                  ),
                  _buildDetailRow(
                    'Valore Totale',
                    '\$${(order.price * order.origQty).toStringAsFixed(2)}',
                  ),
                  _buildDetailRow('Creato', order.time.toString()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Chiudi'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
