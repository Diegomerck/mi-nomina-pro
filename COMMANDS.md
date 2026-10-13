# Guía de Comandos Frecuentes: Mi Nómina Pro

Este documento contiene los comandos esenciales y el flujo de trabajo recomendado para desarrollo local, pruebas y publicación a producción.

---

## 1. Desarrollo Local y Vista Previa (Preview)

Para iniciar la aplicación en tu navegador con recarga rápida (**Hot Reload**):

```bash
flutter run -d chrome
```

### Controles en la terminal mientras corre:
| Tecla | Acción |
| :--- | :--- |
| `r` | **Hot Reload**: Actualiza los cambios en la UI de inmediato sin perder el estado actual. |
| `R` | **Hot Restart**: Reinicia la aplicación por completo (útil si cambiaste variables iniciales o el `initState`). |
| `q` | **Salir**: Detiene el servidor de desarrollo y cierra la sesión. |

---

## 2. Flujo de Publicación ("Publicar nueva versión")

Siempre que vayas a publicar una nueva versión en producción, el proceso consta de dos partes: **respaldo en GitHub** y **despliegue en Firebase Hosting**.

### Paso 1: Respaldo en GitHub
```bash
git add .
git commit -m "feat/fix: descripción del cambio"
git push origin master
```

### Paso 2: Compilación y Despliegue en Vivo
```bash
flutter build web
firebase deploy --only hosting
```

> **URL de Producción**: [https://nomina-televisa-v2.web.app](https://nomina-televisa-v2.web.app)

---

## 3. Comprobaciones y Calidad de Código

Antes de compilar o cuando quieras verificar que no haya errores de sintaxis o tipo:

```bash
flutter analyze
```

Si en algún momento el caché de Flutter genera inconsistencias o problemas extraños:
```bash
flutter clean
flutter pub get
```

---

## 4. Gestión de Cuenta en Firebase CLI

Si necesitas cambiar de cuenta o reautenticarte:

- **Cerrar sesión actual**:
  ```bash
  firebase logout
  ```

- **Iniciar sesión**:
  ```bash
  firebase login
  ```

- **Ver usuario activo**:
  ```bash
  firebase login:list
  ```

---

## 5. Cargar Rutas de Terminal (si no se encuentra flutter o firebase)

Si abres una terminal nueva y te indica `command not found: flutter` o `command not found: firebase`:

```bash
source ~/.zprofile
```
