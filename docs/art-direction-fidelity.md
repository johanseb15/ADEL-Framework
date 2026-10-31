# ADEL-EVO-003 — Art Direction Lock y Design Quality

## Alcance

Este control aplica a proyectos con componentes visuales y a sus tareas visuales. Cada producto conserva en su repositorio la autoridad sobre su dirección artística; ADEL no fija una estética, medio ni paleta universal. No impone obligaciones visuales a `python-cli`.

El caso ART-LOCK-001 detectó que un SVG válido y legible, útil como prototipo, se propuso como referencia artística definitiva pese a que el producto había aprobado otro medio visual. La validez técnica de un recurso no demuestra fidelidad a la dirección aprobada.

## Decisiones y autoridad

Antes de proponer o generar arte, recuperar y citar la decisión vigente del fundador o responsable autorizado, con origen, fecha y referencias finales trazables. La precedencia es: (1) decisión explícita más reciente del fundador o responsable autorizado; (2) Art Bible o contrato aprobado que no la contradiga; (3) activos finales aprobados de procedencia verificable; (4) propuestas, auditorías, prototipos, placeholders y recomendaciones de agentes como hipótesis. Si falta una fuente o hay conflicto, detener la generación o promoción del arte definitivo y pedir resolución. No transferir reglas de un producto a otro.

Cada proyecto visual documenta por tipo de recurso el medio, estilo, nivel de realismo, materiales, iluminación, paleta, referencias aprobadas, prohibiciones y cambios que requieren nueva aprobación. La plantilla React [ART-DIRECTION.md](../templates/react-vite-ts/docs/ART-DIRECTION.md) contiene el contrato autocontenido que se copia al proyecto. En brownfield se recuperan primero las decisiones y activos propios del producto; la plantilla no los reemplaza.

## Estados y gates

- **Prototipo:** exploración o placeholder `PROVISIONAL`; no es referencia final.
- **Candidato:** propuesta para revisión, sin autorización para reemplazar maestros ni publicar. Equivale a `final-candidato` en ART-LOCK-001.
- **Final aprobado:** aceptación explícita del fundador o responsable autorizado, con fecha, fuente y evidencia.

No sustituir arte aprobado por placeholders o candidatos. Conservar originales y licencias. Cambiar medio, técnica o lenguaje visual aprobado requiere una nueva decisión; un pulido dentro del lenguaje vigente puede seguir el proceso de revisión ordinario.

En la especificación se cita el contrato. En el plan se identifica destino, medio, estado y referencia de cada activo. En revisión se compara referencia y resultado en el mismo viewport y estado. La integración y entrega de arte definitivo requieren aprobación humana explícita del fundador o responsable autorizado. El QA técnico (validez, carga, tests, build y accesibilidad comprobable) se registra separado de la aprobación artística. Las capturas y auditorías automáticas son evidencia, no autoridad de aprobación.

## Design Quality proporcional

Revisar tipografía, legibilidad, responsive, accesibilidad y coherencia de medio y estilo conforme al uso y a las referencias del producto. Considerar estados interactivos, teclado, foco y contraste. Documentar viewports, observaciones y límites. Si falta Browser o una herramienta de captura, declarar el QA visual limitado; ImageGen, MCP y servicios pagos son opcionales. Este gate artístico sigue separado del gate de publicación y de [ADEL-RELEASE-001](adel-release-001.md).
