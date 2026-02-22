// [AUDIT-PHASE-9] - Formal Audit Marker
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';

class TradingLoopPreFlightCheck {
  final AccountRepository _accountRepository;
  final ISymbolInfoRepository _symbolInfoRepository;
  final PriceRepository _priceRepository;
  final _log = LogManager.getLogger();

  TradingLoopPreFlightCheck({
    required AccountRepository accountRepository,
    required ISymbolInfoRepository symbolInfoRepository,
    required PriceRepository priceRepository,
  })  : _accountRepository = accountRepository,
        _symbolInfoRepository = symbolInfoRepository,
        _priceRepository = priceRepository;

  Future<Either<Failure, Unit>> execute(
      String symbol, AppSettings settings) async {
    _log.d('Esecuzione controlli pre-volo per $symbol...');

    // 1. Validazione formato simbolo
    if (symbol.isEmpty || !symbol.contains('USDC')) {
      return Left(ValidationFailure(
          message:
              'Simbolo non valido: $symbol. Deve contenere USDC (es. BTCUSDC)'));
    }

    // 2. Verifica connettività base e esistenza simbolo su Binance
    // Proviamo a recuperare il prezzo corrente (REST)
    try {
      final priceCheck = await _priceRepository.getCurrentPrice(symbol);
      if (priceCheck.isLeft()) {
        return Left(NetworkFailure(
            message:
                'Impossibile recuperare prezzo per $symbol. Verifica connessione e simbolo.'));
      }
    } catch (e) {
      return Left(NetworkFailure(
          message: 'Eccezione durante check connettività per $symbol: $e'));
    }

    // 3. Verifica accessibilità Account (API Key/Secret valide)
    // Non bloccante se siamo in Test Mode?
    // Anche in test mode potremmo voler verificare le chiavi se usiamo quelle reali per i prezzi o user data stream.
    // Tuttavia, se siamo in Testnet o Paper Trading pura, potrebbe differire.
    // Assumiamo che AccountRepository gestisca la logica corretta.
    try {
      final accountCheck = await _accountRepository.getAccountInfo();
      return await accountCheck.fold((failure) async => Left(failure),
          (AccountInfo? accountInfo) async {
        if (accountInfo == null) {
          return Left(ServerFailure(message: 'Account info not found'));
        }
        final quoteAsset = symbol.endsWith('USDC')
            ? 'USDC'
            : (symbol.endsWith('USDT') ? 'USDT' : null);

        if (quoteAsset != null) {
          final balance = accountInfo.balances.firstWhere(
            (b) => b.asset == quoteAsset,
            orElse: () => Balance(asset: quoteAsset, free: 0.0, locked: 0.0),
          );
          if (balance.free < settings.tradeAmount) {
            return Left(BusinessLogicFailure(
              message:
                  'Saldo $quoteAsset insufficiente (${balance.free}) per tradeAmount (${settings.tradeAmount}).',
            ));
          }
        }

        // 4. Verifica Info Simbolo (Lot Size, Min Notional, etc.)
        // Questo passaggio assicura che i parametri di trading configurati
        // rispettino i limiti imposti dall'exchange per il simbolo specifico.
        try {
          final symbolInfoResult =
              await _symbolInfoRepository.getSymbolInfo(symbol);

          return symbolInfoResult.fold((failure) {
            return Left(failure);
          }, (info) {
            // Validazioni aggiuntive sulla configurazione rispetto ai limiti del simbolo
            // Es. Trade Amount > Min Notional
            if (settings.tradeAmount < info.minNotional) {
              return Left(ValidationFailure(
                  message:
                      'Trade Amount (${settings.tradeAmount}) inferiore al Min Notional (${info.minNotional}) per $symbol'));
            }

            // Verifica Fixed Quantity se usata
            if (settings.fixedQuantity != null && settings.fixedQuantity! > 0) {
              if (settings.fixedQuantity! < info.minQty) {
                return Left(ValidationFailure(
                    message:
                        'Fixed Quantity (${settings.fixedQuantity}) inferiore alla Min Quantity (${info.minQty}) per $symbol'));
              }
            }

            _log.i(
                'Controlli pre-volo superati per $symbol. Limits: MinNotional=${info.minNotional}, MinQty=${info.minQty}');
            return const Right(unit);
          });
        } catch (e) {
          return Left(ServerFailure(
              message: 'Eccezione durante recupero info simbolo $symbol: $e'));
        }
      });
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
          message:
              'Bypass check account fallito con eccezione: $e\n$stackTrace'));
    }
  }
}
