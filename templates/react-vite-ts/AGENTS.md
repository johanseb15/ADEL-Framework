# ADEL — Instrucciones para agentes en este proyecto

Antes de ejecutar trabajo, leer las especificaciones y decisiones vigentes del proyecto. Aplicar Superpowers y ADEL: preservar arquitectura brownfield, alcance limitado, criterios de aceptación, TDD y verificación independiente.

## Puerta de arte: ART-LOCK-001

**Para cualquier tarea visual (diseño, imágenes, personajes, UI ilustrada, animación):**
1. Leer `docs/ART-DIRECTION.md` y las decisiones más recientes del responsable del producto; en proyectos existentes, recuperar el Art Bible y referencias aprobadas antes de diseñar.
2. Respetar el **medio y estilo de cada tipo de asset**. No cambiar fotografías/realismo por SVG/vector ni 3D por 2D, ni realizar otro cambio equivalente, sin autorización explícita.
3. Diferenciar `prototipo`, `candidato` y `final aprobado`. Un placeholder útil para pruebas **no** es referencia ni arte definitivo.
4. Si el contrato está sin definir, desactualizado o es contradictorio, **detener la generación o promoción del arte y pedir una decisión**. No elegir estilo por conveniencia técnica ni por sugerencias de otras IA.
5. Validar conformidad artística de modo independiente a XML/render correcto, tests, TypeScript, build y Playwright. No afirmar «aprobado artísticamente» sin revisión humana frente a la referencia.
6. Preservar el diseño y los activos existentes; no sobrescribir maestros ni publicar sin aprobación.

Para tareas no visuales, estas reglas no deben introducir trabajo de diseño innecesario.

Procedimiento transversal: `ADEL-Framework/docs/art-direction-fidelity.md` (repositorio original del framework).
