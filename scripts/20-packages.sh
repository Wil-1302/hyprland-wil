#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACMAN_LIST="$REPO_DIR/packages/pacman.txt"
AUR_LIST="$REPO_DIR/packages/aur.txt"

echo "[INFO] Instalando paquetes (pacman.txt + aur.txt)"

# --- leer listas (ignorando comentarios y líneas vacías) ---
mapfile -t PKGS < <(grep -Ev '^\s*($|#)' "$PACMAN_LIST" 2>/dev/null || true)
mapfile -t AUR  < <(grep -Ev '^\s*($|#)' "$AUR_LIST" 2>/dev/null || true)

# --- pacman ---
if ((${#PKGS[@]})); then
  sudo pacman -Syu --needed --noconfirm "${PKGS[@]}"
else
  echo "[WARN] packages/pacman.txt vacío (o solo comentarios)."
fi

# --- AUR (requiere yay) ---
if ((${#AUR[@]})); then
  if ! command -v yay >/dev/null 2>&1; then
    echo "[INFO] yay no está instalado. Instalándolo..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  fi

  yay -S --needed --noconfirm "${AUR[@]}"
else
  echo "[INFO] packages/aur.txt vacío (o solo comentarios)."
fi
