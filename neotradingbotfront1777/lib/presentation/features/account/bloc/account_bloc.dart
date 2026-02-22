import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_account_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final IAccountRepository _accountRepository;

  AccountBloc({required IAccountRepository accountRepository})
    : _accountRepository = accountRepository,
      super(const AccountInitial()) {
    on<LoadAccountInfo>(_onLoadAccountInfo);
    on<WatchAccountInfo>(_onWatchAccountInfo, transformer: restartable());
    on<RefreshAccountInfo>(_onRefreshAccountInfo);
    on<FilterBalancesByAsset>(_onFilterBalancesByAsset);
    on<ShowOnlyNonZeroBalances>(_onShowOnlyNonZeroBalances);
    on<SortBalances>(_onSortBalances);
  }

  Future<void> _onLoadAccountInfo(
    LoadAccountInfo event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoading());

    final result = await _accountRepository.getAccountInfo();

    result.fold((failure) => emit(AccountError(failure.message)), (
      accountInfo,
    ) {
      final filteredBalances = _applyFilters(
        accountInfo.balances,
        null, // No asset filter initially
        true, // Show only non-zero by default
        BalanceSortType.alphabetical, // Default sorting
      );

      emit(
        AccountLoaded(
          accountInfo: accountInfo,
          filteredBalances: filteredBalances,
          showOnlyNonZero: true,
        ),
      );
    });
  }

  Future<void> _onWatchAccountInfo(
    WatchAccountInfo event,
    Emitter<AccountState> emit,
  ) async {
    // Se isStreaming è false, aggiorniamo solo lo stato UI e terminiamo.
    // Grazie a restartable(), questo cancellerà eventuali stream precedenti.
    if (!event.isStreaming) {
      final currentState = state;
      if (currentState is AccountLoaded) {
        emit(currentState.copyWith(isStreaming: false));
      }
      return;
    }

    // Caricamento iniziale inline (non usiamo add() dentro un event handler
    // per evitare race condition con il BLoC).
    emit(const AccountLoading());
    final initialResult = await _accountRepository.getAccountInfo();
    initialResult.fold((failure) => emit(AccountError(failure.message)), (
      accountInfo,
    ) {
      final filteredBalances = _applyFilters(
        accountInfo.balances,
        null,
        true,
        BalanceSortType.alphabetical,
      );
      emit(
        AccountLoaded(
          accountInfo: accountInfo,
          filteredBalances: filteredBalances,
          showOnlyNonZero: true,
        ),
      );
    });

    // Sottoscrizione allo stream per aggiornamenti successivi.
    await emit.forEach<Either<Failure, AccountInfo>>(
      _accountRepository.subscribeAccountInfo(),
      onData: (result) {
        return result.fold(
          (failure) {
            // In caso di errore nello stream, emettiamo uno stato di errore.
            // Potremmo anche aggiungere un evento per tentare una nuova sottoscrizione.
            return AccountError(failure.message);
          },
          (accountInfo) {
            final currentState = state;
            if (currentState is AccountLoaded) {
              // Applichiamo i filtri correnti ai nuovi dati ricevuti.
              final filteredBalances = _applyFilters(
                accountInfo.balances,
                currentState.assetFilter,
                currentState.showOnlyNonZero,
                currentState.sortType,
              );
              // Emettiamo il nuovo stato aggiornato.
              return currentState.copyWith(
                accountInfo: accountInfo,
                filteredBalances: filteredBalances,
                isStreaming: true,
              );
            }
            // Se lo stato non è 'Loaded', non facciamo nulla,
            // anche se questo caso è improbabile data la logica precedente.
            return currentState;
          },
        );
      },
      onError: (error, stackTrace) {
        // Gestiamo errori imprevisti nello stream.
        return AccountError('An unexpected error occurred: $error');
      },
    );
  }

  Future<void> _onRefreshAccountInfo(
    RefreshAccountInfo event,
    Emitter<AccountState> emit,
  ) async {
    // Inline la logica di caricamento (non usiamo add() dentro un handler).
    emit(const AccountLoading());
    final result = await _accountRepository.getAccountInfo();
    result.fold((failure) => emit(AccountError(failure.message)), (
      accountInfo,
    ) {
      final currentState = state;
      final showOnlyNonZero =
          currentState is AccountLoaded ? currentState.showOnlyNonZero : true;
      final sortType =
          currentState is AccountLoaded
              ? currentState.sortType
              : BalanceSortType.alphabetical;
      final assetFilter =
          currentState is AccountLoaded ? currentState.assetFilter : null;
      final filteredBalances = _applyFilters(
        accountInfo.balances,
        assetFilter,
        showOnlyNonZero,
        sortType,
      );
      emit(
        AccountLoaded(
          accountInfo: accountInfo,
          filteredBalances: filteredBalances,
          showOnlyNonZero: showOnlyNonZero,
        ),
      );
    });
  }

  Future<void> _onFilterBalancesByAsset(
    FilterBalancesByAsset event,
    Emitter<AccountState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountLoaded) {
      final filteredBalances = _applyFilters(
        currentState.accountInfo.balances,
        event.asset,
        currentState.showOnlyNonZero,
        currentState.sortType,
      );

      emit(
        currentState.copyWith(
          assetFilter: event.asset,
          filteredBalances: filteredBalances,
        ),
      );
    }
  }

  Future<void> _onShowOnlyNonZeroBalances(
    ShowOnlyNonZeroBalances event,
    Emitter<AccountState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountLoaded) {
      final filteredBalances = _applyFilters(
        currentState.accountInfo.balances,
        currentState.assetFilter,
        event.showOnlyNonZero,
        currentState.sortType,
      );

      emit(
        currentState.copyWith(
          showOnlyNonZero: event.showOnlyNonZero,
          filteredBalances: filteredBalances,
        ),
      );
    }
  }

  List<Balance> _applyFilters(
    List<Balance> balances,
    String? assetFilter,
    bool showOnlyNonZero,
    BalanceSortType sortType,
  ) {
    return _filterAndSortBalances(
      balances,
      assetFilter,
      showOnlyNonZero,
      sortType,
    );
  }

  void _onSortBalances(SortBalances event, Emitter<AccountState> emit) {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    final sortedBalances = _applySorting(
      currentState.filteredBalances,
      event.sortType,
    );

    emit(
      currentState.copyWith(
        filteredBalances: sortedBalances,
        sortType: event.sortType,
      ),
    );
  }

  List<Balance> _applySorting(
    List<Balance> balances,
    BalanceSortType sortType,
  ) {
    final sorted = balances.toList();

    switch (sortType) {
      case BalanceSortType.alphabetical:
        sorted.sort((a, b) => a.asset.compareTo(b.asset));
        break;
      case BalanceSortType.alphabeticalDesc:
        sorted.sort((a, b) => b.asset.compareTo(a.asset));
        break;
      case BalanceSortType.freeBalance:
        sorted.sort((a, b) => a.free.compareTo(b.free));
        break;
      case BalanceSortType.freeBalanceDesc:
        sorted.sort((a, b) => b.free.compareTo(a.free));
        break;
      case BalanceSortType.totalBalance:
        sorted.sort((a, b) => a.total.compareTo(b.total));
        break;
      case BalanceSortType.totalBalanceDesc:
        sorted.sort((a, b) => b.total.compareTo(a.total));
        break;
      case BalanceSortType.lockedBalance:
        sorted.sort((a, b) => a.locked.compareTo(b.locked));
        break;
      case BalanceSortType.lockedBalanceDesc:
        sorted.sort((a, b) => b.locked.compareTo(a.locked));
        break;
    }

    return sorted;
  }

  List<Balance> _filterAndSortBalances(
    List<Balance> balances,
    String? assetFilter,
    bool showOnlyNonZero,
    BalanceSortType sortType,
  ) {
    var filtered = balances.toList();

    if (showOnlyNonZero) {
      filtered = filtered.where((balance) => balance.total > 1e-8).toList();
    }

    if (assetFilter != null && assetFilter.isNotEmpty) {
      filtered =
          filtered
              .where(
                (balance) => balance.asset.toLowerCase().contains(
                  assetFilter.toLowerCase(),
                ),
              )
              .toList();
    }

    return _applySorting(filtered, sortType);
  }
}
