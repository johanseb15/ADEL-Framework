# BOOTSTRAP-001: diseño y plan breve

**Objetivo.** Un clon nuevo ofrece un manifiesto y scripts PowerShell capaces de detectar, instalar de forma idempotente y diagnosticar las herramientas globales de ADEL, y de generar una app con lockfile verificable.

**Diseño.** `adel.tools.json` es la única fuente de perfiles/versiones. `lib/ADEL.psm1` calcula estado y plan sin efectos. `install.ps1` ejecuta solo acciones necesarias, respeta `-WhatIf`, verifica fallas externas y nunca reemplaza rutas preexistentes no verificadas. `doctor.ps1` separa estado global, skill, proyecto y capacidades de sesión. `new-project.ps1` copia una plantilla cerrada y rechaza destinos existentes.

**Plan TDD del desarrollo inicial.** 1) Pruebas RED de perfiles, comparación numérica, estados, idempotencia, `-WhatIf` y no sobrescritura. 2) Módulo puro y scripts GREEN. 3) Generar proyecto temporal, instalar con lockfile, probar y compilar. 4) Documentar recuperación, límites y validación en PC limpia. La instalación global quedó fuera de las pruebas automáticas.
