#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: forward
#	Version: 1.0
#	Author: remote-work-ln
#	Blog: https://
#=================================================

sh_ver="1.0"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/forward"
forward_file="/usr/local/forward/forward"
forward_conf="/usr/local/forward/forward.ini"
forward_log="/usr/local/forward/forward.log"
Crontab_file="/usr/bin/crontab"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${forward_file} ]] && echo -e "${Error} forward 没有安装，请检查 !" && exit 1
}
check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab 没有安装，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install crond -y
		else
			apt-get install cron -y
		fi
		if [[ ! -e ${Crontab_file} ]]; then
			echo -e "${Error} Crontab 安装失败，请检查！" && exit 1
		else
			echo -e "${Info} Crontab 安装成功！"
		fi
	fi
}
check_pid(){
	PID=$(ps -ef| grep "./forward "| grep -v "grep" | grep -v "forward.sh" | grep -v "init.d" |grep -v "service" |awk '{print $2}')
}
check_new_ver(){
	echo -e "请输入要下载安装的 forward 版本号 ${Green_font_prefix}[ 格式是日期，例如: v20190827 ]${Font_color_suffix}
版本列表请去这里获取：${Green_font_prefix}[ https://github.com/remote-work-ln/forward/releases ]${Font_color_suffix}"
	read -e -p "直接回车即自动获取:" forward_new_ver
	if [[ -z ${forward_new_ver} ]]; then
		forward_new_ver=$(wget -qO- https://api.github.com/repos/remote-work-ln/forward/releases| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g')
		[[ -z ${forward_new_ver} ]] && echo -e "${Error} forward 最新版本获取失败！" && exit 1
		echo -e "${Info} 检测到 forward 最新版本为 [ ${forward_new_ver} ]"
	else
		echo -e "${Info} 开始下载 forward [ ${forward_new_ver} ] 版本！"
	fi
}
check_ver_comparison(){
	forward_now_ver=$(${forward_file} -v|awk '{print $3}')
	[[ -z ${forward_now_ver} ]] && echo -e "${Error} forward 当前版本获取失败 !" && exit 1
	forward_now_ver="v${forward_now_ver}"
	if [[ "${forward_now_ver}" != "${forward_new_ver}" ]]; then
		echo -e "${Info} 发现 forward 已有新版本 [ ${forward_new_ver} ]，旧版本 [ ${forward_now_ver} ]"
		read -e -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			rm -rf ${forward_file}
			Download_forward
			Start_forward
		fi
	else
		echo -e "${Info} 当前 forward 已是最新版本 [ ${forward_new_ver} ]" && exit 1
	fi
}
Download_forward(){
	[[ ! -e ${file} ]] && mkdir ${file}
	cd ${file}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -N "https://github.com/remote-work-ln/forward/releases/download/${forward_new_ver}/forwards_linux_amd64"
		mv forwards_linux_amd64 forward
	else
		wget --no-check-certificate -N "https://github.com/remote-work-ln/forward/releases/download/${forward_new_ver}/forwards_linux_386"
		mv forwards_linux_386 forward
	fi
	[[ ! -e "forward" ]] && echo -e "${Error} forward 下载失败 !" && rm -rf "${file}" && exit 1
	chmod +x forward
}
Service_forward(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/remote-work-ln/remotework/master/service/forward_centos" -O /etc/init.d/forward; then
			echo -e "${Error} forward服务 管理脚本下载失败 !" && rm -rf "${file}" && exit 1
		fi
		chmod +x "/etc/init.d/forward"
		chkconfig --add forward
		chkconfig forward on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/remote-work-ln/remotework/master/service/forward_debian" -O /etc/init.d/forward; then
			echo -e "${Error} forward服务 管理脚本下载失败 !" && rm -rf "${file}" && exit 1
		fi
		chmod +x "/etc/init.d/forward"
		update-rc.d -f forward defaults
	fi
	echo -e "${Info} forward服务 管理脚本下载完成 !"
}
Download_config(){
	[[ ! -e ${file} ]] && mkdir ${file}
	cd ${file}
	wget --no-check-certificate -N "https://raw.githubusercontent.com/remote-work-ln/remotework/master/config/forwards.ini"
	[[ ! -e "forwards.ini" ]] && echo -e "${Error} forwards.ini 下载失败 !" && rm -rf "${file}" && exit 1
}
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
Centos_yum(){
	cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
	if [[ $? = 0 ]]; then
		yum update
		yum install -y net-tools
	fi
}
Debian_apt(){
	cat /etc/issue |grep 9\..*>/dev/null
	if [[ $? = 0 ]]; then
		apt-get update
		apt-get install -y net-tools
	fi
}
Read_config(){
	[[ ! -e ${forward_conf} ]] && echo -e "${Error} forward 配置文件不存在 !" && exit 1
	user_all=$(cat ${forward_conf}|sed "1d")
	user_all_num=$(echo "${user_all}"|wc -l)
	[[ -z ${user_all} ]] && echo -e "${Error} forward 配置文件中用户配置为空 !" && exit 1
	protocol=$(cat ${forward_conf}|sed -n "1p")
}
Install_forward(){
	check_root
	[[ -e ${forward_file} ]] && echo -e "${Error} 检测到 forward 已安装 !" && exit 1
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download_forward
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_forward
	echo -e "${Info} 开始下载 配置文件..."
	Download_config
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_forward
}
Start_forward(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} forward 正在运行，请检查 !" && exit 1
	/etc/init.d/forward start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_forward
}
Stop_forward(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} forward 没有运行，请检查 !" && exit 1
	/etc/init.d/forward stop
}
Restart_forward(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/forward stop
	/etc/init.d/forward start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_forward
}
Update_forward(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_forward(){
	check_installed_status
	echo "确定要卸载 forward ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		if [[ ! -z $(crontab -l | grep "forward.sh monitor") ]]; then
			crontab_monitor_forward_cron_stop
		fi
		rm -rf "${file}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del forward
		else
			update-rc.d -f forward remove
		fi
		rm -rf "/etc/init.d/forward"
		echo && echo "forward 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_forward(){
	check_installed_status
	Read_config
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
	clear && echo
	echo -e "当前外部IP为：${ip}"
	echo -e "forward 用户配置请查看：${file}/forwards.ini"
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/remote-work-ln/remotework/master/forward.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/forward" ]]; then
		rm -rf /etc/init.d/forward
		Service_forward
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/remote-work-ln/remotework/master/forward.sh" && chmod +x forward.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_forward
else
	echo && echo -e "  forward 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- remote-work-ln ----
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 forward
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 forward
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 forward
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 forward
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 forward
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 forward
————————————" && echo
	if [[ -e ${forward_file} ]]; then
		check_pid
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
	echo
	read -e -p " 请输入数字 [0-6]:" num
	case "$num" in
		0)
		Update_Shell
		;;
		1)
		Install_forward
		;;
		2)
		Update_forward
		;;
		3)
		Uninstall_forward
		;;
		4)
		Start_forward
		;;
		5)
		Stop_forward
		;;
		6)
		Restart_forward
		;;
		*)
		echo "请输入正确数字 [0-6]"
		;;
	esac
fi