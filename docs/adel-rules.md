# Reglas ADEL consolidadas para este MVP

- Antes de implementar, registrar propósito, alcance y criterios; usar Superpowers para especificación, plan, TDD y verificación. Las aprobaciones de arte y publicación son puertas separadas.
- Conservar reglas de producto en cada repositorio; el framework instala herramientas y crea proyectos, no mueve especificaciones, contenido ni activos entre productos.
- Respetar la jerarquía de autoridad de cada producto. Las reglas específicas de un producto no se transfieren automáticamente a proyectos nuevos.
- Para tareas visuales, aplicar [Art Direction Lock y Design Quality](art-direction-fidelity.md): recuperar la decisión artística explícita más reciente del fundador o responsable autorizado y referencias trazables antes de proponer, generar o integrar arte. Distinguir prototipo, candidato y final aprobado; no sustituir arte aprobado por placeholders. Registrar QA técnico separado de aprobación artística humana del fundador o responsable autorizado. La plantilla visual corresponde a React, no a `python-cli`.
- Visual: capturar referencia y resultado al mismo viewport; revisar estados, teclado, foco y accesibilidad. Si falta Browser, marcar QA visual como limitada. ImageGen y MCP son capacidades opcionales sujetas a cuenta, cuota y autenticación.
- No convertir candidatos visuales en activos finales sin aprobación. Mantener originales y licencias documentadas.
- Para entregas publicables, aplicar la extensión transversal [ADEL-RELEASE-001](adel-release-001.md): distinguir incremento terminado de versión entregada; exigir decisión explícita, evidencia del entorno real y registro de riesgos. No sustituye SPEC, Superpowers, TDD, gates ni aprobaciones visuales y de publicación ya existentes. No aplica como gate de producción a prototipos sin despliegue.
- Los controles deben ser proporcionales al tipo de producto y destino. Una excepción comercial solo puede aceptar deuda no crítica documentada; nunca falsear pruebas ni dispensar seguridad, privacidad, legalidad o funcionamiento esencial.
- Superpowers se obtiene desde su tag Git público y se expone mediante la ruta de skills de usuario; la caché de un plugin no se usa como fuente de instalación ni prueba de descubrimiento.
- No editar `~/.codex/config.toml`, `~/.codex/auth.json` ni credenciales. `doctor.ps1` solo ejecuta verificaciones de versión y existencia.

Fuentes públicas: [Superpowers v6.4.2](https://github.com/obra/superpowers/releases/tag/v6.4.2), [instalación de Superpowers para Codex](https://github.com/obra/superpowers/blob/main/.codex/INSTALL.md), [Codex CLI](https://learn.chatgpt.com/docs/codex/cli).
