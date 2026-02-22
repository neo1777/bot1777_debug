# User Guide: NeoTradingBot1777

## 🚀 Getting Started

1. **Access the Dashboard**: Open the Flutter application (Desktop or Web).
2. **Connection Status**: Verify the "Server Status" indicator in the top right is GREEN.

## 📊 Dashboard Overview

- **Account Overview**: Shows total balance (USDC) and estimated value of open positions.
- **Active Strategies**: List of trading pairs currently being monitored.
  - **Status**: IDLE, LISTENING, POSITION_OPEN.
  - **PnL**: Profit/Loss for the current active position.
- **Logs Console**: Real-time stream of system events.

## ⚙️ Configuration

Strategies are configured via `app_settings` (currently file-based or via backend defaults).

### Key Parameters
- **Allocation**: Amount of USDC to allocate per trade.
- **Profit Target**: Percentage gain to trigger a sell (e.g., 1.5%).
- **Stop Loss**: Percentage loss to trigger a sell (e.g., -2.0%).

## ❓ FAQ

**Q: What happens if I close the dashboard?**
A: The trading bot runs on the backend (server). Closing the UI does **not** stop trading.

**Q: How do I stop a strategy?**
A: Use the "Stop" button next to the strategy in the dashboard. This will gracefully terminate the trading loop for that symbol.
