# Server Audit — Arquitectura Completa

Fecha: 2026-06-26
Backup: `/home/edson/server-backup/`
DB dump: `server-backup/db/ecosistema_20260626.sql` (16MB)

## Dominios (13 total, 2.3G)

| # | Dominio | Tamaño | Propósito | Stack |
|---|---------|--------|-----------|-------|
| 1 | **criptoinversiones.net** | 1.8G | Hub principal, WordPress + Blog + Intercambio SPA | PHP, WordPress, Laravel Mix |
| 2 | **podscast.criptoinversiones.net** | 463M | Podcast CriptoSinCensura (PWA, audios) | HTML/JS, Python |
| 3 | **auditoria.criptoinversiones.net** | 43M | Auditoría de trading Deriv | PHP + MySQL |
| 4 | **goldt.criptoinversiones.net** | 18M | **SISTEMA GOLDT** — token, oráculo, ventas | PHP + Solidity + Web3 |
| 5 | **binance.criptoinversiones.net** | 14M | Oráculo de precios Venezuela (P2P, spot, USD/VES) | PHP, flat JSON |
| 6 | **bot.criptoinversiones.net** | 2.7M | Bot trading Deriv | PHP + WebSocket |
| 7 | **oraculo1.criptoinversiones.net** | 660K | Oráculo legacy (BTC/ETH/BNB precios) | PHP |
| 8 | **oraculo2.criptoinversiones.net** | 572K | Widget estadísticas Deriv | JS + Chart.js |
| 9 | **tienda.criptoinversiones.net** | 368K | Tienda GOLDT secundaria (casi clone de goldt) | PHP |
| 10 | **forex.criptoinversiones.net** | 176K | Colector datos Forex (Deriv WebSocket) | PHP + MySQL |
| 11 | **youtube.criptoinversiones.net** | 140K | CMS videos YouTube | PHP |
| 12 | **usd.criptoinversiones.net** | 28K | Redirect/placeholder | PHP |
| 13 | **quant.criptoinversiones.net** | 28K | Redirect/placeholder | PHP |

## Arquitectura del Sistema GOLDT (goldt.criptoinversiones.net)

### Flujo de Venta
```
1. Usuario → market.php → api/process_order.php
2. Validación: token_iso, tx_hash, wallet, monto
3. Oracle.getMetadata(iso) → tasa desde DB `tasas_cambio`
4. Cálculo: tokens = monto * tasa
5. INSERT en `ordenes_compra` (con KYC, IP, user agent)
6. Log a `logs/transactions_YYYY-MM.log`
7. Redirect a /order_receipt.php?id=N
8. Admin revisa en admin_orders.php → cambia estado
9. Si COMPLETADO: tokens van a `cola_acuñacion`
10. inyector_soberano.php procesa cola → batch mint vía Web3 a BSC
```

### Bases de Datos
| DB | Dominio | Usuario |
|----|---------|---------|
| u914331325_ecosistema | goldt | u914331325_goldt |
| u914331325_tienda | tienda | u914331325_deriv |
| u914331325_auditoria | auditoria | u914331325_auditor |
| u914331325_precios_forex | forex | u914331325_precios |
| u914331325_jAaW6 | criptoinversiones (WP) | u914331325_yLT2b |

### Contratos BSC Testnet (desplegados)
- GOLDT: `0x1A8d61467552d0320424fe20E766AeA26f3024A8`
- SOBERANO: `0xFA150C26C3e3Ca06aC31f203e9D9dDCFEa174046`
- Oracle: `0x17EF76F9F22bEA61ccf61c62C9E599815518C8F3`
- Core: `0xc88e6744bdf43E08bFCf7d05FffA0Ed8837BaD45`

### Integraciones Cross-Domain
- binance → goldt: fallback rate vía `goldt.criptoinversiones.net/api/fiat.php?iso=VES`
- goldt → blockchain: PriceInjector → Oracle contract → Core contract
- binance → Telegram: canal @cotizacionUSDT
- criptoinversiones.net → Deriv, CoinMarketCap, Telegram

## Seguridad — Riesgos Identificados
1. 🔴 Claves privadas blockchain en texto plano en `credentials.php`
2. 🔴 Admin key compartida entre goldt y tienda
3. 🟡 Tokens API duplicados (Deriv token en .env + hardcoded)
4. 🟡 Sin variables de entorno separadas por entorno (dev/prod)
5. 🟡 WordPress sin actualizaciones visibles

## Backup Realizado
- `server-backup/domains/` → copia completa de los 13 dominios (2GB)
- `server-backup/db/ecosistema_20260626.sql` → dump completo (16MB)
