# Ecosistema Claude — Escriba Clínico IA

Conjunto de **skills** y **comandos** para que Claude Code (y el equipo humano) trabaje con
máximo rendimiento en este repositorio. Está diseñado alrededor de tres ideas centrales del
proyecto:

1. **Una base reutilizable**: el flujo `captura de audio → transcripción (STT) → LLM →
   borrador estructurado → revisión humana → exportación` es el mismo para varios casos de
   uso. La arquitectura debe permitir crear un caso nuevo sin reescribir el núcleo.
2. **Flutter multiplataforma de primer nivel**: una sola base de código que se vea y se sienta
   excelente en móvil, tablet, escritorio y web, con UI/UX de empresa moderna.
3. **Cumplimiento no negociable**: residencia UE, humano en el bucle, minimización de audio,
   producto Clase I. Todo el código respeta `../CLAUDE.md` §7.

> Antes de tocar código, lee siempre `../CLAUDE.md` (raíz del repo). Este ecosistema **no lo
> sustituye**: lo complementa con guías operativas profundas.

---

## Skills disponibles

Las skills viven en `.claude/skills/<nombre>/SKILL.md`. Claude las invoca automáticamente
según el contexto; el equipo puede leerlas como documentación de referencia.

| Skill | Cuándo se usa | Qué aporta |
|-------|---------------|------------|
| [`flutter-stack`](skills/flutter-stack/SKILL.md) | Tocar el frontend Flutter, elegir paquetes, montar estado/navegación/tests | Stack y tendencias 2026, gestión de estado (Riverpod moderno), navegación, networking, codegen, testing |
| [`reusable-ai-architecture`](skills/reusable-ai-architecture/SKILL.md) | Diseñar o añadir un **caso de uso nuevo** sobre la base audio+LLM | Arquitectura "plataforma vs. producto", contratos compartidos FE+BE, pipeline dirigido por esquema, monorepo de paquetes |
| [`flutter-ui-ux`](skills/flutter-ui-ux/SKILL.md) | Construir/revisar pantallas, diseño, theming, responsive | Design system con tokens, Material 3, layout adaptativo multiplataforma, accesibilidad, microinteracciones, checklist de calidad |
| [`python-backend`](skills/python-backend/SKILL.md) | Tocar el backend FastAPI/servicios/pipeline | Patrones FastAPI + Pydantic v2 async, abstracción de proveedores, jobs, persistencia, auditoría, testing, cumplimiento |

## Comandos disponibles

| Comando | Qué hace |
|---------|----------|
| [`/new-use-case`](commands/new-use-case.md) | Guía el alta de un caso de uso nuevo reutilizando la base compartida (esquema, prompt, UI de revisión y exportación) sin duplicar el núcleo |

---

## Cómo encaja con el repo

```
helthcare-ai-system/
├── CLAUDE.md                 # contrato del proyecto (LEER PRIMERO)
├── docs/                     # estado, visión MVP, roadmap, arquitectura, cumplimiento
├── backend/                  # FastAPI (ver skill python-backend)
├── frontend/                 # Flutter (ver skills flutter-*)
└── .claude/                  # ESTE ecosistema
    ├── README.md
    ├── skills/
    │   ├── flutter-stack/
    │   ├── reusable-ai-architecture/
    │   ├── flutter-ui-ux/
    │   └── python-backend/
    └── commands/
        └── new-use-case.md
```

## Principios transversales (resumen rápido)

- **Desacopla por contratos, no por proveedores.** STT y LLM siempre detrás de su interfaz.
- **El esquema manda.** Cada caso de uso se define por su `OutputSchema` + prompt + render de
  revisión + exportador. El núcleo no sabe de clínica concreta.
- **Humano en el bucle, siempre.** Ninguna salida de IA se persiste sin validación explícita.
- **UE primero.** Ningún dato de salud sale de la UE; preferir proveedores europeos.
- **Sin secretos en el repo.** Todo por configuración/entorno.
- **Multiplataforma de verdad.** Diseña adaptativo desde el primer widget, no como parche final.
