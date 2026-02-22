import 'package:mockito/annotations.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

@GenerateMocks([
  ITradingApiService,
  ISymbolInfoRepository,
  AccountRepository,
])
void main() {}
