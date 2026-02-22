/// Shared test helper that registers all common provideDummy values
/// needed by Mockito for complex generic types.
///
/// Import this file and call [registerMockitoDummies] in your setUp
/// before creating any mocks.
library;

import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/exchange_info.dart';
import 'package:neotradingbotback1777/domain/entities/kline.dart';
import 'package:neotradingbotback1777/domain/entities/order_response.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';

/// Registers all common dummy values for Mockito.
/// Call this at the top of your setUp() before creating any mocks.
void registerMockitoDummies() {
  // Either<Failure, List<Kline>>
  provideDummy<Either<Failure, List<Kline>>>(const Right([]));

  // Either<Failure, AppStrategyState>
  provideDummy<Either<Failure, AppStrategyState>>(
    Right(AppStrategyState(symbol: 'BTCUSDT')),
  );

  // Either<Failure, AppStrategyState?>
  provideDummy<Either<Failure, AppStrategyState?>>(
    Right(AppStrategyState(symbol: 'BTCUSDT')),
  );

  // Either<Failure, AccountInfo?>
  provideDummy<Either<Failure, AccountInfo?>>(
    const Right(null),
  );

  // Either<Failure, Price>
  provideDummy<Either<Failure, Price>>(
    Right(Price(
      symbol: 'BTCUSDT',
      price: 50000.0,
      timestamp: DateTime.now(),
    )),
  );

  // Either<Failure, SymbolInfo>
  provideDummy<Either<Failure, SymbolInfo>>(
    Right(SymbolInfo(
      symbol: 'BTCUSDT',
      minQty: 0.00001,
      maxQty: 9000.0,
      stepSize: 0.00001,
      minNotional: 10.0,
    )),
  );

  // Either<Failure, BacktestResult>
  provideDummy<Either<Failure, BacktestResult>>(
    Right(BacktestResult(
      backtestId: '',
      totalProfit: Decimal.zero,
      profitPercentage: Decimal.zero,
      tradesCount: 0,
      trades: [],
    )),
  );

  // Either<Failure, OrderResponse>
  provideDummy<Either<Failure, OrderResponse>>(
    Right(OrderResponse(
      symbol: 'BTCUSDT',
      orderId: 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'FILLED',
      executedQty: 0.0,
    )),
  );

  // Either<Failure, ExchangeInfo>
  provideDummy<Either<Failure, ExchangeInfo>>(
    const Right(ExchangeInfo(symbols: [])),
  );

  // Either<Failure, double?>
  provideDummy<Either<Failure, double?>>(const Right(0.0));

  // Either<Failure, List<AppTrade>>
  provideDummy<Either<Failure, List<AppTrade>>>(const Right([]));

  // Either<Failure, Unit>
  provideDummy<Either<Failure, Unit>>(const Right(unit));

  // Either<Failure, void>
  provideDummy<Either<Failure, void>>(const Right(null));

  // Either<Failure, bool>
  provideDummy<Either<Failure, bool>>(const Right(true));

  // Either<Failure, String>
  provideDummy<Either<Failure, String>>(const Right(''));

  // Either<Failure, FeeInfo>
  provideDummy<Either<Failure, FeeInfo>>(
    Right(FeeInfo.defaultBinance(symbol: 'BTCUSDT')),
  );

  // IFeeRepository
  provideDummy<IFeeRepository>(MockIFeeRepository());
}

class MockIFeeRepository extends Mock implements IFeeRepository {}
