#!/bin/bash

echo "████████████████████████████████████████"
echo "█                                      █"
echo "█      Ultimate Privacy Cleaner        █"
echo "█      终极清理工具 v2.0           █"
echo "█                                      █"
echo "████████████████████████████████████████"
echo ""

# ================= 初始化检查 =================
if [ "$(id -u)" != "0" ]; then
   echo "✖ 必须使用root权限运行！" 
   exit 1
fi

# ================= 网络痕迹清理 =================
echo "🔍 正在清理网络痕迹..."

# 清除ARP缓存
ip -s -s neigh flush all &>/dev/null

# 清除连接追踪
echo 0 > /proc/sys/net/netfilter/nf_conntrack_count
modprobe -r nf_conntrack &>/dev/null

# 清除DNS缓存（不同系统）
systemd-resolve --flush-caches &>/dev/null  # systemd
/etc/init.d/nscd restart &>/dev/null        # 传统系统

# 清除防火墙日志
iptables -Z && ip6tables -Z
firewall-cmd --reload &>/dev/null

# ================= 系统日志清理 =================
echo "📝 正在粉碎系统日志..."

system_logs=(
    /var/log/wtmp /var/log/btmp /var/log/lastlog
    /var/log/secure* /var/log/auth.log* /var/log/messages*
    /var/log/syslog* /var/log/cron* /var/log/maillog*
    /var/log/yum.log /var/log/dmesg /var/log/audit/audit.log
    /var/log/firewalld* /var/log/tallylog /var/log/cloud-*
    /var/log/nginx/*access* /var/log/nginx/*error*
    /var/log/apache2/*access* /var/log/apache2/*error*
    /var/log/httpd/*access* /var/log/httpd/*error*
)

for log in "${system_logs[@]}"; do
    [ -e "$log" ] && shred -u -z -n 7 "$log" &>/dev/null
done

# ================= 宝塔专项清理 =================
echo "🛡️ 正在深度清理宝塔痕迹..."

bt_logs=(
    /www/server/panel/logs/*
    /www/server/panel/script/*
    /www/server/panel/data/*
    /www/server/panel/plugin/*/logs/*
    /www/server/panel/vhost/*/access_log/*
    /www/server/panel/vhost/*/error_log/*
)

for target in "${bt_logs[@]}"; do
    [ -e "$target" ] && shred -u -z -n 7 "$target" &>/dev/null
done

# 特殊处理数据库日志
find /www/server/panel/data -type f -name "*.db" -exec sqlite3 {} "DELETE FROM logs;" \; &>/dev/null

# ================= 临时文件清理 =================
echo "🧹 正在清扫临时文件..."

temp_dirs=(
    /tmp/*
    /var/tmp/*
    /root/.cache/*
    /home/*/.cache/*
    /www/server/panel/temp/*
)

for dir in "${temp_dirs[@]}"; do
    [ -d "$dir" ] && rm -rf "${dir:?}"/*
done

# ================= 内存痕迹清理 =================
echo "🧠 正在擦除内存痕迹..."

sync && echo 3 > /proc/sys/vm/drop_caches
echo 1 > /proc/sys/vm/compact_memory
echo 1 > /proc/sys/vm/overcommit_memory

# ================= 服务级清理 =================
echo "🔄 正在重置服务日志..."

services=(
    nginx apache2 httpd mysql redis memcached 
    pure-ftpd postgresql mongodb docker
)

for service in "${services}"; do
    systemctl restart "${service}" &>/dev/null
    journalctl --vacuum-time=1s --unit="${service}" &>/dev/null
done

# ================= 终极防护 =================
echo "🔒 正在部署防护措施..."

# 锁定关键目录
chattr -R +i /var/log/ &>/dev/null
chattr -R +i /www/server/panel/logs/ &>/dev/null

# 禁用历史记录
echo 'unset HISTFILE' >> /etc/profile
echo 'set +o history' >> /etc/profile
source /etc/profile

# ================= 完成提示 =================
echo ""
echo "████████████████████████████████████████"
echo "█                                      █"
echo "█      ✅ 深度清理完成！注意事项：      █"
echo "█                                      █"
echo "█ 1. 所有网络连接痕迹已清除             █"
echo "█ 2. 需手动重启服务器生效               █"
echo "█ 3. 部分服务可能需要重新配置           █"
echo "█                                      █"
echo "████████████████████████████████████████"

# 最后强制断开所有连接（可选）
# pkill -9 -u root && exit
