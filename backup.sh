#!/usr/bin/env sh
#
# Backup a Postgresql database into a daily file.
#
VER=0.1
SCRIPT_NAME="backup.sh"
PROJECT="https://github.com/PierNola/BackupPg/"
PROJECT_RAW="https://raw.githubusercontent.com/PierNola/BackupPg/main/"

BACKUP_DIR=/opt/backup
DATA_DIR=${BACKUP_DIR}/data
ARCH_DIR=${BACKUP_DIR}/archives
LOG_DIR=${BACKUP_DIR}/log

DAY_TO_KEEP_DUMP=14
DAY_TO_KEEP_LOG=14

DATE=$(date +"%Y%m%d-%H%M")
LOG_FILE=${LOG_DIR}/${DATE}-backup.log

backup() {
    _date_echo "Starting PostgreSQL backup" >${LOG_FILE} 

    DBLIST=`psql -U postgres -d postgres -q -t -c "SELECT datname FROM pg_database WHERE NOT datistemplate"` 2>>${LOG_FILE}
    for DB in ${DBLIST}; do  
        GZ_DMP_FILE=${DATA_DIR}/${DB}.dmp.gz
        ARCH_GZ_DMP_FILE=${ARCH_DIR}/${DATE}-${DB}.dmp.gz

        _date_echo "Starting backup of database '${DB}'" >>${LOG_FILE}
        pg_dump -Upostgres -v ${DB} -F p 2>>${LOG_FILE}  | gzip >${GZ_DMP_FILE}

        _date_echo "Creating backup archives of database '${DB}'" >>${LOG_FILE}
        cp ${GZ_DMP_FILE} ${ARCH_GZ_DMP_FILE}
    done

    _date_echo "Prune all archives backup older then ${DAY_TO_KEEP_DUMP} days" >>${LOG_FILE} 
    find ${ARCH_DIR} -maxdepth 1 -type f -mtime +${DAY_TO_KEEP_DUMP} -name "*.gz" -delete 2>&1 >>${LOG_FILE}

    _date_echo "End PostgreSQL backup" >>${LOG_FILE} 

    # prune old logs
    find ${LOG_DIR} -maxdepth 1 -type f -mtime +${DAY_TO_KEEP_LOG} -name "*.log" -delete
}

install(){
    if [[ ! -z "${1}" ]]; then
        BACKUP_DIR="${1}"
    fi

    DATA_DIR=${BACKUP_DIR}/data
    ARCH_DIR=${BACKUP_DIR}/archives
    LOG_DIR=${BACKUP_DIR}/log

    _date_echo "Installing to '${BACKUP_DIR}'"

    if [ ! -d "${BACKUP_DIR}" ]; then
        if ! mkdir -p "${BACKUP_DIR}"; then
            _err "Can not create dir: ${BACKUP_DIR}"
            return 1
        fi
    fi
  
    if [ ! -d "${DATA_DIR}" ]; then
        if ! mkdir -p "${DATA_DIR}"; then
            _err "Can not create dir: ${DATA_DIR}"
            return 1
        fi
    fi

    if [ ! -d "${ARCH_DIR}" ]; then
        if ! mkdir -p "${ARCH_DIR}"; then
            _err "Can not create dir: ${ARCH_DIR}"
            return 1
        fi
    fi

    if [ ! -d "${LOG_DIR}" ]; then
        if ! mkdir -p "${LOG_DIR}"; then
            _err "Can not create dir: ${LOG_DIR}"
            return 1
        fi
    fi
    cp "${SCRIPT_NAME}" "${BACKUP_DIR}/" && chmod +x "${BACKUP_DIR}/${SCRIPT_NAME}"

    if [ "$?" != "0" ]; then
        _err "Install failed, can not copy ${SCRIPT_NAME} to ${BACKUP_DIR}"
        return 1
    fi

    installcronjob

    FULL_SCRIPT_NAME=$(readlink -nf ${0})
    INSTALL_SCRIPT_NAME=$(readlink -nf ${BACKUP_DIR}/${SCRIPT_NAME})

    _date_echo "Install to '${BACKUP_DIR}' finished"

    if [ "${FULL_SCRIPT_NAME}" != "${INSTALL_SCRIPT_NAME}" ]; then
        rm -f "${FULL_SCRIPT_NAME}"
    fi
}

installonline() {
    if _exists curl; then 
        curl ${PROJECT_RAW}backup.sh  -o backup.sh
        chmod +x ${SCRIPT_NAME}
        ./${SCRIPT_NAME} --install ${1}
    elif _exists wget ; then 
        wget ${PROJECT_RAW}/backup.sh
        chmod +x ${SCRIPT_NAME}
        ./${SCRIPT_NAME} --install ${1}
    else 
        echo "Sorry, you must have curl or wget installed first." 
        echo "Please install either of them and try again." 
    fi 
}

installcronjob() {
    _CRONTAB="crontab"
    if [ ! -f "${BACKUP_DIR}/${SCRIPT_NAME}" ]; then
        _err "Can not install cronjob, ${BACKUP_DIR}/${SCRIPT_NAME} not found."
        return 1
    fi

    _date_echo "Installing cron job"
    if ! ${_CRONTAB} -l | grep "${BACKUP_DIR}/${SCRIPT_NAME} --run"; then
      ${_CRONTAB} -l | {
        cat
        echo "30 22 * * * ${BACKUP_DIR}/${SCRIPT_NAME} --run > /dev/null"
      } | ${_CRONTAB} -
    fi
  
    if [ "$?" != "0" ]; then
        _err "Install cron job failed."
        return 1
    fi

    _date_echo "Install cron job finished"
}

_date_echo() {
    date +"[%Y-%m-%d %H:%M] ${1}"
}

_err() {
    date +"[!!! Error !!!] ${1}"
}

_info() {
    date +"[Info] ${1}"
}

_exists() { 
    cmd="$1" 
    if [ -z "$cmd" ] ; then 
        echo "Usage: _exists cmd" return 1 
    fi 
    if type command >/dev/null 2>&1 ; then 
        command -v $cmd >/dev/null 2>&1 
    else 
        type $cmd >/dev/null 2>&1 
    fi 
    ret="$?" 
    return $ret 
}

_process(){
    while [ ${#} -gt 0 ]; do
        case "${1}" in
            --help | -h)
                showhelp
                return
                ;;
            --version | -v)
                version
                return
                ;;
            --install | -i | install)
                install ${2}
                return
                ;;
            --installonline | installonline)
                installonline ${2}
                return
                ;;
            --run | -r)
                backup
                return
                ;;
            *)
                echo "Unknown parameter : $1"
                return 1
            ;;
        esac
    done
}

version() {
  echo "${PROJECT} - Version ${VER}"
}

showhelp() {
  version
  echo "Usage: $SCRIPT_NAME [commands]
Commands:
  -h, --help                   Show this help message.
  -v, --version                Show version info.
  -i, --install <directory>    Install to the specific direcotry.
  -r, --run                    Run backup of all databases
"
}

main() {
  [ -z "${1}" ] && showhelp && return
  _process "${@}"
}

main "${@}"
