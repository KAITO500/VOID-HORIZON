# VOID HORIZON — VH-DEV-001
## Auditoría técnica y preparación del gameplay principal

**Fecha:** 2026-11-24
**Proyecto inspeccionado:** `D:\Angel\VOID-HORIZON-main`
**Motor:** Godot 4.7.2.stable.official
**Alcance:** inspección de solo lectura; no se modificaron scripts, escenas, controles ni recursos del proyecto inspeccionado.

## Addendum — roadmap y continuidad (2026-11-24)

Después de esta auditoría, el usuario marcó Fase 04 — Space Navigation como fase actual y entregó un encargo de implementación. Esa instrucción más reciente reemplaza la recomendación anterior de priorizar Fase 03 o crear un bucle de carreras como siguiente tarea. La arquitectura de circuitos de la sección 6 responde al prompt VH-DEV-001 original; queda como propuesta preliminar, fuera del alcance activo de Fase 04. La implementación y estado de Fase 04 están en `docs/PHASE_04_SPACE_NAVIGATION.md`.

El usuario mantiene las carreras entre los pilares del juego, pero la secuencia vigente para el trabajo inmediato es 03 Flight System → 04 Space Navigation → 05 Planetary Approach, y el encargo de Fase 04 excluye el HUD específico de carreras.

## 1. Resumen ejecutivo

VOID HORIZON tiene un prototipo jugable de vuelo arcade en tercera persona: una nave `CharacterBody3D`, entrada de teclado/ratón, aceleración con límite de velocidad, rotación, asistencia lateral, boost, frenado, cámara perseguidora, HUD, efectos de polvo y un entorno espacial procedural. Las comprobaciones headless existentes pasan en una copia exacta de la carpeta de D: ejecutada con Godot 4.7.2. También inicia la escena asignada a F5 durante cinco frames sin errores en la salida headless.

Esto verifica la lógica cubierta por los checks y la carga básica de escenas. No verifica el tacto de vuelo, la visibilidad del HUD en una ventana renderizada, la legibilidad, el ajuste de colisión del modelo ni el rendimiento en hardware real.

El proyecto aún no es un juego de carreras: los aros se generan como `MeshInstance3D` decorativos. No existen checkpoints, secuencia de progreso, rutas alternativas validadas, temporizador, clasificación, IA de carrera, obstáculos jugables, combate, gravedad planetaria, transición atmosférica ni multijugador funcional.

Hay dos discrepancias de continuidad importantes:

1. El contexto documental describe exploración, combate y cooperativo como pilares; el encargo VH-DEV-001 prioriza carreras espaciales y planetarias de velocidad extrema. Hay que reconciliar esa visión antes de fijar alcance de producto.
2. `D:\Angel\VOID-HORIZON-main` no contiene `.git`, por lo que no se puede atribuirle un commit o rama. Varios archivos de HUD y pruebas también difieren de la rama de trabajo disponible en `Documents\Codex`; esa rama no se debe asumir presente en la carpeta de D:.

## 2. Estructura y arquitectura actual

- `project.godot`: Godot 4.7 / Forward+, viewport 1280×720, interpolación física activada. `run/main_scene` apunta a `scenes/flight/flight_test.tscn`.
- `scenes/main/main.tscn` y `scripts/core/main.gd`: escena raíz mínima de arranque; no es la escena que ejecuta F5.
- `scenes/environment/` y `scripts/environment/`: cielo, estrellas, nebulosas, cuerpo celeste de fondo, iluminación y escena de inspección espacial.
- `scenes/ships/`, `scripts/ships/`, `resources/ships/`, `assets/models/ships/`: nave, modelo GLB, puntos de anclaje, colisiones y datos.
- `scenes/flight/`, `scripts/flight/`, `resources/flight/`: escena de vuelo, entrada, controlador, matemática, overdrive, cámara, HUD y estelas de velocidad.
- `tests/unit/`: checks headless de las fases 01, 02, vuelo y HUD.
- `systems/`: no contiene sistemas de gameplay de carrera en la copia inspeccionada.

El vuelo separa las responsabilidades de forma razonable:

