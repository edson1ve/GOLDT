# GOLDT — Workflow para Agentes AI

## SDD Flow (Spec-Driven Development)

Cada cambio sigue 5 fases en orden. Nunca saltar una fase sin justificación.

1. **explore** — entender el estado actual, restricciones, impacto
2. **propose** — plan con alcance definido, esperar aprobación
3. **apply** — implementar según el plan aprobado
4. **verify** — tests, lint, typecheck, evidencia de validación
5. **archive** — resumen final, actualizar AGENTS.md si aplica

### Artefactos
Cada fase genera un archivo en `.sdd/<cambio>/`:
- `explore.md` — hallazgos, riesgos
- `propose.md` — propuesta con límites de alcance
- `verify.md` — evidencia de validación
- `archive.md` — resumen y seguimientos

## Git Conventions

### Branches
```
main        ← producción (protegido)
feat/<desc> ← nuevas features
fix/<desc>  ← correcciones
docs/<desc> ← documentación
refactor/<desc> ← refactorización
chore/<desc> ← mantenimiento
```

### Commits (Conventional Commits)
```
feat(scope): mensaje en español, presente imperativo
fix(scope): mensaje corto y preciso
docs(scope): mensaje
refactor(scope): mensaje
test(scope): mensaje
chore(scope): mensaje

Ejemplos:
  feat(vault): agregar withdraw con cola de minteo
  fix(oracle): corregir cálculo de precio BNB
  docs(readme): actualizar instrucciones de despliegue
```

### Reglas
- main siempre estable, tests pasando
- feature branches desde main
- Commits atómicos (un cambio por commit)
- No commits directos a main (siempre branch → merge)
- Mensajes de commit en español

## Agent Delegation

Tareas complejas se delegan con `task tool` y subagent especializado.

### Cuándo delegar
- Más de 3 archivos por editar
- Requiere búsqueda exhaustiva en el código
- Tarea paralelizable
- Análisis de seguridad o revisión de código

### Formato de delegación
```markdown
Prompt debe incluir:
1. Contexto del cambio (SDD phase actual)
2. Archivos específicos a tocar
3. Criterio de éxito verificable
4. Restricciones (no agregar dependencias, mantener estilo, etc.)
```

## Server Deployment

Hostinger VPS: `u914331325@157.173.209.232 -p 65002`
- PHP 8.3 + MariaDB 11.8 + Composer + Git
- Node via alt-nodejs20/22/24
- Dominios: goldt, binance, bot, criptoinversiones, oraculo1, etc.
- DB: u914331325_ecosistema (24 tablas)

## Validación

Siempre ejecutar antes de commit:
```bash
forge test  # Tests Solidity
forge build # Compilación limpia
```
