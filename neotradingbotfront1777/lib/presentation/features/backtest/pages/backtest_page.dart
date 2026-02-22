import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_event.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_state.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:intl/intl.dart';

class BacktestPage extends StatelessWidget {
  const BacktestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BacktestBloc>(),
      child: const BacktestView(),
    );
  }
}

class BacktestView extends StatefulWidget {
  const BacktestView({super.key});

  @override
  State<BacktestView> createState() => _BacktestViewState();
}

class _BacktestViewState extends State<BacktestView> {
  final TextEditingController _symbolController = TextEditingController(
    text: 'BTCUSDT',
  );
  final TextEditingController _periodController = TextEditingController(
    text: '30',
  );
  String _selectedInterval = '1h';
  final List<String> _intervals = ['1m', '5m', '15m', '1h', '4h', '1d'];

  @override
  void dispose() {
    _symbolController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backtest Strategia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildControls(context),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<BacktestBloc, BacktestState>(
                builder: (context, state) {
                  if (state is BacktestLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is BacktestRunning) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('Backtest in corso... ID: ${state.backtestId}'),
                        ],
                      ),
                    );
                  } else if (state is BacktestError) {
                    return Center(
                      child: Text(
                        'Errore: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is BacktestLoaded) {
                    return _buildResults(state.result);
                  }
                  return const Center(
                    child: Text('Inserisci i parametri e avvia il backtest.'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _symbolController,
                    decoration: const InputDecoration(labelText: 'Simbolo'),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedInterval,
                  items:
                      _intervals.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedInterval = newValue!;
                    });
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _periodController,
                    decoration: const InputDecoration(
                      labelText: 'Periodo (giorni)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final symbol = _symbolController.text;
                final period = int.tryParse(_periodController.text) ?? 30;
                context.read<BacktestBloc>().add(
                  StartBacktest(
                    symbol: symbol,
                    interval: _selectedInterval,
                    period: period,
                    strategyName: 'ClassicStrategy', // Hardcoded or selector
                  ),
                );
              },
              child: const Text('Avvia Backtest'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BacktestResult result) {
    return Column(
      children: [
        _buildSummaryCard(result),
        const SizedBox(height: 16),
        Expanded(child: _buildTradesList(result.trades)),
      ],
    );
  }

  Widget _buildSummaryCard(BacktestResult result) {
    final profitColor = result.totalProfit >= 0 ? Colors.green : Colors.red;
    final profitStr = result.totalProfitStr.isNotEmpty
        ? result.totalProfitStr
        : result.totalProfit.toStringAsFixed(4);
    final pctStr = result.profitPercentageStr.isNotEmpty
        ? result.profitPercentageStr
        : result.profitPercentage.toStringAsFixed(2);
    final feesStr = result.totalFeesStr.isNotEmpty
        ? result.totalFeesStr
        : result.totalFees.toStringAsFixed(4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Profitto Netto', '$profitStr USDT',
                    color: profitColor),
                _buildStatItem('Rendimento', '$pctStr%', color: profitColor),
                _buildStatItem('Fee Totali', '$feesStr USDT'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trade Totali', '${result.tradesCount}'),
                _buildStatItem('Trade DCA', '${result.dcaTradesCount}'),
                _buildStatItem('ID', result.backtestId,
                    style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value,
      {Color? color, TextStyle? style}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value,
            style: style ??
                TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTradesList(List<AppTrade> trades) {
    return ListView.builder(
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        final color =
            trade.profit != null && trade.profit! >= 0
                ? Colors.green
                : Colors.red;
        return ListTile(
          leading: Icon(
            trade.isBuy ? Icons.arrow_downward : Icons.arrow_upward,
            color: trade.isBuy ? Colors.green : Colors.red,
          ),
          title: Text('${trade.side} ${trade.symbol}'),
          subtitle: Text(
            'Prezzo: ${trade.price.toStringAsFixed(2)} | Qty: ${trade.quantity.toStringAsFixed(4)} | ${DateFormat('dd/MM/yyyy HH:mm').format(trade.timestamp)}',
          ),
          trailing: Text(
            trade.profit != null ? trade.profit!.toStringAsFixed(2) : '-',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
