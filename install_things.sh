#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

CURRENT_DIR="$(pwd)"

SOURCE_ROOT_DIR="${CURRENT_DIR}"
TARGET_CONFIG_DIR="${HOME}/.config"

configure_directory_symlink() {
	local source_path="$1"
	local target_path="$2"
	local config_name="$3"

	if [[ -e "${target_path}" || -L "${target_path}" ]]; then
		prompt_message="${config_name} at '${target_path}' already exists. Do you want to replace it?\n"
		print_warning "$prompt_message"
		tmp_array=("No" "Yes")

		MENU ${tmp_array[@]}
		response="${RETURN_0}"

		clear_previous_string "$prompt_message"

		if [[ "$response" = "No" ]]; then
			print_warning "Configuring ${config_name} aborted.\n"
			exit
		fi

		rm -rf "${target_path}"
	fi

	ln -s "${source_path}" "${target_path}"
}

mkdir -p "${TARGET_CONFIG_DIR}"

configure_directory_symlink "${SOURCE_ROOT_DIR}/hypr" "${TARGET_CONFIG_DIR}/hypr" "Hypr config folder"
configure_directory_symlink "${SOURCE_ROOT_DIR}/waybar" "${TARGET_CONFIG_DIR}/waybar" "Waybar config folder"
configure_directory_symlink "${SOURCE_ROOT_DIR}/swayosd" "${TARGET_CONFIG_DIR}/swayosd" "SwayOSD config folder"
configure_directory_symlink "${SOURCE_ROOT_DIR}/dunst" "${TARGET_CONFIG_DIR}/dunst" "Dunst config folder"
configure_directory_symlink "${SOURCE_ROOT_DIR}/kitty" "${TARGET_CONFIG_DIR}/kitty" "Kitty config folder"
configure_directory_symlink "${SOURCE_ROOT_DIR}/images" "${TARGET_CONFIG_DIR}/images" "Waybar config folder"
