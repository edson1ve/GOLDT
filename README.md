# GOLDT — Infraestructura Monetaria Digital

Smart contracts del ecosistema GOLDT: token respaldado por oro con oráculo propio, bóveda de estabilización y minteo offline automatizado.

## Arquitectura

```
src/
├── core/
│   ├── GoldTokenBase.sol   ← Base ERC20 con convert() + batchMint() + fee 1%
│   ├── Oracle.sol           ← Oráculo on-chain con precios injectados offline
│   └── CommodityFactory.sol ← Factory legacy de commodities
├── goldt/
│   └── GOLDT.sol            ← Token GOLDT (18 decimals, max wallet)
├── vault/
│   └── GOLDVE.sol           ← Bóveda discrecional + Vault (deposit/withdraw/requestMint)
├── fiat_g/
│   ├── FIAT_G.sol           ← Token FIAT_G (6 decimals, stable)
│   └── FIAT_G_Factory.sol   ← Deploy lazy de FIAT_G por código ISO
├── commodities/
│   └── CommodityToken.sol   ← Token de commodity (6 decimals)
└── interfaces/
    └── IOracle.sol          ← Interfaces IOracle, IGoldToken, IVault
```

## Stack

- **Solidity** + Foundry (forge build, forge test)
- Oracle offline: precios injectados desde `goldt.criptoinversiones.net/api/rates.php` (148 activos)
- Fee: 1% en tokens (no BNB), minteado a GOLDVE como adicional
- Conversión BNB→GOLDT vía oráculo con cola de minteo batch

## Tests

```bash
forge test -vvv    # 34 tests
forge build --sizes
```

## CI

GitHub Actions: `forge build + forge test + forge fmt --check` en cada push.

## License

MIT