```text
FlightInput → ShipIntent → FlightController → FlightMath / FlightBoost → Spaceship
                                           ↘ ShipEngineVisuals
FlightCamera, FlightHud y SpeedStreakEffect leen el estado de la nave/controlador.
```

`FlightMath`, `FlightBoost` y `FlightConfig` son reutilizables y no dependen de nodos. `ShipNetworkState` separa algunas propiedades y ofrece capturar/aplicar una instantánea, pero no replica datos ni abre conexiones.

## 3. Estado real por sistema

Se usan exactamente las categorías solicitadas.

| Sistema | Estado | Evidencia y límites |
|---|---|---|
| Configuración y escena F5 | IMPLEMENTADO Y VERIFICADO | La escena de vuelo abre en headless; no hay menú ni flujo de juego real. |
| Matemática del entorno espacial | IMPLEMENTADO Y VERIFICADO | `phase01_math_check.gd` pasa pruebas de dirección, banda y tamaño angular. |
| Presentación del entorno procedural | IMPLEMENTADO, PERO NO VERIFICADO | Hay shaders y escenas; el arranque headless no acredita su apariencia ni su coste GPU. |
| Modelo y estructura de la VH-01 | IMPLEMENTADO Y VERIFICADO | `phase02_ship_check.gd` pasa; comprueba GLB, orientación -Z, dimensiones, anclajes y formas de colisión presentes. La prueba no valida ajuste visual de las cajas. |
| Aceleración, velocidad, rotación, asistencia lateral, freno y boost | IMPLEMENTADO Y VERIFICADO | `phase03_flight_check.gd` pasa cap, aceleración, freno, deriva con/sin asistencia, signos de giro, ortonormalidad y ciclo de boost. |
| Entrada real de teclado y ratón | IMPLEMENTADO, PERO NO VERIFICADO | Está conectada en la escena; no se hizo una sesión interactiva de pilotaje. No existe soporte de gamepad. |
| Cámara de tercera persona | IMPLEMENTADO, PERO NO VERIFICADO | Script y escena cargan; su seguimiento, encuadre y FOV no se evaluaron en ventana renderizada. |
| HUD de vuelo | IMPLEMENTADO, PERO NO VERIFICADO | El check verifica construcción espacial, datos simulados, resolución y estados de preview. No valida legibilidad visual; el test termina con avisos de recursos no liberados. |
| Aros de práctica del testbed | PARCIALMENTE IMPLEMENTADO | Se dibujan 18 toros en zigzag; no tienen `Area3D`, colisión, IDs ni progreso. |
| Carreras abiertas y checkpoints | DISEÑADO, PERO NO IMPLEMENTADO | El encargo define la experiencia; todavía no hay definición técnica de carrera en el código. Este informe propone una primera estructura. |
| Drift dedicado / maniobras | PARCIALMENTE IMPLEMENTADO | Con asistencia desactivada se conserva velocidad lateral; no hay estado, input ni curva de drift dedicados. |
| Overdrive sostenido | IMPLEMENTADO EN ESTE AJUSTE | Shift mantiene la sobreaceleración mientras se pulsa; no hay timer de energía. Un hipersalto discreto sigue pendiente para Fase 08. |
| Combate, armas, escudos y selección de objetivo | NO IMPLEMENTADO | `fire_primary` solo es un campo de intención; no existe arma ni blanco. |
| IA de rivales | NO IMPLEMENTADO | No hay pilotos de IA. |
| Gravedad, vuelo atmosférico y transición a superficie | DISEÑADO, PERO NO IMPLEMENTADO | Existen cuerpos decorativos de fondo, pero no física planetaria ni transición continua. |
| Multijugador cooperativo | DISEÑADO, PERO NO IMPLEMENTADO | `ShipNetworkState` es un placeholder local; no hay RPC, sincronizadores ni autoridad de servidor operativa. |

### 3.1 VH-01 WRAITH y movimiento

