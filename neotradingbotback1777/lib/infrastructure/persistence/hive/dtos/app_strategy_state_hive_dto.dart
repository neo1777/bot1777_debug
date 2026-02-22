import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';

part 'app_strategy_state_hive_dto.g.dart';

@HiveType(typeId: 1)
class AppStrategyStateHiveDto extends HiveObject {
  @HiveField(0)
  String? symbol;
  @HiveField(1)
  HiveList<FifoAppTradeHiveDto>? openTrades;
  @HiveField(2) // Questo era isActive, ora sarà status
  int? status; // Memorizzeremo l'indice dell'enum
  @HiveField(3) // Era 4, ora 3
  int? currentRoundId;
  @HiveField(4) // Era 5, ora 4
  double? cumulativeProfit;
  @HiveField(5) // Era 6, ora 5
  int? successfulRounds;
  @HiveField(6) // Era 7, ora 6
  int? failedRounds;

  /// Round target dopo il quale la strategia deve fermarsi automaticamente (IDLE).
  /// Se 0 o assente: nessun limite.
  @HiveField(7)
  int? targetRoundId;

  // NOTA: Questo metodo ora si aspetta una HiveList già popolata e salvata.
  // La responsabilità di gestire il salvataggio dei trade figli è del repository.
  static AppStrategyStateHiveDto fromEntity(
      AppStrategyState entity, HiveList<FifoAppTradeHiveDto> openTradesList) {
    return AppStrategyStateHiveDto()
      ..symbol = entity.symbol
      ..openTrades = openTradesList
      ..status = entity.status.index
      ..currentRoundId = entity.currentRoundId
      ..cumulativeProfit = entity.cumulativeProfit
      ..successfulRounds = entity.successfulRounds
      ..failedRounds = entity.failedRounds
      ..targetRoundId = entity.targetRoundId;
  }

  AppStrategyState toEntity() => AppStrategyState(
        symbol: symbol ?? '',
        openTrades: openTrades?.map((dto) => dto.toEntity()).toList() ?? [],
        status: status != null &&
                status! >= 0 &&
                status! < StrategyState.values.length
            ? StrategyState.values[status!]
            : StrategyState.IDLE,
        currentRoundId: currentRoundId ?? 0,
        cumulativeProfit: cumulativeProfit ?? 0.0,
        successfulRounds: successfulRounds ?? 0,
        failedRounds: failedRounds ?? 0,
        targetRoundId: targetRoundId,
      );
}
