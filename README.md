# MQL5-ADV

Two MetaTrader 5 tools by **Shayan Ghadamian**: a compact risk-manager Expert
Advisor with on-chart controls, and a read-only trade dashboard with position
analysis and a P&L calculator.

| File            | Name                         | Version | Type                  |
| --------------- | ---------------------------- | ------- | --------------------- |
| `VorAdvs.mq5`   | Risk Manager EA              | 8.20    | Expert Advisor (trade) |
| `Analysor.mq5`  | Unified Trade Dashboard      | 1.02    | Dashboard (read-only)  |

Compiled `.ex5` binaries are included next to each source file.

## VorAdvs — Risk Manager EA

A compact, draggable panel for position sizing, order placement, and trade
management.

- **Account header** — balance and leverage at a glance.
- **Candle countdown** — time remaining until the current bar closes, with
  timeframe label and progress bar (top-right chart corner).
- **Position sizing** — switch between three modes:
  - `LOT` — fixed lot size
  - `%` — percentage of account balance
  - `$` — risk amount in currency
- **Trade preview** — shows computed lots, margin, and projected outcomes
  before you commit.
- **BUY / SELL** — one-click market orders, tagged with a magic number.
- **Advanced section** — entry / TP / SL analysis with profit, loss, and
  reward:risk ratio (color-coded: green ≥ 2.0, amber ≥ 1.0, red below).
- **Open positions** — up to 4 slots showing direction, pips, SL/TP status,
  and floating P&L, each with:
  - `✕` close position
  - `BE` move stop-loss to breakeven (only when the trade is in profit far
    enough; blocked otherwise and logged to the Experts log)
- **Bulk close** — `ALL` and `WIN` (winners only) buttons.
- **Settings panel** — runtime-editable magic number, chart timer toggle,
  red-line toggle, and panel positions; applies live without re-attach.
- **Red line** — horizontal reference line at the current bid.

### Inputs

| Input               | Default  | Description                              |
| ------------------- | -------- | ---------------------------------------- |
| `InpSize`           | `1.0`    | Initial sizing value                     |
| `InpMode`           | `1`      | Sizing mode (0 = LOT, 1 = %, 2 = $)      |
| `InpPanelX/Y`       | `20/30`  | Main panel position                      |
| `InpMagic`          | `20241008` | Magic number stamped on orders         |
| `InpShowChartTimer` | `true`   | Show candle countdown widget             |
| `InpShowRedLine`    | `true`   | Show red reference line                  |
| `InpTimerCornerX/Y` | `20/30`  | Countdown widget position                |

## Analysor — Unified Trade Dashboard

A single draggable, tabbed dashboard. **Display only — it never sends,
modifies, or closes orders.**

- **📋 Trade Assistant tab**
  - Lists open positions; select one to inspect it.
  - Chart overlay of entry, SL, and TP levels for the selected trade.
  - TP-ladder simulation (`SIM`) with reset — models stepping out of a
    position without touching the market.
  - Auto-refreshes when position data changes (2-second timer).
- **📊 P&L Analyser tab**
  - Inputs: lot, entry price, leverage, TP price, SL price, pair, TP/SL mode.
  - Outputs: risk/reward ratio (formatted `R:R  x.xx : 1`), profit and loss
    projections.
  - Fields are read only after you finish editing, so typing is never
    interrupted.
- **Panel controls** — drag by the title bar, minimize, switch tabs, `↺`
  reset to default position.

## Installation

1. Open MetaTrader 5 → **File → Open Data Folder**.
2. Copy each `.mq5` file (or the pre-built `.ex5`) into
   `MQL5\Experts\`.
3. Compile in MetaEditor if you changed the source (**F7**).
4. In the Navigator, drag the tool onto a chart.
   - For `VorAdvs`: enable **Allow Algo Trading** in the chart properties so
     orders can be placed.
   - For `Analysor`: no trading permission needed (display only).
5. On first load `VorAdvs` prints a permissions check to the Experts log —
   confirm all three lines say `YES` before live use.

## Testing & Safety

- Test on a **demo account** first; `VorAdvs` places real market orders,
  closes positions, and moves stop-losses.
- Keep a unique `InpMagic` if other EAs run on the same account.
- Review sizing mode and preview numbers before pressing BUY/SELL.
- See [SECURITY.md](SECURITY.md) for the security policy and design notes.

## Requirements

- MetaTrader 5 (build with MQL5 support)
- Auto-trading enabled for `VorAdvs` order functions

## License

[MIT](LICENSE) — © 2026 Shayan Ghadamian

## Disclaimer

Trading foreign exchange and CFDs on margin carries a high level of risk and
may not be suitable for all investors. These tools are provided "as is"
without warranty of any kind. You are solely responsible for any trades
placed using them.
