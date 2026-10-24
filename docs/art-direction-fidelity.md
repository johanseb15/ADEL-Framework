# ADEL — Gate de fidelidad a la dirección artística (ART-LOCK-001)

## Propósito
Evitar que asistentes, agentes, diseñadores o implementadores sustituyan inadvertidamente la **dirección artística ya aprobada** por otro medio, estilo o lenguaje visual. Esta regla aplica a **todos los proyectos con componentes visuales**, usando **el contrato particular de cada producto**. ADEL no impone una estética universal.

## Incidente que origina la regla (WhoLivesHere, 2026-10-20)

- **Dirección aprobada del producto:** casas/ambientes de apariencia realista y personajes estilizados en **3D** para la revelación («personajes de juguete, casas de verdad»).
- **Desvío observado:** se creó y se recomendó aprobar una escena **SVG/vectorial** para Alma (H06) como referente artístico definitivo de H07–H20, basándose en legibilidad, validez XML y similitud con placeholders existentes.
- **Error de proceso:** se confundió una ilustración funcional con el estándar artístico final. Se validaron composición y técnica **sin cotejar antes el medio visual contra el contrato del fundador**. Las auditorías estéticas de terceros y los recursos provisionales no sustituyen ese contrato.
- **Contención:** el SVG de H06 se conserva solo como prototipo para posición de pistas; no se promueve como arte final ni se extiende a otros hogares. No inferir que cualquier SVG existente es una referencia artística aprobada.

## Regla obligatoria

**Antes de cualquier trabajo visual: recuperar, leer y citar en la especificación la decisión artística vigente.** Debe registrarse el origen y la fecha de la decisión cuando estén disponibles, junto con referencias aprobadas y una lista explícita de cosas prohibidas.

La precedencia de decisiones es:
1. Decisión explícita más reciente del fundador o responsable autorizado.
2. Contrato/Art Bible aprobado para el proyecto, siempre que no contradiga (1).
3. Recursos **finales aprobados** como referencias concretas, con estado y procedencia verificables.
4. Propuestas, auditorías externas, prototipos, arte temporal y sugerencias de agentes: **hipótesis**, nunca autoridad suficiente para cambiar (1)–(3).

Si las fuentes se contradicen, faltan o no puede determinarse qué versión está aprobada: **detenerse, describir el conflicto y solicitar resolución**. No inventar una dirección propia.

## Contrato artístico mínimo por proyecto

Cada iniciativa visual documenta en su propio repositorio:
- Medio visual por elemento: fotografía, CGI realista, 3D estilizado, 2D, SVG, etc.
- Estilo, nivel de realismo, materiales, iluminación, paleta y características identitarias; separar **ambientes**, **personajes** e **interfaz**.
- Referencias maestras aprobadas con rutas o enlaces, estado (`aprobado`/`provisional`) y fecha/decisor.
- Lo que **no se debe hacer** y qué cambios requieren nueva aprobación.
- Criterios de aceptación y evidencias visuales por dispositivos y momentos de uso.

La plantilla del framework `templates/react-vite-ts/docs/ART-DIRECTION.md` provee campos, pero **no define el estilo de ningún producto** ni reemplaza decisiones previas. En proyectos brownfield primero se lee el contrato y los activos existentes; no se sustituye por el template.

## Gates ejecutables de proceso

| Momento | Control | Condición de bloqueo |
| --- | --- | --- |
| **Spec / Superpowers** | Registrar contrato artístico y referencias antes de crear un plan de assets | No existe fuente aprobada o hay contradicción sin resolver |
| **Plan y generación** | Cada asset declara destino, medio, estado (`prototipo`/`final-candidato`) y referencia | El medio o estilo propuesto difiere sin aprobación |
| **Revisión y QA** | Comparar el resultado con referencias finales al mismo uso y viewport; comprobar pistas, legibilidad y accesibilidad | Solo pasó validación técnica, no validación artística |
| **Integración** | Separar prototipos/placeholders de recursos finales; no reemplazar masters sin autorización | Cambiaría el lenguaje visual aprobado o sustituiría arte final |
| **Entrega** | Registrar evidencia y aprobación del responsable de arte/producto, además de tests y build | No hay aceptación artística explícita para assets definitivos |

Un cambio de estilo, técnica de render, medio o tratamiento de personajes se considera **cambio de dirección**, no mero pulido, aunque el resultado sea técnicamente válido. Requiere decisión explícita. Refinamientos menores *dentro* del mismo lenguaje visual no requieren reabrir la dirección completa.

## Checklist ART-LOCK-001 para agentes

- [ ] Localicé y leí la última dirección artística aprobada de **este** proyecto.
- [ ] Verifiqué si las imágenes existentes son referencias finales o placeholders técnicos.
- [ ] Especifiqué medio/estilo permitido por tipo de asset y su referencia.
- [ ] Contrasté mi propuesta con la decisión vigente antes de generar o recomendar implementación.
- [ ] Marqué candidatos y prototipos como **no finales** y mantuve los originales.
- [ ] Confirmé que los cambios no modifican implícitamente el estándar artístico.
- [ ] Ejecuté QA técnico **y**, por separado, revisión estética del material renderizado.
- [ ] No promoví ni publiqué arte definitivo sin aprobación.

## Ejemplo específico: WhoLivesHere

- **Ambientes:** imágenes realistas/de apariencia fotográfica, con pistas integradas naturalmente.
- **Revelación:** personajes 3D estilizados premium, coherentes entre sí.
- **Interfaz:** conservar React/CSS aprobado.
- **SVG de escenas:** aceptable como placeholder funcional para pruebas, **no** como dirección artística final.
- **Lección:** una captura visualmente legible y un SVG XML válido no bastan para declarar una escena aprobada.

**Esta especificación es un control transversal de proceso.** No cambia por sí sola los assets de WhoLivesHere ni reinterpreta el contrato de otros proyectos.
