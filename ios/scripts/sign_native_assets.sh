#!/bin/sh
# Firma los frameworks de native assets de Flutter que la fase "Thin Binary"
# copia con rsync dentro de Frameworks/.
#
# Por qué existe: xcode_backend.dart sólo firma native assets cuando la
# plataforma es macOS (embedFlutterFrameworks -> codesign = platform ==
# TargetPlatform.macos ...). En iOS los copia sin firmar, así que llegan con
# firma adhoc y sin TeamIdentifier. installd los rechaza:
#   0xe8008014 (The executable contains an invalid signature.)
#
# Esta fase corre DESPUÉS de "Thin Binary" y ANTES del CodeSign final que hace
# Xcode sobre el .app, así que el sello del bundle queda consistente.

set -e

if [ "${CODE_SIGNING_REQUIRED}" = "NO" ] || [ -z "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
  echo "note: Firma no requerida; se omite la firma de native assets."
  exit 0
fi

FRAMEWORKS_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
NATIVE_ASSETS_DIR="${FLUTTER_APPLICATION_PATH:-${SOURCE_ROOT}/..}/${FLUTTER_BUILD_DIR:-build}/native_assets/ios"

if [ ! -d "${NATIVE_ASSETS_DIR}" ]; then
  echo "note: No hay native assets en ${NATIVE_ASSETS_DIR}."
  exit 0
fi

for asset in "${NATIVE_ASSETS_DIR}"/*.framework; do
  [ -d "${asset}" ] || continue
  name=$(basename "${asset}" .framework)
  embedded="${FRAMEWORKS_DIR}/${name}.framework"
  [ -d "${embedded}" ] || continue

  team=$(codesign -dvv "${embedded}" 2>&1 | sed -n 's/^TeamIdentifier=//p')
  if [ "${team}" = "${DEVELOPMENT_TEAM}" ] && [ -n "${team}" ]; then
    echo "note: ${name}.framework ya está firmado por ${team}."
    continue
  fi

  echo "note: Firmando ${name}.framework con ${EXPANDED_CODE_SIGN_IDENTITY}."
  codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${embedded}"
done
