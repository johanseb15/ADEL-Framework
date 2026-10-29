# ADEL-RELEASE-001 — Entrega verificable y aprendizaje

**Estado:** propuesta integrada en rama de revisión; no modifica el runtime del framework.  
**Origen:** retrospectiva del lanzamiento público de Vyntrava Technologies, 29/10/2026.  
**Ámbito:** módulo transversal para cualquier proyecto, proporcional a su riesgo y tipo de entrega.

## 1. Compatibilidad con ADEL

Este módulo **no crea otra metodología ni reemplaza** el flujo de especificación, Superpowers, TDD RED → GREEN → REFACTOR, arquitectura brownfield-first, auditoría independiente o gates existentes.

- Se añade una disciplina de **entrega y observación** a los criterios de aceptación del producto.
- El dueño de cada producto conserva la autoridad sobre alcance, diseño, publicación y riesgo residual.
- El framework aporta **plantillas y reglas reutilizables**, no mueve datos, activos ni especificaciones entre repositorios.
- No se exige infraestructura de producción a prototipos, scripts o pruebas locales que no se publiquen. La puerta de release se activa cuando existe un destino de entrega real.
- Un componente puede cumplir **Definition of Done (DoD)** sin que una versión cumpla **Definition of Released (DoRls)**.

## 2. Gates y resultados

**DoD — incremento listo:** criterios de aceptación satisfechos; tests exigidos y regresión, typecheck/build cuando aplique; TDD evidenciado; seguridad y documentación proporcional; sin defectos bloqueantes conocidos.

**DoRls — versión entregada:** DoD de los cambios incluidos; ambiente y ruta de distribución declarados; configuración compatible; permisos/secretos revisados; licencias y privacidad pertinentes revisadas; autorización explícita; artefacto y commit trazables; despliegue y smoke tests reales; procedimiento de rollback definido; responsable y seguimiento pospublicación.

La evaluación admite:
- **GO:** todas las condiciones obligatorias satisfechas y evidencia disponible.
- **GO CONDICIONADO:** controles de seguridad/legalidad y funcionamiento esencial aprobados, con riesgos **no bloqueantes** identificados, responsable, aceptación explícita, mitigación, plazo y revalidación. No equivale a alterar el resultado de los tests.
- **NO-GO:** falta evidencia esencial, hay fallas críticas, secretos expuestos, riesgo legal material no resuelto, incumplimiento de aceptación funcional esencial, pruebas obligatorias fallidas sin solución o despliegue no verificable.

La aceptación comercial **no puede** levantar arbitrariamente un NO-GO de seguridad, privacidad, obligaciones legales o funcionamiento esencial. Los puntajes de una herramienta son señales para interpretar, **no políticas universales**: por ejemplo, un `noindex` deliberado en una prepublicación puede reducir SEO sin ser un defecto de la versión. Registrar el motivo y el cambio de política cuando corresponda.

## 3. Protocolo liviano por release

1. **SPEC:** definir usuario, valor, entorno, criterio observable de entrega, criterios de aceptación y riesgos relevantes.
2. **BUILD y VERIFY (ADEL existente):** implementar con TDD y conservar evidencias; asegurar paridad del CI con los navegadores/entornos exigidos.
3. **RELEASE GATE:** completar `release-decision.md` (plantilla), clasificar riesgos y obtener aprobación del responsable. Mantener aprobación visual o de publicación separada cuando el proyecto la requiera.
4. **DEPLOY:** publicar mediante el canal autorizado, con identificador de commit, artefacto y rollback. Los permisos y secretos nunca deben publicarse en informes.
5. **OBSERVE:** comprobar disponibilidad y recorrido funcional esencial en el **entorno real**; medir experiencia cuando corresponda; registrar fallas y responsables.
6. **LEARN:** registrar hipótesis, resultado y propuesta de mejora; promover a regla universal solo si se demuestra aplicabilidad y compatibilidad con reglas existentes.

No se exige realizar siete reuniones ni producir siete documentos. Se reutiliza la evidencia ya disponible y se completa un registro breve por release.

## 4. Política de evidencia

- Una ejecución CI verde confirma los controles **ejecutados**, no requisitos ausentes del workflow.
- Un Lighthouse exitoso significa **auditoría ejecutada**; los puntajes y limitaciones se evalúan aparte. Medir móvil y escritorio por separado cuando aplique. Resultados de laboratorio no equivalen a datos de usuarios reales.
- Ante una optimización, registrar baseline, cambio aislado, comparabilidad del entorno y repetición de mediciones cuando las diferencias sean pequeñas. **Sin mejora demostrada, revertir o clasificar como experimental**.
- El monitoreo posdeploy necesita evidencia de URL, estado HTTP y contenido/recorrido esperado. La mera ejecución del job no reemplaza esta verificación.
- Cuando una falla se repite, evaluar cómo prevenirla con automatización (sin crear nuevos gates costosos sin evidencia de beneficio).

## 5. Aprendizajes observados en Vyntrava (no generalizaciones automáticas)

| Observación | Regla reutilizable |
| --- | --- |
| CI inicial no representaba los dos navegadores probados localmente | Definir matriz de entornos y exigir paridad verificable |
| El sitio estático bajo subruta necesitaba enlaces y assets adecuados | Incluir destino de hosting en SPEC y prueba de export/rutas |
| Lighthouse primero falló por instrumentación | Probar y diagnosticar las herramientas de medición |
| Una precarga de imagen no demostró mejoría móvil | Experimentos de rendimiento con baseline, medida posterior y rollback |
| SEO bajó por `noindex` voluntario | Distinguir política de publicación de defecto técnico |
| CI, Lighthouse, despliegue y smoke HTTPS aportaron evidencias distintas | No confundir DoD, medición, deploy y DoRls |
| Se aceptó rendimiento móvil mejorable para lanzar | Registrar y autorizar deuda no crítica; no falsear gates |

## 6. Criterios de aceptación de ADEL-RELEASE-001

- [x] No modifica scripts, perfiles, toolchain ni reglas de autoridad de ADEL.
- [x] Respeta brownfield-first, SPEC, TDD y gates existentes.
- [x] Separa DoD, release, auditoría y observación.
- [x] Incluye clasificación y tratamiento explícito de riesgos.
- [x] No impone Lighthouse, SEO, navegadores ni publicación web a proyectos que no correspondan.
- [x] Ofrece plantilla de registro por release.
- [ ] Revisión independiente de contenido y compatibilidad.
- [ ] Validación en un segundo proyecto antes de convertir criterios opcionales en obligaciones universales.

**Límite de esta entrega:** es una especificación/plantilla documental; no se ejecutaron pruebas de PowerShell en esta rama, ni se declara adoptada por los proyectos ya existentes.
