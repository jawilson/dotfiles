link_powershell_profile() {
    local powershell_cmd="$1"
    local profile_source="$2"
    local helper_dir
    local linker_script

    # Resolve the helper directory from this sourced file, not the caller.
    if command -v dirname &> /dev/null; then
        helper_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    else
        helper_dir=$( cd -- "${BASH_SOURCE[0]%/*}" &> /dev/null && pwd )
    fi
    linker_script="${helper_dir}/link_powershell_profile.ps1"

    if ! command -v "$powershell_cmd" &> /dev/null; then
        return
    fi

    if command -v cygpath &> /dev/null; then
        profile_source=$(cygpath -w "$profile_source")
        linker_script=$(cygpath -w "$linker_script")
    fi

    "$powershell_cmd" -NoProfile -NonInteractive -ExecutionPolicy Bypass \
        -File "$linker_script" -ProfileSource "$profile_source"
}
