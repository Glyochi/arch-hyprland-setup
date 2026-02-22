#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

CURRENT_DIR="$(pwd)"

SOURCE_ROOT_DIR="${CURRENT_DIR}"
TARGET_ROOT_DIR="${HOME}/.config/hypr"

# Check if hyprland.conf has already exists. If not then symbolic link it.
source_path="${SOURCE_ROOT_DIR}/hyprland.conf"
target_path="${TARGET_ROOT_DIR}/hyprland.conf"	
if [[ -f "${target_path}" ]]; then
	prompt_message="Hyprland config at '${target_path}' already exists. Do you want to replace it?\n" 
	print_warning "$prompt_message"
	tmp_array=("No" "Yes")

	MENU ${tmp_array[@]}
	response="${RETURN_0}"

	clear_previous_string "$prompt_message"

	if [[ "$response" = "No" ]]; then
		print_warning "Configuring hyprland.conf aborted.\n"
		exit
	fi
fi

ln -fs "${source_path}" "${target_path}"
