#!/bin/bash
#### SETUP ####################################################################
set -o errexit
set -o errtrace
set -o nounset

trap '_es=${?};
    _lo=${LINENO};
    _co=${BASH_COMMAND};
    echo "${0}: line ${_lo}: \"${_co}\" exited with a status of ${_es}";
    exit ${_es}' ERR

ARGS=()
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
    NAME:COLOR  Optinally, an icon color (see icons/) maybe specified.
"
PROFILES="${HOME}/Library/Application Support/Firefox/Profiles"


#### FUNCTIONS ################################################################


help_print() {
    # Print help/usage
    echo "${USAGE}"
    exit
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
    echo '# Creating Firefox profile'
    echo "#   profile_path: ${_path_profile/${HOME}/~}"
    # Return immediately if profile already exists
    if [[ -d "${_path_profile}" ]]; then
        echo '#     (no-op: profile already exists)'
        return 0
    else
        printf '#   '
        _status=$("${_path_macos}/firefox-bin" -CreateProfile \
                    "${_label_title} ${_path_profile}")
        printf '%s' "${_status}"
    fi
}


clone_firefox_app() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    echo '# Copying Firefox application bundle'
    echo "#   new application bundle name: ${_name_title}"
    pushd /Applications >/dev/null

    # Remove previously created App Bundle
    if [[ -d "${_app}" ]]; then
        rm -rf "${_app}"
    fi
    # Remove previous and copy App Bundle
    rm -rf "${_app}"
    cp -a 'Firefox.app' "${_app}/"
    # Verify code signature
    echo '#   verifying app bundle code signature'
    codesign -v "${_app}"

    popd >/dev/null
}


remove_app_signature() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null

    # Remove code signature
    echo '#   removing Mozilla Corporatio code signature'
    codesign --remove-signature "${_app}"
    # Remove com.apple.quarantine
    echo '#   removing quarantine'
    xattr -rd com.apple.quarantine "${_app}"
    #xattr -r -d com.apple.macl "${_app}"

    popd >/dev/null
}


remove_updater() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null

    # Remove Updater
    echo '#   removing updater'
    rm -rf "${_app}/Contents/Library"
    rm -rf "${_app}/Contents/MacOS/updater.app"
    rm -f "${_app}/Contents/Resources/updater.ini"
    rm -f "${_app}/Contents/Resources/update-settings.ini"

    popd >/dev/null
}


update_app_icon() {
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
    # Generate Icon
    if [[ -f "${_icon_name}" ]]; then
        echo "#   using existing icon: ${_icon_name}"
        _icon_name_exists=1
    elif [[ -f "${_icon_png}" ]]; then
        echo "#   icon color: ${_icon_color}"
        if [[ -f "${_icon_icns}" ]]; then
            _icon_icns_exists=1
        else
            if which -s makeicns; then
                echo "#   generating: ${_icon_icns}"
                echo "#     from: ${_icon_png}"
                makeicns -in "${_icon_png}" -out "${_icon_icns}"
                _icon_icns_exists=1
            else
                echo '#   makeicns is not installed. Unable to generate icons.'
                echo '#     (resolve with `brew install makeicns`)'
            fi
        fi
        if (( _icon_icns_exists == 1 )); then
            echo "#   creating symlinking: ${_icon_name}"
            echo "#     source: ${_icon_icns}"
            pushd build >/dev/null
            ln -s "${_icon_icns##*/}" "${_icon_name##*/}"
            _icon_name_exists=1
            popd >/dev/null
        fi
    else
        echo "#   icon source file missing: ${_icon_png}"
        echo '#     unable to generate icns file and symlink to it'
    fi
    # Replace Icon
    if (( _icon_name_exists == 1 )); then
        echo '#   copying application icon into place'
        cp "build/${name_lower}.icns" \
            "${_path_contents}/Resources/firefox.icns"
    else
        echo "#   file/symlink does not exist: ${_icon_name}"
        echo '#     skipping application icon update'
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
    # Update Info.plist
    echo '#   updating Info.plist'
        # remove from sed, below, as it doesn't work
        # (app in top menu is still named Firefox)
        #-e"s#>Firefox#>${_name_title}#" \
    sed \
        -e"s#>firefox<#>${_name_lower}<#" \
        -e"s#>org.mozilla.firefox<#>org.mozilla.${_name_lower}<#" \
        -i.bak \
        "${_path_contents}/Info.plist"
    rm -f "${_path_contents}/Info.plist.bak"
    # Disabled as rename doesn't work (app in top menu is still named Firefox)
    ## Update application.ini
    #echo '#   updating application.ini'
    #sed \
    #    -e"s#=Firefox#=${_name_title}#" \
    #    -e"s#=firefox#=${_name_lower}#" \
    #    -i.bak \
    #    "${_path_contents}/Resources/application.ini"
    #rm -f "${_path_contents}/Resources/application.ini.bak"
}


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
    echo '#   creating launcher script'
    {
        echo '#!/bin/sh'
        echo "${_path_macos}/firefox \\"
        echo "    -no-remote \\"
        echo "    --profile \\"
        echo "    '${_path_profile}'"
        #echo "    2>/dev/null &"
    } > "${_path_macos}/${_name_lower}"
    chmod 0755 "${_path_macos}/${_name_lower}"
    echo "#     script name: ${_name_lower}"
}


pseudo_sign_binary() {
    local _app _name_title
    _name_title="${1}"
    _app="${_name_title}.app"
    pushd /Applications >/dev/null

    echo '#   pseduo-signing firefox binary'
    ldid -S "${_app}/Contents/MacOS/firefox"

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
    touch "${_path_contents}/Info.plist"
    touch "${_path_contents}/Resources/application.ini"
}


#### MAIN #####################################################################


#### Parse options
while [[ -n "${1:-}" ]]; do
    case "${1}" in
        -h | -help | --help | Help | help )
            shift
            help_print
            ;;
        #-n | --noop )
        #    shift
        #    opt_noop='--noop'
        #    ;;
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
mkdir -p build
for name_color in "${ARGS[@]}"; do
    label_title=${name_color%%:*}
    icon_color=${name_color##*:}
    [[ "${label_title}" != "${icon_color}" ]] || icon_color='orange'
    label_lower="$(echo "${label_title}" | tr '[:upper:]' '[:lower:]')"
    name_title="Firefox-${label_title}"
    name_lower="firefox-${label_lower}"
    echo "### ${label_title}"
    clone_firefox_app "${name_title}"
    echo "# Updating ${name_title} application bundle"
    remove_updater "${name_title}"
    remove_app_signature "${name_title}"
    update_app_icon "${name_title}" "${name_lower}" "${icon_color}"
    update_app_info "${name_title}" "${name_lower}" "${icon_color}"
    add_launch_script "${name_title}" "${name_lower}" "${PROFILES}"
    pseudo_sign_binary "${name_title}"
    touch_app "${name_title}"
    create_profile "${name_title}" "${name_lower}" "${label_title}" \
        "${PROFILES}"
    echo
done
