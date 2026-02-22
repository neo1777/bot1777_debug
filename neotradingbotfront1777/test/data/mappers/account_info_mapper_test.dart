import 'package:neotradingbotfront1777/data/mappers/account_info_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';

void main() {
  group('AccountInfoMapper — toDomain', () {
    test('[AIM-01] maps all fields from proto to domain', () {
      final proto = AccountInfoResponse(
        balances: [
          BalanceProto(
            asset: 'BTC',
            free: 0.5,
            locked: 0.1,
            estimatedValueUSDC: 27000.0,
            freeStr: '0.50000000',
            lockedStr: '0.10000000',
            estimatedValueUSDCStr: '27000.00',
          ),
        ],
        totalEstimatedValueUSDC: 27000.0,
        totalEstimatedValueUSDCStr: '27000.00',
      );

      final result = proto.toDomain();

      expect(result, isA<AccountInfo>());
      expect(result.balances.length, 1);
      expect(result.balances[0].asset, 'BTC');
      expect(result.balances[0].free, 0.5);
      expect(result.balances[0].locked, 0.1);
      expect(result.totalEstimatedValueUSDC, 27000.0);
    });

    test('[AIM-02] maps multiple balances', () {
      final proto = AccountInfoResponse(
        balances: [
          BalanceProto(asset: 'BTC', free: 0.5, locked: 0.0),
          BalanceProto(asset: 'ETH', free: 10.0, locked: 2.0),
          BalanceProto(asset: 'USDC', free: 5000.0, locked: 0.0),
        ],
      );

      final result = proto.toDomain();
      expect(result.balances.length, 3);
      expect(result.balances[2].asset, 'USDC');
    });
  });

  group('AccountInfoMapper — toDto', () {
    test('[AIM-03] maps domain account info back to proto', () {
      final domain = AccountInfo(
        balances: [
          Balance(
            asset: 'BTC',
            free: 0.5,
            locked: 0.1,
            estimatedValueUSDC: 27000.0,
            freeStr: '0.50',
            lockedStr: '0.10',
            estimatedValueUSDCStr: '27000.00',
          ),
        ],
        totalEstimatedValueUSDC: 27000.0,
        totalEstimatedValueUSDCStr: '27000.00',
      );

      final result = domain.toDto();
      expect(result, isA<AccountInfoResponse>());
      expect(result.balances.length, 1);
      expect(result.balances[0].asset, 'BTC');
    });
  });

  group('AccountInfoMapper — edge cases', () {
    test('[AIM-04] handles empty balances list', () {
      final proto = AccountInfoResponse(balances: []);

      final result = proto.toDomain();
      expect(result.balances, isEmpty);
    });
  });
}

