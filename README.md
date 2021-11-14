一种安全可靠的移动办公解决方案

## 概述

移动办公，是指随时随地，使用智能终端或笔记本电脑，接入企业内网，从事工作内容的场景。在员工出差，非工作时间等场景下，对及时处理工作事宜很有帮助。现有的解决方案还不够安全，数据传输未加密或传输的数据特征十分明细，很容易被分析出来。在特殊时期不得不关停服务以防被攻击。

提供一套安全可靠的内网穿透服务，或是远程访问方式，或是隐秘的VPN服务，从原理上保证数据的加密传输，在网络上隐藏数据流的特征，提供服务的同时避免被检测出所提供的服务。从而实现安全可靠的移动办公解决方案。该方案采用IT技术来实现，零成本。可成为当前手机办公、VPN办公，云桌面办公等方案的替代品。

市面上的大多数VPN服务搭建之后数据特征很明显，被探测后可实施中间人攻击或基于原理的攻击。使用小众的加密技术混合使用，可将业务数据完全封装成数据流，即使数据传输被劫持，也无法基于特征分析数据类型。从而可实现内网穿透，或可信的VPN服务。在安全可靠的基础上，为企业的移动办公提供IT技术支持。

利用现有的非对称加密算法，自行搭建配置参数，开发小众的内网穿透服务，即可避免暴露出明显的VPN特征，实现安全可靠的移动办公。

## 功能介绍

1. 服务端搭建
2. http 代理 - 外网直接访问内网服务
3. 端口转发 - 安全地暴露内网服务
4. 简单文件访问服务

## 服务端搭建

> 默认服务器端系统为发行版 linux。

**基础配置**

服务器需要为双网卡，连接内网与外网，且外网为公网 IP，可被直接访问。

搭建过程需要连接互联网。执行下面的脚本进行安装。

### **安装 http 代理**

```sh
wget -N --no-check-certificate https://raw.githubusercontent.com/remote-work-ln/remotework/master/proxy.sh && chmod +x proxy.sh && ./proxy.sh
```

### **安装端口转发**

```sh
wget -N --no-check-certificate https://raw.githubusercontent.com/remote-work-ln/remotework/master/forward.sh && chmod +x forward.sh && ./forward.sh
```

默认的服务端配置保存在`/usr/local/forward/forwards.ini`：

```ini
[common]
bind_addr = 0.0.0.0
bind_port = 7000
# 令牌
token = remotework
# 允许使用的端口范围
allow_ports = 1080,2000-3000,4000-65535
# 虚拟web端口
vhost_http_port = 800
# 仪表盘
dashboard_addr = 0.0.0.0
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = forward
```

> 令牌`token`：需要服务端与客户端一致方可连接成功。
> `allow_ports`：仅允许客户端在指定的范围内配置端口转发
> `vhost_http_port`：配置简单文件访问服务时使用的端口号
> `dashboard`相关：设置后可查看服务器端实时的状态，基于 basic 验证。
> （浏览器访问：`dashboard_addr:dashboard_port`）

可按需修改。

**提示 wget: command not found 的错误：**

这是系统精简的太干净了，wget都没有安装，所以需要安装wget。

```sh
# CentOS系统:
yum install -y wget
 
# Debian/Ubuntu系统:
apt-get install -y wget
```

## 使用方法1 - http 代理

> 外网直接访问内网服务

访问<https://github.com/remote-work-ln/proxy/releases>，下载客户端命令行工具。在命令行运行即可。

```sh
proxy client -l 127.0.0.1:8080 -i 127.0.0.1 -s server_address:port -p password --http
```

在上面的命令中：`server_address`为服务器的 IP 地址或域名，`port`和`password`是在服务端搭建的时候设置的。`port`默认为`1080`，`password`默认为`proxy`。

为了方便使用，可以新建一个`.bat`脚本。将上面的命令输入并保存。使用时双击脚本文件即可。

运行后，设置浏览器的代理为上面的`127.0.0.1:8080`，即可实现通过服务器代理访问内网服务。

**附设置 IE 代理的脚本，可在 cmd 运行，或保存到`.bat`文件运行**

一键设置并开启代理：

