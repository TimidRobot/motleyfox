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
Usage:  ${PROG} [NAME..]
        ${PROG} -h

Description:
    Create discrete Firefox macOS applications to allow clean and complete
    online identity separation.

Options:
    -h      show this help message and exit

Arguments:
    NAME    For each NAME, ${PROG} will create a Firefox-Name application copy
            iand a firefox-name profile. It is expected that NAME is a single
            Titlecase or UPPERCASE word. \"Help\" is an invalid NAME.
"
PROFILES="${HOME}/Library/Application Support/Firefox/Profiles"


#### FUNCTIONS ################################################################


help_print() {
    # Print help/usage, then exit (incorrect usage should exit 2)
    local _es=${1:-0}
    echo "${USAGE}"
    exit ${_es}
}


clone_firefox_app() {
    local _name_title="${1}"
    local _app="${_name_title}.app"
    echo '# Copying Firefox application'
    echo "#   new application name: ${_name_title}"
    pushd /Applications >/dev/null
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
    popd >/dev/null
}


update_app_info() {
    local _name_title="${1}"
    local _name_lower="${2}"
    local _app="${_name_title}.app"
    local _path_app="/Applications/${_app}"
    local _path_contents="${_path_app}/Contents"
    echo '# Updating application bundle'
    ## Update Info.plist
    #sed \
    #    -e"s/>firefox</>${_name_lower}</" \
    #    -e"s/>Firefox/>${_name_title}/" \
    #    -e"s/>org.mozilla.firefox</>org.mozilla.${_name_lower}</" \
    #    -i.bak \
    #    "${_path_contents}/Info.plist"
    #rm -f "${_path_contents}/Info.plist.bak"
    # Replace Icon
    if [[ -f "icons/${name_lower}.icns" ]]
    then
        cp "icons/${name_lower}.icns" \
            "${_path_contents}/Resources/firefox.icns"
    else
        echo "#   file does not exist: icons/${name_lower}.icns"
        echo '#     skipping application icon update'
    fi
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
    echo '# Creating launcher script'
    echo "#   script name: ${_name_lower}"
    #pushd "${_path_macos}" >/dev/null
    # Create launcher script
    {
        echo '#!/bin/sh'
        echo "${_path_macos}/firefox \\"
        echo "    -no-remote \\"
        echo "    --profile \\"
        echo "    '${_path_profile}' \\"
        echo "    2>/dev/null &"
    } > ${_name_lower}
    chmod 0755 ${_name_lower}
    ## Move launcher script into place
    #mv firefox firefox-orig
    #mv ${name_lower} firefox
    #popd >/dev/null
}


create_profile() {
    local _name_title="${1}"
    local _name_lower="${2}"
    local _label_title="${3}"
    local _profiles="${4}"
    local _app="${_name_title}.app"
    local _path_macos="/Applications/${_app}/Contents/MacOS"
    local _path_profile="${_profiles}/${_name_lower}"
    echo '# Creating Firefox profile'
    echo "#   profile_name: ${_name_lower}"
    echo '#     (see launcher script for full profile path)'
    # Return immediately if profile already exists
    if [[ -d "${_path_profile}" ]]
    then
        echo '#     no-op: profile already exists'
        return 0
    else
        printf '#   '
        local _status=$("${_path_macos}/firefox-bin" -CreateProfile \
                            "${_label_title} ${_path_profile}")
        printf "${_status}"
    fi
}


#### MAIN #####################################################################


#### Parse options
while [[ -n "${1:-}" ]]
do
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
(( ${#ARGS[@]} > 1 )) || ARGS=(Home Work)
for label_title in "${ARGS[@]}"
do
    label_lower="$(echo "${label_title}" | tr '[:upper:]' '[:lower:]')"
    name_title="Firefox-${label_title}"
    name_lower="firefox-${label_lower}"
    echo "### ${label_title}"
    clone_firefox_app "${name_title}"
    update_app_info "${name_title}" "${name_lower}"
    add_launch_script "${name_title}" "${name_lower}" "${PROFILES}"
    create_profile "${name_title}" "${name_lower}" "${label_title}" \
        "${PROFILES}"
    echo
done
