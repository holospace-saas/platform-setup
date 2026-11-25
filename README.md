# platform-setup

Instalador de todos los proyectos de Holospace y Hologrowth en una Mac, con un solo comando.

## Uso

Abrir la Terminal en la carpeta donde van a vivir los proyectos (por ejemplo `~/Projects` o una carpeta de un disco externo) y correr:

```bash
curl -fsSL https://raw.githubusercontent.com/holospace-saas/platform-setup/main/setup-mac.sh | bash
```

Es siempre el mismo comando: para una Mac nueva, para una que ya tiene los proyectos y para retomar una instalación que quedó a medias.

## Qué hace

1. Instala Homebrew si no está (puede pedir la contraseña de la Mac).
2. Instala `git` y la CLI de GitHub (`gh`) si no están, y pide iniciar sesión en GitHub (se abre el navegador).
3. Clona o actualiza el repo privado `platform-workspace` en `business/platform/platform-workspace`.
4. Corre su `setup-mac.sh`, que instala el resto de las herramientas, clona y verifica todos los repos, instala Claude y genera el workspace de VS Code. Al final muestra el resultado, por ejemplo **"30 de 30 repos bajados y verificados"**, y dice **Listo** o **INCOMPLETO** con lo que falta. Si queda incompleto, se vuelve a correr el mismo comando.

El detalle completo está en el README de `platform-workspace`.

## Acceso

Este repo es público y no contiene nada privado: solo el instalador. Los proyectos son privados y solo se bajan después de iniciar sesión en GitHub con una cuenta que tenga acceso a ellos; con cualquier otra cuenta el instalador se detiene en el paso 2.

## Revisar antes de correr

Como todo instalador que se ejecuta con `curl | bash`, se puede leer antes: [`setup-mac.sh`](setup-mac.sh). Todo el script corre dentro de `main()`, que se llama en la última línea, así que una descarga cortada nunca se ejecuta a medias. Cada cambio pasa por ShellCheck en GitHub Actions.
