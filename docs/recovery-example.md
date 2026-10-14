# Recuperar una aplicación sin tocar la copia existente

Desde una carpeta nueva en otra ruta:

```powershell
git clone https://github.com/OWNER/APP.git .\app-recovered
cd .\app-recovered
pnpm.cmd install --frozen-lockfile
pnpm.cmd run test:run
pnpm.cmd run typecheck
pnpm.cmd run build
```

Reemplazá `OWNER/APP` por el repositorio de la aplicación. Esto recupera el estado publicado del remoto; los cambios locales aún no enviados no se pueden recuperar desde GitHub. El framework no copia archivos desde la carpeta de origen ni ejecuta comandos dentro de ella. Para el flujo visual de ADEL, revisar en una sesión con Browser las pantallas, foco, pistas e imágenes; los tests DOM por sí solos no prueban fidelidad visual. Los candidatos de arte requieren aprobación antes de integrarse.
