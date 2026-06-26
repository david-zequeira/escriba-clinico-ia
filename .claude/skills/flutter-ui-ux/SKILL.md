---
name: flutter-ui-ux
description: >-
  Diseño UI/UX de empresa moderna y de primer nivel para la app Flutter, que se vea y se sienta
  excelente en móvil, tablet, escritorio y web. Úsala al construir o revisar pantallas, montar
  el design system, theming, layout responsive/adaptativo, tipografía, color, accesibilidad,
  microinteracciones, estados (loading/empty/error) o pulir la pantalla de revisión clínica.
  Cubre Material 3, design tokens, breakpoints adaptativos, dark mode, a11y WCAG y un checklist
  de calidad. Para crear/buscar componentes puede apoyarse en la skill ui-ux-pro-max y el MCP de
  Magic/21st (mcp__magic__*) cuando estén disponibles.
---

# UI/UX Flutter — Enterprise, moderno, multiplataforma

Objetivo: una sola base de código Flutter con apariencia y comportamiento de **producto de
empresa de primer nivel** en **móvil, tablet, escritorio y web**. Sobrio, clínico, confiable —
no juguetón. La pantalla estrella es la **revisión del borrador**: debe transmitir control,
claridad y seguridad (el médico edita y valida; nada se guarda sin su acción).

> Esta app maneja un contexto sensible (salud). El diseño prioriza **legibilidad, confianza y
> control humano** sobre el efectismo. Indicar siempre, de forma visible, que el contenido fue
> "asistido por IA y revisado por el profesional" (requisito de transparencia, `../../CLAUDE.md` §7).

---

## 1. Design system primero (tokens, no valores sueltos)

Nada de hex ni paddings mágicos repartidos por los widgets. Define **tokens** y consúmelos vía
`ThemeExtension`. Vive en el paquete `design_system/` (ver reusable-ai-architecture).

```dart
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color surface, surfaceAlt, primary, danger, warning, aiAccent;
  final double radiusSm, radiusMd, radiusLg;     // 8 / 12 / 20
  final double space1, space2, space3, space4;   // 4 / 8 / 16 / 24 (escala 4pt)
  // copyWith + lerp ...
}
```

- **Escala de espaciado 4/8pt** (4, 8, 12, 16, 24, 32). Consistencia = aire profesional.
- **Radios** y **elevaciones** definidos una vez. Sombras suaves, no dramáticas.
- Un único `aiAccent` para marcar de forma sutil lo generado por IA.

---

## 2. Material 3 + theming serio

El repo ya usa `useMaterial3: true` con `colorSchemeSeed: Colors.teal`. Súbelo de nivel:

```dart
final scheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0F6E6E),   // teal clínico, sobrio
  brightness: Brightness.light,
);
ThemeData(
  useMaterial3: true,
  colorScheme: scheme,
  extensions: [AppTokens.light],
  textTheme: appTextTheme,               // tipografía con jerarquía clara
  visualDensity: VisualDensity.adaptivePlatformDensity, // clave multiplataforma
);
```

- **Light y dark** desde el principio (`themeMode`, dos `ColorScheme`). Hospitales usan ambos.
- **Tipografía**: jerarquía explícita (display/title/body/label). Fuente legible (p. ej. Inter).
  Cuerpo ≥ 16px en escritorio; respeta el text scaling del sistema (accesibilidad).
- **Densidad adaptativa**: más compacto en escritorio, más táctil en móvil (objetivos ≥ 48px).

---

## 3. Layout adaptativo y responsive (el corazón del "se ve bien en todo")

No basta con que "quepa": el layout debe **cambiar de forma** según el ancho. Diseña por
breakpoints (alineados a Material 3 window size classes):

| Clase | Ancho | Layout |
|-------|-------|--------|
| Compact | < 600 | 1 columna, navegación inferior, acciones en bottom bar |
| Medium | 600–840 | `NavigationRail`, contenido 1–2 columnas |
| Expanded | 840–1200 | `NavigationRail` + panel de detalle (lista ↔ detalle) |
| Large/XL | > 1200 | layout de 2–3 zonas, anchos máximos de lectura (~720px de texto) |

```dart
// Usa LayoutBuilder/MediaQuery o el paquete flutter_adaptive_scaffold.
Widget build(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  if (w < 600)  return _MobileLayout();       // BottomNavigationBar
  if (w < 1200) return _MediumLayout();       // NavigationRail
  return _ExpandedLayout();                    // Rail + master-detail
}
```

