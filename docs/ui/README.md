# VOID HORIZON UI/UX — COSMIC VIOLET

**Status:** implementation handoff specification. The Figma file exists but is still blank; the connected Starter plan hit its Figma MCP call limit before canvas authoring. No page or prototype is represented as complete or approved.

Figma file: https://www.figma.com/design/5ClHDiCKjLYY00jJ83mF52

## Foundations

`cosmic-violet.tokens.json` records the UI-only palette, semantic aliases, typography scale, spacing, radii and target breakpoints. Keep spacecraft, planets and environment art independent of these tokens. Primary target is 1920×1080 with 64 px safe margins; validate 2560×1440, 1600×900 and 2560×1080 ultrawide.

Typography proposal: Rajdhani for display and numeric readouts, Inter for body copy, IBM Plex Mono for compact technical values. Confirm font availability in Figma before styling final components; use a metrically similar fallback only if a family is unavailable.

## Figma page plan

1. **Visual Identity** — wordmark, violet interface palette, contrast samples, UI-over-world examples.
2. **Design Foundations** — variable collections, semantic roles, typography, 4 px spacing grid, corner and elevation rules.
3. **Component Library** — component sets for buttons, navigation, tabs, panels, cards, status indicators, bars, toggles, sliders, dropdowns, notifications, warnings, tooltips and icons. Include default, hover, active, disabled, warning and critical states where relevant.
4. **Main Menu and Hangar** — cinematic menu and VH-01 WRAITH inspection/selection with speed, acceleration, maneuverability, durability, weapons and customisation.
5. **Flight HUD** — 1920×1080 front layout and editable three-quarter perspective composition. Preserve a clear center reticle and show the game world as a separate scene layer.
6. **Navigation and Star Map** — galaxy/system/planet views, routes, distances, destination and travel status.
7. **Racing and Combat** — countdown, lap/position/checkpoints/results plus targeting, weapons, ammo, shields and damage states.
8. **Planetary Interface** — entry, altitude, navigation, environmental warnings and approach/landing states, with environmental colors left untouched.
9. **Multiplayer and Progression** — sessions, lobby, players, invites, team data, player profile, unlocks, achievements and records.
10. **Settings and Accessibility** — controls, graphics, audio, gameplay, HUD scale/opacity/visibility and readable accessibility options.
11. **Prototypes** — connected examples for menu, ship selection, HUD states, race, combat, map and settings.
12. **Developer Handoff** — dimensions, anchors, safe areas, type, colors, spacing, interaction timings, states, responsive notes and Godot hierarchy.

## Component inventory and reuse

Build the primitives before screens. Use component properties for button labels, icon visibility, selected state and status text. Keep repeated menu items, tabs, stat rows, player rows, route stops and HUD indicators as instances of reusable components. Build icons as vectors and document interactive states; do not substitute glyphs or duplicated one-off groups for shared components.

## Flight HUD acceptance

- Center reticle is stable, unobstructed and in the front plane.
- Heading stays upper-center; speed stays lower-center; engine data is lower-left; target data is upper-right.
- Side information sits on separate angled panels, remains upright, inside safe areas and legible at normal gameplay scale.
- Front and three-quarter views are separate editable frames; perspective is carried by the panel planes, not decorative curved rails.
- UI overlays the live game scene without recoloring the ship, planet or environment.

## Prototype flows

- Main menu: Continue / New Game / Multiplayer / Hangar / Navigation / Settings / Exit.
- Hangar: select WRAITH → inspect statistics → customize components/paint → confirm.
- HUD: normal → boost → target acquired → warning → critical warning.
- Race: introduction → countdown → checkpoint/lap updates → result.
- Combat: acquire target → lock → select weapon → damage warning.
- Star map: galaxy → system → destination → route confirmation.
- Settings: category → control/value adjustment → apply/reset.

## Validation boundary

The Godot HUD is an implementation and must be checked against the two Figma presentation views in a running build. Current runtime screenshot showed inverted side-panel text and edge panels too large; the UV orientation and screen-safe projection sizing have been corrected in code, but require a Godot run before they can be called fixed. Figma designs also remain concept work until reviewed by the project owner.

