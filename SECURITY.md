# Security Policy

## Supported Versions

| Version      | Supported          |
| ------------ | ------------------ |
| VorAdvs 8.20 | :white_check_mark: |
| Analysor 1.02 | :white_check_mark: |
| Older        | :x:                |

Only the latest versions shipped in this repository receive fixes.

## Reporting a Vulnerability

Please report security issues **privatively** rather than in a public issue:

- Use GitHub's **Security → Advisories → Report a vulnerability** on this
  repository, or
- Contact the maintainer, Shayan Ghadamian, directly.

You should receive an acknowledgement within 7 days. Please allow reasonable
time for a fix before any public disclosure.

When reporting, include:

- Affected file and version (`VorAdvs.mq5` / `Analysor.mq5` + `#property version`)
- Steps to reproduce or the relevant code path
- Impact (e.g. unintended order placement, funds at risk, chart object corruption)

## Scope & Design Notes

These are MQL5 Expert Advisors for MetaTrader 5. Current hardening properties:

- **No network I/O** — neither EA calls `WebRequest`, sockets, or DLLs.
- **No file or registry writes** — no `FileWrite`, `ShellExecute`, or imports.
- **No external input parsing** — inputs come only from the MT5 inputs dialog
  and chart events generated locally.
- **Analysor is read-only** — it displays and simulates; it never sends orders.
- **VorAdvs executes trades** — `OrderSend` is used for market orders, SL/TP
  modifications, and closes. Verify permissions (the EA logs a permissions
  check on init) and test on a demo account first.

## Safe Usage Recommendations

1. Test any modified build on a **demo account** before live use.
2. Keep `InpMagic` unique so the EA only manages its own positions.
3. Never grant auto-trading to unreviewed or third-party modified copies of
   these files.
4. Trading involves substantial risk of loss; review position sizes
   (LOT / % / $ modes) carefully before placing orders.
