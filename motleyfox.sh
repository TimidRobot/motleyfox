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

prog="${0##*/}"
usage="\
Usage:  ${prog}
        ${prog} -h

MotliFox -  Create discrete Firefox applications to allow clean and complete
            online identity separation.

Options:
    -h      show this help message and exit
"
profiles="${HOME}/Library/Application Support/Firefox/Profiles"


#### FUNCTIONS ################################################################


help_print() {
    # Print help/usage, then exit (incorrect usage should exit 2)
    local _es=${1:-0}
    echo "${usage}"
    exit ${_es}
}


clone_firefox_app() {
    local _name_title="${1}"
    local _app="${_name_title}.app"
    cd /Applications
    # Remove previously created App Bundle
    if [[ -d "${_app}" ]]
    then
        rm -rf "${_app}"
    fi
    # Copy App Bundle
    cp -a 'Firefox.app' "${_app}/"
    # Remove Updater
    rm -rf "${_app}/Contents/Library"
    rm -f "${_app}/Contents/Resources/update-settings.ini"
    # Return to previous directory
    cd "${OLDPWD}"
}


update_app_info() {
    local _name_title="${1}"
    local _name_lower="${2}"
    local _app="${_name_title}.app"
    local _path_app="/Applications/${_app}"
    local _path_contents="${_path_app}/Contents"
#    # Update Info.plist
#    sed \
#        -e"s/>firefox</>${_name_lower}</" \
#        -e"s/>Firefox/>${_name_title}/" \
#        -e"s/>org.mozilla.firefox</>org.mozilla.${_name_lower}</" \
#        -i.bak \
#        "${_path_contents}/Info.plist"
#    rm -f "${_path_contents}/Info.plist.bak"
    # Replace Icon
    cp "icons/${name_lower}.icns" \
        "${_path_contents}/Resources/firefox.icns"
    # Ensure Finder sees changes
    #   https://gist.github.com/fabiofl/5873100#gistcomment-1240299
    touch "${_path_app}"
    touch "${_path_contents}/Info.plist"
}


add_launch_script() {
    local _name_title="${1}"
    local _name_lower="${2}"
    local _profiles="${3}"
    local _app="${_name_title}.app"
    local _path_macos="/Applications/${_app}/Contents/MacOS"
    local _path_profile="${_profiles}/${_name_lower}"
#    cd "${_path_macos}"
    # Create launcher script
    {
        echo '#!/bin/sh'
        echo "${_path_macos}/firefox \\"
        echo "    -no-remote \\"
        echo "    --profile \\"
        echo "    \"${_path_profile}\" \\"
        echo "    2>/dev/null &"
    } > ${_name_lower}
    chmod 0755 ${_name_lower}
    # Move launcher script into place
#    mv firefox firefox-orig
#    mv ${name_lower} firefox
#    # Return to previous directory
#    cd "${OLDPWD}"
}


create_profile() {
    local _name_title="${1}"
    local _name_lower="${2}"
    local _label_title="${3}"
    local _profiles="${4}"
    local _app="${_name_title}.app"
    local _path_macos="/Applications/${_app}/Contents/MacOS"
    local _path_profile="${_profiles}/${_name_lower}"
    # Return immediately if profile already exists
    if [[ -d "${_path_profile}" ]]
    then
        return 0
    else
        "${_path_macos}/firefox-bin" -CreateProfile \
            "${_label_title} ${_path_profile}"
    fi
}


#### MAIN #####################################################################


#### Parse options
while [[ -n "${1:-}" ]]
do
    case "${1}" in
        -h | -help | --help )
            help_print
            shift
            ;;
        * )
            help_print
            ;;
    esac
done

for label_title in Work Home
do
    label_lower="$(echo "${label_title}" | tr '[:upper:]' '[:lower:]')"
    name_title="Firefox-${label_title}"
    name_lower="firefox-${label_lower}"
    echo "${label_title}"
    clone_firefox_app "${name_title}"
    update_app_info "${name_title}" "${name_lower}"
    add_launch_script "${name_title}" "${name_lower}" "${profiles}"
    create_profile "${name_title}" "${name_lower}" "${label_title}" \
        "${profiles}"
    echo
done