- `FlightInput` llena `ShipIntent`; `FlightController` solo procesa la nave localmente si `ShipNetworkState.is_owned_locally()` lo permite.
- La velocidad es un vector en m/s. `FlightMath.step_velocity()` separa velocidad longitudinal y lateral; la asistencia aplica amortiguación exponencial lateral, mientras que sin asistencia se conserva el drift.
- Valores principales de `FlightConfig`: máximo normal 220 m/s, reversa 30%, tope absoluto 5.000 m/s, aceleración 90 m/s², deceleración 110 m/s², freno 160 m/s².
- Shift fuerza acelerador hacia delante con sobreaceleración sostenida mientras se mantiene pulsado, hasta ×20 de velocidad nominal (4.400 m/s) y ×5 de aceleración. No tiene reserva temporal ni bloqueo por energía. El polvo de puntos se sustituyó por estelas radiales de pantalla, visibles solo entre 900 y 4.200 m/s.
- El testbed Khepri está a 85 km frente a la nave. Las estelas radiales están apagadas por debajo de 900 m/s y ganan intensidad hasta 4.200 m/s. El nuevo shader no se ha probado en una ventana renderizada.
- Pitch, yaw y roll son velocidades angulares locales suavizadas; pitch/yaw/roll nominales son 100/80/160 grados por segundo, con penalización de giro del 25% a velocidad máxima.
- La prueba cubre matemática y estados de boost, pero no latencia de input, respuesta percibida, maniobras en circuito, interacción con obstáculos ni tuning de carrera. Los números son valores iniciales, no balance validado.

### 3.2 Cámara y controles

La cámara mantiene su posición ligada a la nave, pero interpola orientación; usa distancia 26 m, altura 6,5 m y anticipación 45 m. Amplía FOV y se aleja levemente con velocidad/boost. El entorno requiere una distancia de visión muy alta, y la escena F5 fija `far` en 500000 m. Estos valores necesitan revisión visual, en particular el compromiso entre ver el espacio y la precisión de profundidad cercana.

Acciones registradas en tiempo de ejecución: W/S aceleración/reversa, flechas para pitch y yaw junto con A/D, Q/E roll, Shift sobreaceleración sostenida (mantener), X freno, F asistencia, H ayuda, Escape libera el ratón y R reinicia el testbed. No hay menú de reasignación ni gamepad.

## 4. Comprobaciones realizadas

Se copió temporalmente la carpeta D: al workspace porque el proceso de Godot no pudo abrir D: bajo el aislamiento del entorno. No se cambió ningún archivo de la copia original. Sobre esa copia, con Godot `4.7.2.stable.official`:

- `phase01_math_check.gd`: PASS, exit 0.
- `phase02_ship_check.gd`: PASS, exit 0.
- `phase03_flight_check.gd`: PASS, exit 0.
- `phase03_hud_check.gd`: PASS, exit 0.
- Inicio headless de la escena principal durante cinco frames: exit 0, sin errores en stdout.

El check del HUD emite al finalizar 320 diagnósticos de limpieza del renderer (warnings/errors), además de reportar instancias y recursos sin liberar. La prueba agrega escenas y superficies a `SceneTree` y termina con `quit()` sin destruir todo el árbol/instancias de preview. Esto apunta al harness de prueba; no demuestra una fuga en la sesión normal del juego, pero debe limpiarse para que el check produzca una señal clara.

No se hizo revisión gráfica interactiva ni medición de FPS, memoria o GPU. Por ello, la clasificación de render y controles no se eleva a verificada.

## 5. Problemas y deuda técnica

