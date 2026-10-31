#!/bin/sh
# Arma CameraAccess/Anteojos/Secretos.swift con el token de la bóveda (no se sube a git).
# Correr una vez antes de compilar:  sh scripts/secretos.sh
set -e
cd "$(dirname "$0")/.."
boveda correr -p anteojos -k APP_TOKEN -- sh -c '
cat > CameraAccess/Anteojos/Secretos.swift <<EOF
// Generado por scripts/secretos.sh — no editar ni subir a git.
enum Secretos {
  static let appToken = "$APP_TOKEN"
}
EOF'
echo "Listo: CameraAccess/Anteojos/Secretos.swift"
