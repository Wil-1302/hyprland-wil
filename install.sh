#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info(){ echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
warn(){ echo -e "\n\033[1;33m[WARN]\033[0m $*"; }
err(){  echo -e "\n\033[1;31m[ERR ]\033[0m $*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

info "Hyprland-Wil Installer"

# ---- 0) sanity ----
if [[ $EUID -eq 0 ]]; then
  err "No ejecutes como root. Úsalo como tu usuario normal."
  exit 1
fi

if [[ ! -f "$REPO_DIR/packages/pacman.txt" ]]; then
  err "No encuentro packages/pacman.txt (¿estás en el repo correcto?)."
  exit 1
fi

# ---- 1) base tools ----
info "Actualizando sistema e instalando herramientas base..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# ---- 2) yay ----
if ! need_cmd yay; then
  info "Instalando yay (AUR helper)..."
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
else
  info "yay ya está instalado."
fi

# ---- 3) GPU detection (modo C) ----
info "Detectando GPU..."
GPU="unknown"
if lspci | grep -qi "NVIDIA"; then
  GPU="nvidia"
elif lspci | grep -Eqi "AMD|ATI"; then
  GPU="amd"
elif lspci | grep -Eqi "Intel"; then
  GPU="intel"
fi
info "GPU detectada: $GPU"

# ---- 4) packages (pacman) ----
info "Instalando paquetes oficiales (pacman.txt)..."
# Filtra líneas vacías/comentarios por si algún día editas el archivo
PAC_PKGS="$(grep -vE '^\s*($|#)' "$REPO_DIR/packages/pacman.txt" || true)"
if [[ -n "$PAC_PKGS" ]]; then
  sudo pacman -S --needed --noconfirm $PAC_PKGS
else
  warn "packages/pacman.txt está vacío."
fi

# ---- 5) packages (AUR) ----
if [[ -f "$REPO_DIR/packages/aur.txt" ]]; then
  info "Instalando paquetes AUR (aur.txt)..."
  AUR_PKGS="$(grep -vE '^\s*($|#)' "$REPO_DIR/packages/aur.txt" || true)"
  if [[ -n "$AUR_PKGS" ]]; then
    yay -S --needed --noconfirm $AUR_PKGS
  else
    warn "packages/aur.txt está vacío."
  fi
else
  warn "No existe packages/aur.txt, salto AUR."
fi

# ---- 6) GPU extras safe ----
# No forzamos cosas raras: solo avisos y mínimos.
case "$GPU" in
  nvidia)
    info "Perfil NVIDIA: asegurando paquetes típicos (seguro)..."
    sudo pacman -S --needed --noconfirm nvidia-utils egl-wayland ;;
  amd)
    info "Perfil AMD: mesa/vulkan (normalmente ya viene por deps)..."
    sudo pacman -S --needed --noconfirm vulkan-radeon ;;
  intel)
    info "Perfil Intel: vulkan-intel (normalmente ya viene por deps)..."
    sudo pacman -S --needed --noconfirm vulkan-intel ;;
  *)
    warn "No pude detectar GPU. No aplico perfil."
    ;;
esac

# ---- 7) dotfiles ----
info "Aplicando dotfiles (Hyprland/Waybar/etc)..."
mkdir -p ~/.config ~/.local
cp -rT "$REPO_DIR/dotfiles/.config" ~/.config 2>/dev/null || true
cp -rT "$REPO_DIR/dotfiles/.local"  ~/.local  2>/dev/null || true

# ---- 8) SDDM config + theme ----
info "Aplicando SDDM (si existe en el repo)..."
if [[ -d "$REPO_DIR/system/etc/sddm.conf.d" ]]; then
  sudo mkdir -p /etc/sddm.conf.d
  sudo cp -rT "$REPO_DIR/system/etc/sddm.conf.d" /etc/sddm.conf.d
fi
if [[ -f "$REPO_DIR/system/etc/sddm.conf" ]]; then
  sudo cp "$REPO_DIR/system/etc/sddm.conf" /etc/sddm.conf
fi
if [[ -d "$REPO_DIR/system/maldives" ]]; then
  sudo mkdir -p /usr/share/sddm/themes
  sudo cp -rT "$REPO_DIR/system/maldives" /usr/share/sddm/themes/maldives
fi

# ---- 9) GRUB config + theme ----
info "Aplicando GRUB (si existe en el repo)..."
if [[ -f "$REPO_DIR/system/etc/default/grub" ]]; then
  sudo cp "$REPO_DIR/system/etc/default/grub" /etc/default/grub
fi
if [[ -d "$REPO_DIR/bootloader/grub/FedoraLitemint" ]]; then
  sudo mkdir -p /usr/share/grub/themes
  sudo cp -rT "$REPO_DIR/bootloader/grub/FedoraLitemint" /usr/share/grub/themes/FedoraLitemint
fi

warn "GRUB: Si reinstalas en otra máquina/partición, quizá necesites correr:"
warn "  sudo grub-install ..."
warn "  sudo grub-mkconfig -o /boot/grub/grub.cfg"

# ---- 10) services (mínimos) ----
info "Habilitando servicios básicos (NetworkManager + seatd)..."
sudo systemctl enable --now NetworkManager 2>/dev/null || true
sudo systemctl enable --now seatd 2>/dev/null || true

info "Instalación terminada ✅"
info "Reinicia con: reboot"