1. **La escena F5 es un testbed.** `main.tscn` existe pero no es el punto de entrada configurado; todavía no hay flujo de juego.
2. **Los aros engañan como prototipo de carrera.** `flight_test_scene.gd` solo crea mallas. Ningún código sabe si el jugador atravesó un aro ni en qué orden.
3. **Colisión no validada contra el GLB.** Las cuatro cajas se conservan de una versión anterior y la prueba verifica presencia/conteo, no el solapamiento real con fuselaje, alas y motores (KI-018).
4. **El check del HUD no limpia recursos.** 320 avisos del renderer por ejecución dificultan detectar errores nuevos.
5. **Datos repetidos o placeholders.** `ShipConfig` conserva campos `_ref` que la física no lee; por ejemplo, `max_speed_ref=300` frente a `FlightConfig.max_speed=220`. `visual_scene` también está declarado pero no se consume (KI-023).
6. **Código visual alternativo sin ruta de producción.** `LightFighterModel` y `ShipHullBuilder` son herramientas/fallback; el modelo en escena es el GLB. Documentar si se mantienen para inspección o se retiran en una tarea posterior.
7. **Rendimiento sin medir.** Hay 4000 instancias de estrellas, dos capas de nebulosa con ruido procedural y 700 quads de polvo; cada capa de nebulosa evalúa FBM en fragmentos. No existe profiling del objetivo de hardware.
8. **Escala y balance preliminares.** La velocidad de boost efectiva y tasas de giro no se han probado con una persona volando a través del testbed.
9. **Documentación divergente.** `01_GAME_DESIGN.md` todavía declara que no hay sistemas implementados y el master context no incorpora carreras como pilar principal. `05/06/07` mezclan estado de distintas ramas y fechas. La carpeta D: no tiene `.git`; su revisión no permite asociar archivos con un commit.
10. **HUD de D: y rama de trabajo distintos.** Los hashes de `flight_hud.gd`, `flight_hud_preview.gd`, `phase03_hud_check.gd` y su documento no coinciden con la rama `feature/phase03-wraith-flight-hud` en `Documents\Codex`. Por ejemplo, D: conserva `queue_free()` al reconstruir paneles y el test no limpia el árbol; la rama actual contiene correcciones para ello. No asumir que la versión de esa rama está instalada en D:.

## 6. Arquitectura técnica preliminar para carreras abiertas

El circuito debe verificar progreso por secuencia de checkpoints y permitir libertad de trayectoria dentro de cada tramo. No debe convertir el recorrido en una spline obligatoria ni exigir pasar por un túnel continuo.

### Datos

- `RaceDefinition` (`Resource`): identificador, salida/meta, reglas, vueltas, límites del recorrido y referencias a nodos/checkpoints.
- `CheckpointDefinition` (`Resource`): ID estable, transform/orientación, forma del plano de cruce, dirección válida, penalización, tipo obligatorio/opcional y transform de recuperación.
- Grafo dirigido de rutas entre checkpoints obligatorios: cada arista define qué checkpoints alternativos/riesgo se permiten antes de un punto de reunión obligatorio. El progreso se expresa como estados/IDs válidos, no como distancia a una spline.

### Componentes de runtime

- `RaceDirector`: carga la definición, inicia/finaliza el evento y publica cambios de estado.
- `RaceProgress`: estado separado por participante: checkpoint esperado, ramas válidas, vuelta, tiempo, penalizaciones y último punto de recuperación.
- `CheckpointGate` (`Area3D` o detector geométrico): detecta cruce con dirección correcta. Mantiene la posición anterior y comprueba el segmento barrido entre ticks para evitar atravesar la puerta a alta velocidad sin detectar el solapamiento.
- `RaceClock` / `RaceRanking`: registran tiempos y ordenan por vuelta, progreso válido, instante de cruce y penalizaciones.
- `RaceRecovery`: devuelve al jugador a una zona segura del último checkpoint válido; conserva el progreso y aplica la penalización definida.
- Interfaz mediante señales/eventos con IDs estables. La nave, cámara y HUD no deben decidir el progreso.

### Validación y justicia

Solo se acepta un checkpoint que sea sucesor permitido del estado actual. Una puerta futura atravesada fuera de orden no otorga progreso. Las rutas alternativas son explícitas en el grafo y se vuelven a unir en checkpoints obligatorios. Las ramas de riesgo pueden tener recompensa/penalización de tiempo sin imponer una trayectoria entre gates.

En multijugador futuro, el servidor será autoridad para el estado de carrera y validará cruces usando posiciones/segmentos recibidos y secuencias monotónicas. Los clientes pueden predecir la interfaz, pero no adjudicar progreso. IA y jugador deben consultar la misma API `RaceProgress`; la IA puede elegir rutas y conducir entre gates mediante navegación propia.

