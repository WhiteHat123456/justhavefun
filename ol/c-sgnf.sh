#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#Thank you rico
#This is a free version,If you have money, please buy the commercial version
# Current folder
cur_dir=`pwd`
# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
software=(Docker_Caddy Docker_Caddy_cloudflare Docker)
operation=(install update_config update_image logs)
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1


ssrpanel_url=
ssrpanel_key=
ssrpanel_speedtest=
ssrpanel_node_id=
v2ray_api_port=
v2ray_downWithPanel=


# get parameter
while getopts u:k:s:n:p:z: opts; do
  case ${opts} in
    u) ssrpanel_url=${OPTARG} ;;
    k) ssrpanel_key=${OPTARG} ;;
    s) ssrpanel_speedtest=${OPTARG} ;;
    n) ssrpanel_node_id=${OPTARG} ;;
    p) v2ray_api_port=${OPTARG} ;;
    z) v2ray_downWithPanel=${OPTARG} ;;
  esac
done 

echo "$ssrpanel_url"

#Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
error_detect_depends(){
    local command=$1
    local depend=`echo "${command}" | awk '{print $4}'`
    echo -e "[${green}Info${plain}] Starting to install package ${depend}"
    ${command} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Failed to install ${red}${depend}${plain}"
        echo "Please visit: https://teddysun.com/486.html and contact."
        exit 1
    fi
}

# Pre-installation settings
pre_install_docker_compose(){
    # Set ssrpanel_url
    echo "Please ssrpanel_url"
    #read -p "(There is no default value please make sure you input the right thing):" ssrpanel_url
    [ -z "${ssrpanel_url}" ]
    echo
    echo "---------------------------"
    echo "ssrpanel_url = ${ssrpanel_url}"
    echo "---------------------------"
    echo
    # Set ssrpanel key
    echo "ssrpanel key"
    #read -p "(There is no default value please make sure you input the right thing):" ssrpanel_key
    [ -z "${ssrpanel_key}" ]
    echo
    echo "---------------------------"
    echo "ssrpanel_key = ${ssrpanel_key}"
    echo "---------------------------"
    echo

    # Set ssrpanel speedtest function
    echo "use ssrpanel speedtest"
    #read -p "(ssrpanel speedtest: Default (6) hours every time):" ssrpanel_speedtest
    [ -z "${ssrpanel_speedtest}" ] && ssrpanel_speedtest=6
    echo
    echo "---------------------------"
    echo "ssrpanel_speedtest = ${ssrpanel_speedtest}"
    echo "---------------------------"
    echo

    # Set ssrpanel node_id
    echo "ssrpanel node_id"
    #read -p "(Default value: 0 ):" ssrpanel_node_id
    [ -z "${ssrpanel_node_id}" ] && ssrpanel_node_id=0
    echo
    echo "---------------------------"
    echo "ssrpanel_node_id = ${ssrpanel_node_id}"
    echo "---------------------------"
    echo

    # Set V2ray backend API Listen port
    echo "Setting V2ray backend API Listen port"
    #read -p "(V2ray API Listen port(Default 2333):" v2ray_api_port
    [ -z "${v2ray_api_port}" ] && v2ray_api_port=2333
    echo
    echo "---------------------------"
    echo "V2ray API Listen port = ${v2ray_api_port}"
    echo "---------------------------"
    echo

    # Set Setting if the node go downwith panel
    echo "Setting if the node go downwith panel"
    #read -p "(v2ray_downWithPanel (Default 1):" v2ray_downWithPanel
    [ -z "${v2ray_downWithPanel}" ] && v2ray_downWithPanel=1
    echo
    echo "---------------------------"
    echo "v2ray_downWithPanel = ${v2ray_downWithPanel}"
    echo "---------------------------"
    echo
}



# Config docker
config_docker(){
    echo "Press any key to start...or Press Ctrl+C to cancel"
    #char=`get_char`
    cd ${cur_dir}
    echo "install curl"
    install_dependencies
    echo "Writing docker-compose.yml"
    curl -L https://raw.githubusercontent.com/WhiteHat123456/justhavefun/master/yml/sgnf-docker-compose.yml > docker-compose.yml
    sed -i "s|node_id:.*|node_id: ${ssrpanel_node_id}|"  ./docker-compose.yml
    sed -i "s|sspanel_url:.*|sspanel_url: '${ssrpanel_url}'|"  ./docker-compose.yml
    sed -i "s|key:.*|key: '${ssrpanel_key}'|"  ./docker-compose.yml
    sed -i "s|speedtest:.*|speedtest: ${ssrpanel_speedtest}|"  ./docker-compose.yml
    sed -i "s|api_port:.*|api_port: ${v2ray_api_port}|" ./docker-compose.yml
    sed -i "s|downWithPanel:.*|downWithPanel: ${v2ray_downWithPanel}|" ./docker-compose.yml
}



