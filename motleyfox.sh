#!/bin/bash
#### SETUP ####################################################################
set -o errexit
set -o errtrace
set -o nounset

# shellcheck disable=SC2154
trap '_es=${?};
    _lo=${LINENO};
    _co=${BASH_COMMAND};
    echo "${0}: line ${_lo}: \"${_co}\" exited with a status of ${_es}";
    exit ${_es}' ERR

ARGS=()
# https://en.wikipedia.org/wiki/ANSI_escape_code
E0="$(printf "\e[0m")"        # reset
E30="$(printf "\e[30m")"      # foreground: black
E33="$(printf "\e[33m")"      # foreground: yellow
E97="$(printf "\e[97m")"      # foreground: bright white
E107="$(printf "\e[107m")"    # background: bright white
I4='    '
I8='        '
PROFILES="${HOME}/Library/Application Support/Firefox/Profiles"
PROG="${0##*/}"
USAGE="\
Usage:  ${PROG} [NAME[:COLOR]..]
        ${PROG} -h

Description:
    Create discrete Firefox macOS applications to allow clean and complete
    online identity separation.

Options:
    -h      show this help message and exit

Arguments:
    NAME        For each NAME, ${PROG} will create a Firefox-Name application
                copy and a firefox-name profile. It is expected that NAME is a
                single Titlecase or UPPERCASE word. \"Help\" is an invalid NAME.
    NAME:COLOR  Optinally, an icon color (see icons/) maybe specified. Default
                Arguments: Home:navy Work:gray
"


#### FUNCTIONS ################################################################


add_launch_script() {
    local _app _name_lower _name_title _path_app _path_contents _path_macos
    local _path_profile _profiles
    _name_title="${1}"
    _name_lower="${2}"
    _profiles="${3}"
    _app="${_name_title}.app"
    _path_app="/Applications/${_app}"
    _path_contents="${_path_app}/Contents"
    _path_macos="/Applications/${_app}/Contents/MacOS"
    _path_profile="${_profiles}/${_name_lower}"
    echo "${I4}creating launcher script"
    {
        echo '#!/bin/sh'
        echo "exec ${_path_macos}/firefox \\"
        echo "${I4}-no-remote \\"
        echo "${I4}--profile \\"
        echo "${I4}'${_path_profile}' \\"
        echo "${I4}2>/dev/null &"
    } > "${_path_macos}/${_name_lower}"
    chmod 0755 "${_path_macos}/${_name_lower}"
    ln -sf "${_path_macos}/${_name_lower}" ~/bin/"${_name_lower}"
    echo "${I8}script name: ${_name_lower}"
}


create_profile() {
    local _app _label_title _name_lower _name_title _path_macos _path_profile
    local _profiles _status
    _name_title="${1}"
    _name_lower="${2}"
    _label_title="${3}"
    _profiles="${4}"
    _app="${_name_title}.app"
    _path_macos="/Applications/${_app}/Contents/MacOS"
    _path_profile="${_profiles}/${_name_lower}"
    print_header_2 'Creating Firefox profile'
    echo "${I4}profile_path: ${_path_profile/${HOME}/~}"
    # Return immediately if profile already exists
    if [[ -d "${_path_profile}" ]]
    then
        echo "${I8}(no-op: profile already exists)"
        return 0
    else
        printf '%s' "${I8}"
        _status=$("${_path_macos}/firefox-bin" -CreateProfile \
                    "${_label_title} ${_path_profile}")
        printf '%s' "${_status}"
    fi
}


clone_firefox_app() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    print_header_2 'Copying Firefox application bundle'
    echo "${I4}new application bundle name: ${_name_title}"
    pushd /Applications >/dev/null

    # Remove previous and copy App Bundle
    rm -rf "${_app}"
    cp -a 'Firefox.app' "${_app}/"
    # Verify code signature
    echo "${I4}verifying app bundle code signature"
    codesign --verify "${_app}"

    popd >/dev/null
}


print_header_1() {
    # Print 80 character wide black on white heading with time
    printf "${E30}${E107}# %-70s$(date '+%T') ${E0}\n" "${@}"
}


print_header_2() {
    # Print bright white heading
    printf "${E97}%s${E0}\n" "${@}"
}



print_help() {
    # Print help/usage
    echo "${USAGE}"
    exit
}


remove_app_signature() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null
    # Remove code signature
    echo "${I4}removing Mozilla Corporation code signature"
    codesign --remove-signature --deep "${_app}"
    # Remove com.apple.quarantine
    echo "${I4}removing quarantine"
    xattr -rd com.apple.quarantine "${_app}"
    popd >/dev/null
}


remove_misc() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null
    echo "${I4}removing updater"
    rm -rf "${_app}/Contents/MacOS/crashreporter.app"
    rm -f "${_app}/Contents/CodeResources"
    rm -f "${_app}/Contents/embedded.provisionprofile"
    popd >/dev/null
}


remove_updater() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null
    echo "${I4}removing updater"
    rm -rf "${_app}/Contents/Library"
    rm -rf "${_app}/Contents/MacOS/updater.app"
    rm -f "${_app}/Contents/Resources/updater.ini"
    rm -f "${_app}/Contents/Resources/update-settings.ini"
    popd >/dev/null
}


sign_app() {
    local _app _name_lower _name_title
    _name_title="${1}"
    _name_lower="${2}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null
    printf '%s' "${I4}"
    codesign --sign=- \
        --deep \
        --force \
        --identifier="${_name_lower}" \
        --strip-disallowed-xattrs \
        -vvv \
        "${_app}"
    popd >/dev/null
}


touch_app() {
    local _app _name_title _path_app _path_contents
    _name_title="${1}"
    _app="${_name_title}.app"
    _path_app="/Applications/${_app}"
    _path_contents="${_path_app}/Contents"
    # Ensure Finder sees changes
    #   https://gist.github.com/fabiofl/5873100#gistcomment-1240299
    touch "${_path_app}"
    touch "${_path_contents}/MacOS/firefox"
    touch "${_path_contents}/Resources/application.ini"
}


update_app_icon() {
    local _app _icon_color _icon_png _outputi _name_title _path_app
    _name_title="${1}"
    _icon_color="${2}"
    _app="${_name_title}.app"
    _path_app="/Applications/${_app}"
    _icon_png="icons/icons8-firefox-480-${_icon_color}.png"
    print_header_2 "Updating ${_name_title} application icon"
    if command -v fileicon >/dev/null
    then
        # Replace original icon
        _output=$(fileicon set "${_path_app}" "${_icon_png}")
        echo "${I4}${_output%%based on*}"
        echo "${I8}based on${_output##*based on}"
    else
        printf '%s' "${E33}${I4}fileicon is not installed. Unable to generate"
        echo " icons.${E0}"
        echo "${E33}${I8}(resolve with \`brew install fileicon\`)${E0}"
        return
    fi
}


update_app_info() {
    local _app _icon_color _icon_icns _icon_name _icon_png _name_lower
    local _name_title _path_app _path_contents
    local -i _icon_icns_exists _icon_name_exists
    _name_title="${1}"
    _name_lower="${2}"
    _icon_color="${3}"
    _app="${_name_title}.app"
    _path_app="/Applications/${_app}"
    _path_contents="${_path_app}/Contents"
    _icon_png="icons/icons8-firefox-480-${_icon_color}.png"
    _icon_icns="build/firefox-${_icon_color}.icns"
    _icon_icns_exists=0
    _icon_name="build/${name_lower}.icns"
    _icon_name_exists=0
    echo "${I4}updating Info.plist"
    echo "${I8}modifying CFBundleExecutable"
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${_name_lower}" \
        "${_path_contents}/Info.plist"
    echo "${I8}modifying CFBundleIdentifier"
    /usr/libexec/PlistBuddy -c \
        "Set :CFBundleIdentifier ${_name_lower}" \
        "${_path_contents}/Info.plist"
    echo "${I8}modifying CFBundleName"
    /usr/libexec/PlistBuddy -c \
        "Set :CFBundleName ${_name_title}" \
        "${_path_contents}/Info.plist"
    echo "${I8}deleting SMPrivilegedExecutables"
    /usr/libexec/PlistBuddy -c 'Delete :SMPrivilegedExecutables' \
        "${_path_contents}/Info.plist"
}


#### MAIN #####################################################################


#### Parse options
while [[ -n "${1:-}" ]]; do
    case "${1}" in
        -h | -help | --help | Help | help )
            shift
            print_help
            ;;
        -- )
            shift
            ;;
        * )
            ARGS+=("${1}")
            shift
            ;;
    esac
done
(( ${#ARGS[@]} > 0 )) || ARGS=(Home:navy Work:gray)

for name_color in "${ARGS[@]}"
do
    label_title=${name_color%%:*}
    icon_color=${name_color##*:}
    [[ "${label_title}" != "${icon_color}" ]] || icon_color='orange'
    label_lower="$(echo "${label_title}" | tr '[:upper:]' '[:lower:]')"
    name_title="Firefox-${label_title}"
    name_lower="firefox-${label_lower}"
    print_header_1 "${name_title}"
    clone_firefox_app "${name_title}"
    print_header_2 "Updating ${name_title} application bundle"
    remove_misc "${name_title}"
    remove_updater "${name_title}"
    remove_app_signature "${name_title}"
    update_app_info "${name_title}" "${name_lower}" "${icon_color}"
    add_launch_script "${name_title}" "${name_lower}" "${PROFILES}"
    touch_app "${name_title}"
    sign_app "${name_title}" "${name_lower}"
    update_app_icon "${name_title}" "${icon_color}"
    touch_app "${name_title}"
    create_profile "${name_title}" "${name_lower}" "${label_title}" \
        "${PROFILES}"
    echo
done