Primera versión recomendada: carrera local de una vuelta, checkpoints con cruce direccional, bifurcación y reencuentro, cronómetro, clasificación local y recuperación. Añadir redes, rivales y gravedad planetaria después de validar el bucle local.

## 7. Orden recomendado de desarrollo

1. Acordar la visión documental: carreras planetarias/espaciales como pilar, y decidir el lugar de exploración, combate y cooperativo.
2. Corregir el harness del HUD para liberar el árbol e instancias; mantener el test headless sin warnings de fuga.
3. Hacer una sesión manual de vuelo: teclado/ratón, boost, frenado, drift con asistencia desactivada, cámara, HUD y colisiones. Ajustar física a partir de esa evidencia.
4. Crear definición de carrera local y progreso secuencial; reemplazar los aros decorativos por gates con detección robusta.
5. Añadir ramas alternativas, reloj, posiciones, recuperación y una carrera de prueba.
6. Probar obstáculos dinámicos y adaptar IA a la API de progreso.
7. Diseñar gravedad y transiciones planetarias después de que vuelo y checkpoints estén estables.
8. Añadir combate y red cooperativa cuando el núcleo de carrera local y autoridad de estado estén definidos.

## 8. Riesgos técnicos

- A velocidades altas, una detección solo por overlap discreto puede saltarse gates; usar cruce barrido de plano.
- Rutas abiertas necesitan reglas de progreso inequívocas para que atajos sean válidos y saltarse checkpoints no lo sea.
- Replicar transforms sin autoridad de carrera permitirá progreso falso o estados desincronizados; reservar la validación al servidor.
- Estrellas/nebulosas/polvo y un `far` de 500 km pueden tener costes o artefactos de precisión; medirlos en la GPU objetivo.
- La física espacial no modela gravedad ni colisión física de forma avanzada; añadir terreno/planetas prematuramente puede forzar cambios grandes.
- El modelo y sus cajas de colisión no se han revisado juntos en una ventana renderizada.
- La carpeta D: sin `.git` facilita que una copia extraída se quede atrás de la rama de desarrollo.

## 9. Resultado solicitado

### A. Qué funciona actualmente

Los cuatro checks headless existentes pasan en Godot 4.7.2 en la instantánea de D:, y la escena F5 carga durante una ejecución headless corta. La matemática arcade, boost/freno/asistencia, rig de nave, HUD estructural y preview están cubiertos por esas pruebas.

### B. Qué necesita corrección

Limpiar recursos al final de `phase03_hud_check.gd`; alinear documentos con la visión de carreras; validar visualmente HUD, cámara y colisiones; decidir qué datos `_ref`/fallbacks se conservan; y asegurar que D: se sincroniza de forma trazable con una rama Git.

### C. Qué está pendiente

Una sesión manual de pilotaje y el gameplay de carreras: checkpoints, progreso, rutas, tiempos, clasificación y recuperación. Después: IA, obstáculos interactivos, vuelo planetario, combate y cooperativo.

### D. Siguiente tarea de implementación recomendada

VH-DEV-002: **bucle local mínimo de carrera abierta**, empezando por datos de checkpoints y progreso secuencial/direccional en una vuelta. Es el primer incremento que convierte el testbed actual en una carrera verificable.

### E. Archivos concretos a crear o modificar en VH-DEV-002

- Crear `resources/races/first_open_race.tres` y `scripts/races/race_definition.gd`.
- Crear `scripts/races/checkpoint_gate.gd`, `scripts/races/race_progress.gd`, `scripts/races/race_director.gd` y `scripts/races/race_clock.gd`.
- Crear una escena de checkpoint bajo `scenes/races/`.
- Modificar `scripts/flight/flight_test_scene.gd` o crear una escena nueva de carrera para sustituir los aros no funcionales por gates enlazados a la definición.
- Crear `tests/unit/race_progress_check.gd` para orden, dirección, rama alternativa, cruce barrido, finalización y reinicio.

Esta auditoría no implementa VH-DEV-002.
