# Oracle Centralizado — Propuesta de Arquitectura

## Problema
Actualmente hay 3+ fuentes de precio desconectadas:
- `binance.criptoinversiones.net` (USD/VES + crypto spot + P2P)
- `goldt.criptoinversiones.net/api/rates.php` (148 FIAT + crypto + gold)
- `goldt.criptoinversiones.net` Oracle.php interno (actualiza `tasas_cambio`)
- `oraculo1.criptoinversiones.net` (BTC/ETH/BNB legacy)
- BCV como fuente primaria de VES (precio político, no refleja mercado real)

## Solución: Oracle Centralizado

```
oraculo.criptoinversiones.net/  ← NUEVO DOMINIO
├── config/
│   ├── config.php             ← Constantes, rutas, fuentes
│   ├── sources.php            ← RateSourceManager (adaptado de binance)
│   ├── commodities.php        ← Lista de commodities globales + tickers
│   └── OracleEngine.php       ← Motor unificado
├── cron/
│   ├── sync_rates.php         ← Cada 5 min: USD/VES + FIAT + CRYPTO
│   ├── sync_commodities.php   ← Cada 15 min: commodities vía yfinance
│   └── inject_goldt.php       ← Cada 5 min: alimenta goldt DB
└── public_html/
    └── api/
        ├── rates.php           ← API unificada (mismo formato que goldt)
        ├── rates_ves.php       ← USD/VES detallado (todas las fuentes)
        ├── commodities.php     ← Commodities globales
        └── health.php          ← Health check
```

## Fuentes de Datos

### USD/VES (orden de prioridad, SIN BCV)
1. **Binance P2P USDT/VES** — precio real de mercado, prioridad 1
2. Binance P2P BTC/VES, ETH/VES — fuentes secundarias
3. Yadio API — respaldo
4. EnParaleloVzla — respaldo
5. GoldT API — fallback (para no romper dependencia circular, se usa solo como último recurso)

### Crypto (Binance Spot)
- BTC, ETH, BNB, SOL, XRP, ADA, DOGE, DOT, LTC, TRX, AVAX, LINK, ATOM, UNI
- Precio en USD desde `api.binance.com`

### Commodities Globales (Yahoo Finance via Python)
```
Metales:      Oro, Plata, Platino, Paladio, Cobre
Energía:      Crudo WTI, Crudo Brent, Gas Natural, Gasolina RBOB
Granos:       Maíz, Trigo, Soya, Arroz, Avena
Softs:        Café, Cacao, Azúcar, Algodón, Jugo de naranja
Ganado:       Live Cattle, Feeder Cattle, Lean Hogs
Construcción: Madera (Lumber)
Estratégicos: Aceite de palma, Caucho
Potencial VE: Yuca (tapioca), Sal — precio referencia regional
```

### FIAT (148 monedas como hoy)
Se mantiene el mismo provider, pero ahora centralizado.

## Flujo de Datos

```
Binance P2P ─┐
Yadio ───────┤
EnParalelo ──┤→ OracleEngine → API unificada → goldt.criptoinversiones.net
Binance Spot─┤                                    (inyecta a DB)
yfinance ────┘                                   
     │
     └→ oraculo.criptoinversiones.net/api/rates.php
```

## Beneficios
1. Una sola fuente de verdad para todo el ecosistema
2. Sin dependencia de BCV (precio de mercado real via Binance P2P)
3. Commodities globales añadidas (economía real)
4. Backward compatible: goldt rates.php mantiene mismo formato
5. binance.criptoinversiones.net puede consumir de aquí como fuente

## Implementación
1. Crear estructura de directorios
2. Adaptar RateSourceManager de binance (quitar BCV, priorizar P2P)
3. Crear script Python para commodities (yfinance)
4. Crear API endpoint unificado (mismo formato que rates.php actual)
5. Conectar goldt DB para inyección de tasas
6. Desplegar en servidor
