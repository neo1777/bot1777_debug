import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/balance_hive_dto.dart';

part 'account_info_hive_dto.g.dart';

@HiveType(typeId: 5)
class AccountInfoHiveDto extends HiveObject {
  @HiveField(0)
  HiveList<BalanceHiveDto>? balances;

  @HiveField(1)
  double? totalEstimatedValueUSDC;

  static AccountInfoHiveDto fromEntity(AccountInfo entity) {
    final dto = AccountInfoHiveDto();
    dto.totalEstimatedValueUSDC = entity.totalEstimatedValueUSDC;

    final balanceBox = Hive.box<BalanceHiveDto>('balance_box');

    // Inizializza la HiveList e aggiungi gli oggetti già persistiti nel box
    dto.balances = HiveList(balanceBox);
    for (final balance in entity.balances) {
      final existingDto = balanceBox.get(balance.asset);
      if (existingDto != null) {
        dto.balances!.add(existingDto);
      }
    }
    return dto;
  }

  AccountInfo toEntity() => AccountInfo(
      totalEstimatedValueUSDC: totalEstimatedValueUSDC ?? 0.0,
      balances: balances?.map((dto) => dto.toEntity()).toList() ?? []);
}