Reglas de oro:
- **Master–detail** en pantallas anchas (lista de consultas ↔ revisión), pila navegable en móvil.
- **Ancho máximo de línea** para texto largo (la nota clínica): no estirar a 2000px.
- **Convenciones por plataforma**: scrollbars visibles y atajos de teclado en escritorio/web;
  gestos y pull-to-refresh en móvil. Usa `Platform`/`TargetPlatform` con criterio.
- Prueba en los 4 factores de forma antes de dar por hecho que "se ve bien".

---

## 4. La pantalla de revisión (caso estrella)

Es donde el producto se gana la confianza del médico. Buenas prácticas:

- **Cabecera de transparencia**: badge persistente "Borrador asistido por IA · revísalo antes de
  guardar". No es decorativo: es cumplimiento.
- **Campos dudosos marcados**: `needs_confirmation` → resaltado sutil (borde/chip de aviso), no
  rojo de error. Comunica "confírmalo", no "está mal".
- **Edición fluida**: campos multilínea que crecen, autosave de borrador local (no de datos al
  servidor), foco y orden de tabulación correctos (escritorio).
- **Acción de validar destacada y deliberada**: botón primario claro; idealmente confirmación
  ("vas a guardar en el historial"). Nunca auto-guardar.
- **Diff opcional**: poder ver qué cambió respecto al borrador de IA (apoya la auditoría).

---

## 5. Estados: nunca una pantalla muda

Toda vista con datos asíncronos tiene **cuatro** estados; diséñalos los cuatro:

- **Loading**: skeletons (no solo un spinner) que imiten la forma del contenido.
- **Empty**: mensaje útil + acción ("Aún no hay borrador. Graba una consulta.").
- **Error**: mensaje claro, sin tecnicismos ni trazas, con reintento. Sin PHI.
- **Success**: el contenido. Combínalo con `AsyncValue` de Riverpod (ver flutter-stack).

---

## 6. Microinteracciones y feedback (con mesura)

- Transiciones suaves (200–300 ms), `AnimatedSwitcher`/`Hero` entre lista y detalle.
- Feedback inmediato en acciones: estado de carga en el botón "Validar", `SnackBar`/diálogo de
  confirmación al guardar.
- Respeta `MediaQuery.disableAnimations` (accesibilidad / preferencia de movimiento reducido).
- Nada de animaciones gratuitas que distraigan en un entorno clínico.

---

## 7. Accesibilidad (no negociable en salud)

- **Contraste** WCAG AA mínimo (4.5:1 texto normal). Verifica en light y dark.
- **Objetivos táctiles** ≥ 48×48. **Semántica**: `Semantics`, labels en iconos, foco lógico.
- **Text scaling**: la UI no se rompe con fuentes grandes del sistema.
- **Teclado**: navegable completa en escritorio/web (tab, enter, shortcuts).
- No comuniques estado **solo** con color (los chips de "confirmar" llevan icono + texto).

---

## 8. Iconografía e imagen

- Iconos vectoriales consistentes (Material Symbols o set único). `flutter_svg` para nitidez.
- Sin emojis en UI clínica. Sin imágenes decorativas que resten seriedad.
- Logo/branding discreto; el protagonista es el contenido clínico.

---

## 9. Herramientas de apoyo para componentes

Cuando necesites generar o inspirarte en componentes concretos:
- **Skill `ui-ux-pro-max`**: catálogo de estilos, paletas, pairings tipográficos y stacks
  (incluye Flutter). Útil para decisiones de estilo y revisión de UI.
- **MCP Magic / 21st** (`mcp__magic__*`): generación/refinamiento de componentes e inspiración.
  Tradúcelos al design system propio (tokens), no pegues estilos sueltos.

> Sea cual sea la fuente, **todo componente productivo consume los tokens del `design_system/`**.
> No introduzcas hex hardcodeado ni estilos inline dispersos.

---

## 10. Checklist de calidad UI/UX (antes de dar una pantalla por terminada)

- [ ] ¿Usa tokens del design system (color, espaciado, radio, tipografía)? ¿Cero hex sueltos?
- [ ] ¿Se ve bien en compact / medium / expanded / large? ¿Master-detail donde aplica?
- [ ] ¿Light y dark correctos? ¿Densidad adaptativa por plataforma?
- [ ] ¿Estados loading (skeleton) / empty / error / success diseñados?
- [ ] ¿Badge de transparencia "asistido por IA" visible donde corresponde?
- [ ] ¿`needs_confirmation` señalado con color **+ icono + texto** (no solo color)?
- [ ] ¿Contraste AA, objetivos ≥48px, navegación por teclado, text scaling sin romper?
- [ ] ¿Acción de validar deliberada (sin auto-guardado)? ¿Confirmación al guardar?
- [ ] ¿Animaciones sutiles y respetan reduce-motion?
- [ ] ¿Sin PHI en mensajes de error ni en logs?
