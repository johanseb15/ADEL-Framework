# ADEL Framework 1.2 — bootstrap para Windows

Repositorio independiente para reconstruir el entorno base de ADEL y crear proyectos React/Vite/TypeScript. No contiene credenciales, cachés de plugins ni configuración personal de Codex.

## Entrega verificable y aprendizaje (ADEL-RELEASE-001)

La extensión [ADEL-RELEASE-001](docs/adel-release-001.md) complementa SPEC, TDD, Superpowers y los gates actuales con una distinción entre **incremento terminado (DoD)** y **versión publicada y comprobada (DoRls)**. Es proporcional al tipo de proyecto; no impone despliegue web ni Lighthouse a herramientas que no lo requieran. Para cada publicación, copiá la [plantilla de decisión](docs/templates/release-decision.md) al repositorio del producto, conservá la evidencia y registrá el resultado de producción. Una decisión comercial puede aceptar deuda no crítica trazable, nunca falsear pruebas ni dispensar controles esenciales.

## Recuperación

En PowerShell 5.1 o 7, con conexión a Internet y `winget` disponible:

```powershell
git clone https://github.com/johanseb15/ADEL-Framework.git ADEL-Framework
cd ADEL-Framework
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Profile minimal -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Profile minimal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\doctor.ps1 -Profile minimal
```

Si `winget` instala Git o Node, cerrá y abrí PowerShell y repetí `bootstrap.ps1`: el instalador detecta lo ya disponible. Codex requiere inicio de sesión interactivo posterior (`codex.cmd login`); el framework nunca lee ni escribe el token. Reiniciá Codex después de instalar Superpowers para que descubra las skills.

Si `doctor.ps1` muestra Superpowers como `LIMITED cache:6.4.2`, encontró archivos del plugin, pero no puede probar que Codex los haya activado. El bootstrap evita duplicarlo. Si querés una instalación independiente desde el tag público, ejecutá `bootstrap.ps1 -InstallSuperpowersFromSource` después de revisar el `-WhatIf`.

Perfiles en [`adel.tools.json`](adel.tools.json):

| Perfil | Contenido |
| --- | --- |
| `minimal` | Git, Node, pnpm, Codex CLI y Superpowers |
| `web-app` | `minimal` y plantilla React/Vite/TypeScript |
| `visual-game` | `web-app`, Frontend Design, UI/UX Pro Max 2.5.0 y comprobación de Product Design, Browser e ImageGen opcionales |

`doctor.ps1` informa `AVAILABLE` (versión suficiente y detectable), `LIMITED` (versión antigua, skill vista solo en caché o capacidad de sesión no comprobable desde PowerShell) o `UNAVAILABLE` (herramienta local ausente). `-Capabilities browser,imagegen,product-design` declara **solo para esa ejecución** capacidades que el operador confirmó en su sesión; el script no puede descubrir herramientas hospedadas dentro de Codex. Estas capacidades opcionales no bloquean la plantilla: Playwright local, Superpowers y activos SVG/licenciados son alternativas. Las herramientas globales se instalan fuera del proyecto; React, Vite, TypeScript, Vitest y Playwright son dependencias de cada aplicación y están fijadas por su lockfile.

## Crear y probar una aplicación

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\new-project.ps1 -Name demo-adel -Path ..\demo-adel -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\new-project.ps1 -Name demo-adel -Path ..\demo-adel -InstallDependencies
cd ..\demo-adel
pnpm.cmd run test:run
pnpm.cmd run build
```

El generador se niega a sobrescribir una carpeta existente. `-InstallDependencies` instala solo las dependencias del nuevo proyecto. Para el perfil visual:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Profile visual-game -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Profile visual-game
cd ..\demo-adel
pnpm.cmd run browser:install
pnpm.cmd run test:windows
pnpm.cmd run typecheck
pnpm.cmd run build
cd ..\ADEL-Framework
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\doctor.ps1 -Profile visual-game -ProjectPath ..\demo-adel
```

`browser:install` descarga el Chromium compatible con la versión fijada de Playwright, si no existe. `test:windows` ejecuta Vitest, verifica que Chromium pueda abrir una página y después ejecuta Playwright. El E2E prueba una interacción y adjunta `home-desktop.png` en `test-results`, ignorado por Git. Las capturas y los tests automáticos sirven para detectar regresiones; la dirección artística y las referencias aprobadas requieren revisión humana.

Las skills se descargan de repositorios públicos con SHA fijado en el manifiesto y se enlazan en `CODEX_HOME\skills` (o `%USERPROFILE%\.codex\skills`). No se copia ninguna caché personal ni se reemplaza una skill existente: una ruta ocupada sin origen verificable produce error. `doctor.ps1` exige `SKILL.md`, enlace al origen y SHA correcto. UI/UX Pro Max usa Python 3 para sus scripts de búsqueda; instalalo por separado si necesitás esa función. Sus datos y reglas se pueden leer sin servicios con cuota. Reiniciá Codex para descubrir las skills.
En Windows, el origen de UI/UX Pro Max usa enlaces simbólicos para `data` y `scripts`; el instalador materializa esos directorios desde el mismo commit verificado antes de crear el enlace de Codex. `doctor.ps1` comprueba que el script de búsqueda y los datos estén presentes.

En una PC nueva, cloná primero ADEL-Framework desde el remoto indicado arriba, ejecutá `bootstrap.ps1 -Profile visual-game`, abrí una consola nueva si `winget` cambió PATH, repetí el bootstrap y ejecutá `doctor.ps1 -Profile visual-game`. Autenticá Codex interactivamente con `codex.cmd login`; el framework no guarda credenciales. Las fuentes de skills son públicas y no requieren login de GitHub, pero sí acceso HTTPS. Generá la app y ejecutá `browser:install` con acceso de red para descargar Chromium; el navegador queda en la caché de Playwright del usuario. `doctor.ps1 -ProjectPath` verifica el binario lanzándolo. El perfil instala la versión pública de Frontend Design fijada por commit.

## Verificación del framework

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Profile visual-game -WhatIf
```

Las pruebas no hacen instalaciones globales ni contactos de red.

## Límites

La prueba de este framework se hizo en la PC actual, no en una instalación limpia. `winget` puede variar por catálogo o requerir elevación; sus IDs y versiones se fijan en el manifiesto y el script falla si la instalación no termina correctamente. La autenticación de Codex, cuotas de ImageGen, acceso a Browser/MCP y licencias de activos son requisitos de sesión o cuenta y no se pueden reconstruir solo con Git. Las herramientas externas se descargan desde sus orígenes y no se redistribuyen en este repositorio; sus licencias y atribuciones figuran en [`docs/third-party.md`](docs/third-party.md).

## Validación propuesta en una PC limpia

En una VM Windows 11 sin Node, pnpm, Codex ni Superpowers: instalar Git o usar el ZIP del repositorio; ejecutar `bootstrap.ps1 -WhatIf` y confirmar que no crea carpetas; ejecutar `bootstrap.ps1 -Profile web-app`, reabrir la consola si se instaló Git/Node y repetir hasta que `doctor.ps1 -Profile web-app` marque los requisitos como `AVAILABLE`; ejecutar otra vez el bootstrap y comprobar que no instala nada; generar una app nueva con `-InstallDependencies`, correr `pnpm.cmd run test:run` y `pnpm.cmd run build`; comparar las rutas y el estado antes/después de `-WhatIf`. Guardar las salidas y registrar cualquier fallo de `winget`, red, permisos o descubrimiento de skills. No usar credenciales reales para las pruebas del instalador; la autenticación interactiva de Codex se valida por separado.
