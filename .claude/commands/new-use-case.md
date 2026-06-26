---
description: Da de alta un caso de uso nuevo sobre la base compartida audio→STT→LLM→revisión→exportación sin duplicar el núcleo
---

# /new-use-case — Alta de un caso de uso sobre la base compartida

Objetivo: crear un **caso de uso nuevo** (otro tipo de documento audio→texto→estructura→
revisión→exportación) reutilizando la plataforma existente. Un caso = 4 piezas enchufables, no
un fork. Lee primero la skill [`reusable-ai-architecture`](../skills/reusable-ai-architecture/SKILL.md)
y `../../CLAUDE.md` (cumplimiento §7).

## Entrada esperada
El usuario aporta (o se le pregunta): nombre del caso (`key` en snake_case), las **secciones**
del documento, el **sistema/formato de exportación** y el **proveedor** STT/LLM (debe ser UE).

## Pasos

1. **Confirma alcance y cumplimiento.**
   - ¿Es soporte administrativo (Clase I) o roza decisión clínica/automatizada? Si lo segundo,
     **detente** y consulta al equipo (§2, §7.2).
   - ¿Destino de exportación, residencia UE del proveedor y DPA verificados? (§7.4).

2. **Backend — define el caso** en `backend/app/usecases/<key>/`:
   - `output_model`: modelo Pydantic con las secciones (cada una con `content` +
     `needs_confirmation`). Reutiliza tipos base de la plataforma.
   - `build_prompt(...)`: hereda la instrucción **anti-alucinación** de la plantilla base; añade
     lo específico del dominio.
   - `exporter()`: implementa la interfaz `Exporter` para el sistema destino.
   - `register(<UseCase>())` para que el registry lo encuentre. **No toques `orchestrator.py`.**

3. **Frontend — define el render** en `frontend/packages/usecase_<key>/`:
   - Modelo `freezed` espejo del Pydantic (nombres de campo alineados, ver `flutter-stack`).
   - `ReviewSchema`: descripción de secciones para `ai_review_kit` (no escribas una pantalla
     nueva; aporta la config que el kit genérico renderiza).
   - Textos i18n (ARB) en español.

4. **Cablea** el `use_case_key` en la selección/router de la app (`frontend/app/`).

5. **Tests** (no opcional):
   - Backend: pipeline con STT/LLM **mockeados** → verifica orquestación, `del audio_bytes`,
     salida validada contra el esquema y marcado `needs_confirmation`.
   - Frontend: widget de revisión del caso (render, edición, validación humana).

6. **UI/UX**: aplica [`flutter-ui-ux`](../skills/flutter-ui-ux/SKILL.md) — badge "asistido por
   IA", campos dudosos con color+icono+texto, estados loading/empty/error, responsive en los 4
   factores de forma.

7. **Verifica** invariantes de plataforma intactos: revisión humana obligatoria, sin persistir
   audio, sin PHI en logs/URLs, proveedor UE.

## Salida
Resumen de: archivos creados (backend `usecases/<key>/`, frontend `packages/usecase_<key>/`),
puntos de cableado, tests añadidos y confirmación de cumplimiento. Si algo del núcleo tuvo que
cambiar, explica por qué (debería ser raro: el núcleo es agnóstico al caso).