```sh
@echo Set IE proxy: 127.0.0.1:8080
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /d "127.0.0.1:8080" /f
ping 127.1 -n 3 >nul
exit
```

一键关闭代理：

```sh
@echo close IE proxy
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
ping 127.1 -n 3 >nul
exit
```

## 使用方法2 - 端口转发

> 安全地暴露内网服务

端口转发需要远程访问者与内网的被访问者同时设置并运行小工具。

### 简单端口转发

**内网被访问主机**：

1. 访问<https://github.com/remote-work-ln/forward/releases>下载对应系统的`forwardc`，即`forward client`。

2. 配置`forwardc.ini`：

    ```ini
    [common]
    server_addr = x.x.x.x
    server_port = 7000
    token = remotework
    [rdp]
    type = tcp
    local_ip = 127.0.0.1
    local_port = 3389
    remote_port = 63389
    ```

3. 启动运行（命令行）：启动运行：`./forwardc -c ./forwardc.ini`

**外网访问者**：

无需配置，直接启动远程桌面，访问地址输入：`server_addr:63389`

>此方式访问不安全。不建议使用。请使用下面的方法

### 加密端口转发

>与简单端口转发相比增加了加密配置。访问者也需要下载`forwardc`并配置使用。

**内网被访问主机**：

配置`forwardc.ini`：

```ini
[common]
server_addr = x.x.x.x
server_port = 7000
token = remotework
[secret_rdp]
type = stcp
# 只有 sk 一致的用户才能访问到此服务
sk = abcdefg
local_ip = 127.0.0.1
local_port = 3389

> 变化：
>
> - type 变为 stcp
> - 新增 sk，secure key
> - 不再需要 remote_port
```

**外网访问者**

1. 下载 [forwardc](https://github.com/remote-work-ln/forward/releases) 

2. 配置`forwardc.ini`：

    ```ini
    [common]
    server_addr = x.x.x.x
    server_port = 7000
    token = remotework
    [secret_rdp_visitor]
    type = stcp
    # stcp 的访问者
    role = visitor
    # 要访问的 stcp 代理的名字
    server_name = secret_rdp
    sk = abcdefg
    # 绑定本地端口用于访问 rdp 服务
    bind_addr = 127.0.0.1
    bind_port = 6000
    ```

3. 启动运行（命令行）：`./forwardc -c ./forwardc.ini`

4. 通过远程桌面访问时，地址栏输入：`127.0.0.1:6000`

## 使用方法3 - 自定义域名访问内网的 web 服务

服务器搭建部分提到一个配置：

```ini
# 虚拟web端口
vhost_http_port = 800
```

在这里将会用到。

**内网 web 服务器**

1. 下载 [forwardc](https://github.com/remote-work-ln/forward/releases) 
2. 配置`forwardc.ini`：

    ```ini
    [common]
    server_addr = x.x.x.x
    server_port = 7000
    token = remotework
    [web]
    type = http
    local_port = 80
    custom_domains = www.yourdomain.com
    ```

3. 启动运行（命令行）：`./forwardc -c ./forwardc.ini`

将 `www.yourdomain.com` 的域名 A 记录解析到 IP `x.x.x.x`，如果服务器已经有对应的域名，也可以将 CNAME 记录解析到服务器原先的域名。

通过浏览器访问 `http://www.yourdomain.com:800` 即可访问到处于内网机器上的 web 服务。

## 使用方法4 - 简单文件访问服务

**文件服务器**

1. 下载 [forwardc](https://github.com/remote-work-ln/forward/releases) 

2. 配置`forwardc.ini`：

   ```ini
   [common]
   server_addr = x.x.x.x
   server_port = 7000
   token = remotework
   [test_static_file]
   type = tcp
   remote_port = 6000
   plugin = static_file
   # 要对外暴露的文件目录
   plugin_local_path = /tmp/file
   # 访问 url 中会被去除的前缀，保留的内容即为要访问的文件路径
   plugin_strip_prefix = static
   plugin_http_user = user
   plugin_http_passwd = passwd
   ```

3. 启动运行（命令行）：`./forwardc -c ./forwardc.ini`

通过浏览器访问 `http://x.x.x.x:6000/static/` 来查看位于 `/tmp/file` 目录下的文件，会要求输入已设置好的用户名和密码。