# Install docker and docker compose
install_docker(){
    echo -e "Starting installing Docker "
    curl -fsSL https://get.docker.com -o get-docker.sh
    bash get-docker.sh
    echo -e "Starting installing Docker Compose "
    curl -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/1.8.0/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose
    clear
    echo "Start Docker "
    service docker start
    echo "Start Docker-Compose "
    docker-compose up -d
    echo
    echo -e "Congratulations, V2ray server install completed!"
    echo
    echo "Enjoy it!"
    echo
}

install_check(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_select(){
    
    while true
    do
    echo  "Which v2ray Docker you'd select:"
    for ((i=1;i<=${#software[@]};i++ )); do
        hint="${software[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
#    read -p "Please enter a number (Default ${software[0]}):" selected
selected="1"
[ -z "${selected}" ] && selected="1"
selected="3"
    case "${selected}" in
        1|2|3|4)
        echo
        echo "You choose = ${software[${selected}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-4]"
        ;;
    esac
    done
}
install_dependencies(){
    if check_sys packageManager yum; then
        echo -e "[${green}Info${plain}] Checking the EPEL repository..."
        if [ ! -f /etc/yum.repos.d/epel.repo ]; then
            yum install -y epel-release > /dev/null 2>&1
        fi
        [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] Install EPEL repository failed, please check it." && exit 1
        [ ! "$(command -v yum-config-manager)" ] && yum install -y yum-utils > /dev/null 2>&1
        [ x"$(yum-config-manager epel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable epel > /dev/null 2>&1
        echo -e "[${green}Info${plain}] Checking the EPEL repository complete..."

        yum_depends=(
             curl
        )
        for depend in ${yum_depends[@]}; do
            error_detect_depends "yum -y install ${depend}"
        done
    elif check_sys packageManager apt; then
        apt_depends=(
           curl
        )
        apt-get -y update
        for depend in ${apt_depends[@]}; do
            error_detect_depends "apt-get -y install ${depend}"
        done
    fi
    echo -e "[${green}Info${plain}] Setting TimeZone to Shanghai"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"

}
#update_image
update_image_v2ray(){
    echo "Shut down the current service"
    docker-compose down
    echo "Pulling Images"
    docker-compose pull
    echo "Start Service"
    docker-compose up -d
}

#show last 100 line log

logs_v2ray(){
    echo "Last 100 line logs"
    docker-compose logs --tail 100
}

# Update config
update_config_v2ray(){
    cd ${cur_dir}
    echo "Shut down the current service"
    docker-compose down
    install_select
    case "${selected}" in
        1)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker
        ;;
        2)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker_cloudflare
        ;;
        3)
        pre_install_docker_compose
        config_docker
        ;;
        *)
        echo "Wrong number"
        ;;
    esac

    echo "Start Service"
    docker-compose up -d

}
# remove config
# Install v2ray
install_v2ray(){
    install_select
    case "${selected}" in
        1)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker
        ;;
        2)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker_cloudflare
        ;;
        3)
        pre_install_docker_compose
        config_docker
        ;;
        *)
        echo "Wrong number"
        ;;
    esac
    install_docker
}

# Initialization step

while true
do
echo  "Which operation you'd select:"
for ((i=1;i<=${#operation[@]};i++ )); do
    hint="${operation[$i-1]}"
    echo -e "${green}${i}${plain}) ${hint}"
done
#read -p "Please enter a number (Default ${operation[0]}):" selected
selected="1"
[ -z "${selected}" ] && selected="1"

case "${selected}" in
    1|2|3|4)
    echo
    echo "You choose = ${operation[${selected}-1]}"
    echo
    ${operation[${selected}-1]}_v2ray
    break
    ;;
    *)
    echo -e "[${red}Error${plain}] Please only enter a number [1-4]"

    ;;
esac
done
