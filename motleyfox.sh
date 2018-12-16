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
    local _icon_color="${3}"
    local _app="${_name_title}.app"
    local _path_app="/Applications/${_app}"
    local _path_contents="${_path_app}/Contents"
    local _icon_png="icons/icons8-firefox-480-${_icon_color}.png"
    local _icon_icns="build/firefox-${_icon_color}.icns"
    local _icon_icns_exists=0
    local _icon_name="build/${name_lower}.icns"
    local _icon_name_exists=0
    echo '# Updating application bundle'
    ## Update Info.plist
    echo '#   updating Info.plist'
    sed \
        -e"s/>firefox</>${_name_lower}</" \
        -e"s/>Firefox/>${_name_title}/" \
        -e"s/>org.mozilla.firefox</>org.mozilla.${_name_lower}</" \
        -i.bak \
        "${_path_contents}/Info.plist"
    rm -f "${_path_contents}/Info.plist.bak"
    # Generate Icon
    if [[ -f "${_icon_name}" ]]
    then
        echo "#   using existing: ${_icon_name}"
        local _icon_name_exists=1
    elif [[ -f "${_icon_png}" ]]
    then
        echo "#   icon color: ${_icon_color}"
        if [[ -f "${_icon_icns}" ]]
        then
            local _icon_icns_exists=1
        else
            if which -s makeicns
            then
                echo "#   generating: ${_icon_icns}"
                echo "#     from: ${_icon_png}"
                makeicns -in "${_icon_png}" -out ${_icon_icns}
                local _icon_icns_exists=1
            else
                echo '#   makeicns is not installed. Unable to generate icons.'
                echo '#     (resovle with `brew install icns`)'
            fi
        fi
        if (( _icon_icns_exists == 1 ))
        then
            echo "#   creating symlinking: ${_icon_name}"
            echo "#     source: ${_icon_icns}"
            pushd build >/dev/null
            ln -s "${_icon_icns##*/}" "${_icon_name##*/}"
            local _icon_name_exists=1
            popd >/dev/null
        fi
    else
        echo "#   icon source file missing: ${_icon_png}"
        echo '#     unable to generate icns file and symlink to it'
    fi
    # Replace Icon
    if (( _icon_name_exists == 1 ))
    then
        echo '#   copying application icon into place'
        cp "build/${name_lower}.icns" \
            "${_path_contents}/Resources/firefox.icns"
    else
        echo "#   file/symlink does not exist: ${_icon_name}"
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
    local _path_app="/Applications/${_app}"
    local _path_contents="${_path_app}/Contents"
    local _path_macos="/Applications/${_app}/Contents/MacOS"
    local _path_profile="${_profiles}/${_name_lower}"
    echo '# Creating launcher script'
    echo '#   located in app bundle Contents'
    {
        echo '#!/bin/sh'
        echo "${_path_macos}/firefox \\"
        echo "    -no-remote \\"
        echo "    --profile \\"
        echo "    '${_path_profile}'"
        #echo "    2>/dev/null &"
    } > ${_path_contents}/${_name_lower}
    chmod 0755 ${_path_contents}/${_name_lower}
    echo "#   script name: ${_name_lower}"
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
    echo "#   profile_path: ${_path_profile/${HOME}/~}"
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
(( ${#ARGS[@]} > 0 )) || ARGS=(Home:navy Work:gray)
mkdir -p build
for name_color in "${ARGS[@]}"
do
    label_title=${name_color%%:*}
    icon_color=${name_color##*:}
    [[ "${label_title}" != "${icon_color}" ]] || icon_color='orange'
    label_lower="$(echo "${label_title}" | tr '[:upper:]' '[:lower:]')"
    name_title="Firefox-${label_title}"
    name_lower="firefox-${label_lower}"
    echo "### ${label_title}"
    create_profile "${name_title}" "${name_lower}" "${label_title}" \
        "${PROFILES}"
    clone_firefox_app "${name_title}"
    update_app_info "${name_title}" "${name_lower}" "${icon_color}"
    add_launch_script "${name_title}" "${name_lower}" "${PROFILES}"
    echo
done
