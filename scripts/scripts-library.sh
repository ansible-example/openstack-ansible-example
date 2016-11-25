#!/usr/bin/env bash

## Vars ----------------------------------------------------------------------
LINE='----------------------------------------------------------------------'
MAX_RETRIES=${MAX_RETRIES:-5}
ANSIBLE_PARAMETERS=${ANSIBLE_PARAMETERS:--e gather_facts=False}
STARTTIME="${STARTTIME:-$(date +%s)}"
PIP_INSTALL_OPTIONS=${PIP_INSTALL_OPTIONS:-'pip==9.0.0 setuptools==28.7.1 wheel==0.29.0 '}
COMMAND_LOGS=${COMMAND_LOGS:-"/openstack/log/ansible_cmd_logs"}

# The default SSHD configuration has MaxSessions = 10. If a deployer changes
#  their SSHD config, then the ANSIBLE_FORKS may be set to a higher number. We
#  set the value to 10 or the number of CPU's, whichever is less. This is to
#  balance between performance gains from the higher number, and CPU
#  consumption. If ANSIBLE_FORKS is already set to a value, then we leave it
#  alone.
#  ref: https://bugs.launchpad.net/openstack-ansible/+bug/1479812
if [ -z "${ANSIBLE_FORKS:-}" ]; then
    CPU_NUM=$(grep -c ^processor /proc/cpuinfo)
    if [ ${CPU_NUM} -lt "10" ]; then
        ANSIBLE_FORKS=${CPU_NUM}
    else
        ANSIBLE_FORKS=10
    fi
fi

## Functions -----------------------------------------------------------------
function print_info {
    PROC_NAME="- [ $@ ] -"
    printf "\n%s%s\n" "$PROC_NAME" "${LINE:${#PROC_NAME}}"
}

function info_block {
    echo "${LINE}"
    print_info "$@"
    echo "${LINE}"
}

function install_ansible {
    pip install --upgrade "ansible>=2.2.0.0"
}

function create_virtualenv_for_ansible {
    # Create a Virtualenv for the Ansible runtime
    PYTHON_EXEC_PATH="$(which python2 || which python)"
    virtualenv --clear --always-copy --system-site-packages --python="${PYTHON_EXEC_PATH}" /opt/ansible-runtime

}