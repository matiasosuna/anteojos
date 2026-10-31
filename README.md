# Anteojos

App de iPhone para los Ray-Ban Meta: sacás una foto con los anteojos, Gemini dice qué tenés delante y lo escuchás por los parlantes de los anteojos.

- `app/`: app iOS (base: ejemplo CameraAccess del SDK de Meta, licencia en `app/LICENSE-meta`).
- `worker/`: Worker de Cloudflare `anteojos-vision` que guarda la clave de Gemini.

## Correr en el iPhone
1. Instalar Xcode 26.4+ (App Store).
2. `sh app/scripts/secretos.sh` (arma el token desde la bóveda).
3. Abrir `app/CameraAccess.xcodeproj`, elegir el iPhone y ▶️.
4. En la app Meta AI: Developer Mode activado. En Anteojos: Connect → Start Session → Preview → foto.

Claves: bóveda, proyecto `anteojos` (APP_TOKEN, GEMINI_API_KEY).
