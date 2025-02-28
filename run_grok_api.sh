#!/bin/bash

#####################################
# Grok API Docker 容器启动脚本
#####################################

# 项目信息：
# - 项目地址：https://github.com/sanshao85/grok3-api-free
# - Docker镜像：sanshao85/grok3-api-free:latest
#
# 本脚本用于快速部署 Grok API 服务，支持多种模型调用和图像生成功能。
# 更多详细信息和更新请访问项目地址。
#
# 使用说明：
# 1. 下载脚本后，先赋予执行权限：
#    chmod +x run_grok_api.sh
# 2. 使用root用户或sudo权限运行脚本：
#    sudo ./run_grok_api.sh
#    或
#    su root -c "./run_grok_api.sh"

# 环境变量设置（全局）
CONTAINER_NAME=grok3-api-free  # 容器名称
PORT=3000  # 默认端口
IS_TEMP_CONVERSATION=false
IS_TEMP_GROK2=true
GROK2_CONCURRENCY_LEVEL=1
API_KEY=sk-123456789
TUMY_KEY=108|80zxZaRn*********   # TUMY_KEY
# PICGO_KEY=  # 和 TUMY_KEY 二选一
IS_CUSTOM_SSO=false
ISSHOW_SEARCH_RESULTS=false
SHOW_THINKING=true
# 多个 SSO 令牌用英文逗号分隔
SSO=eyJhbGciOiJI********

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 用户运行此脚本"
    exit 1
fi

# 获取外网 IP
get_public_ip() {
    echo "正在获取服务器外网 IP..."
    PUBLIC_IP=$(curl -s http://ipinfo.io/ip)
    if [ $? -eq 0 ] && [ ! -z "$PUBLIC_IP" ]; then
        echo "服务器外网 IP: $PUBLIC_IP"
    else
        echo "无法获取外网 IP，请检查网络连接"
        PUBLIC_IP="unknown"
    fi
}

# 检查服务状态
check_service() {
    echo "正在检查服务状态..."
    
    # 检查本地访问
    echo "检查本地访问 (http://localhost:${PORT})..."
    local_response=$(curl -s http://localhost:${PORT})
    if [[ "$local_response" == "api运行正常"* ]]; then
        echo "✓ 本地访问正常"
        echo "  - 测试结果: $local_response"
        echo "  - 本地访问地址: http://localhost:${PORT}"
        local_status="success"
    else
        echo "✗ 本地访问异常"
        echo "  - 可能原因："
        echo "    1. 容器未完全启动，请等待几秒后重试"
        echo "    2. 容器启动失败，请检查容器日志"
        echo "    3. 端口映射可能有问题，请检查容器状态"
        local_status="fail"
        
        # 显示容器状态以帮助诊断
        echo
        echo "当前容器状态："
        docker ps -a | grep ${CONTAINER_NAME}
    fi

    # 检查外网访问
    if [ "$PUBLIC_IP" != "unknown" ]; then
        echo
        echo "外网访问检测："
        echo "- 服务器IP: ${PUBLIC_IP}"
        echo "- 外网访问地址: http://${PUBLIC_IP}:${PORT}"
        
        # 测试外网访问
        echo "正在测试外网访问..."
        external_response=$(curl -s http://${PUBLIC_IP}:${PORT})
        if [[ "$external_response" == "api运行正常"* ]]; then
            echo "✓ 外网访问正常"
            echo "  - 测试结果: $external_response"
        else
            echo "✗ 外网访问异常"
            if [ "$local_status" == "success" ]; then
                echo "  - 本地访问正常但外网访问失败，请检查："
                echo "    1. 防火墙配置："
                echo "       CentOS: firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent"
                echo "              firewall-cmd --reload"
                echo "       Ubuntu: ufw allow ${PORT}/tcp"
                echo "    2. 云服务器安全组是否已配置 ${PORT} 端口"
                echo "    3. 等待 1-2 分钟后再尝试访问"
                
                # 检查防火墙状态
                if command -v firewall-cmd &> /dev/null; then
                    echo
                    echo "防火墙端口状态："
                    firewall-cmd --zone=public --list-ports | grep ${PORT} || echo "端口 ${PORT} 未在防火墙中开放"
                fi
            fi
        fi
        
        # 检查端口状态
        echo
        echo "端口状态检查："
        if command -v nc &> /dev/null; then
            if nc -zv localhost ${PORT} 2>&1 | grep -q "succeeded"; then
                echo "✓ 端口 ${PORT} 已开放（本地）"
                # 检查外网端口
                if nc -zv ${PUBLIC_IP} ${PORT} 2>&1 | grep -q "succeeded"; then
                    echo "✓ 端口 ${PORT} 已开放（外网）"
                else
                    echo "✗ 端口 ${PORT} 未开放（外网）"
                fi
            else
                echo "✗ 端口 ${PORT} 未开放（本地）"
            fi
        else
            echo "提示：安装 nc 工具可以进行更详细的端口检测"
            echo "- CentOS: yum install -y nc"
            echo "- Ubuntu: apt-get install -y netcat"
        fi
    fi
}

# 容器管理函数
container_status() {
    echo "容器状态："
    docker ps -a | grep ${CONTAINER_NAME}
}

container_logs() {
    echo "容器日志："
    docker logs ${CONTAINER_NAME}
}

container_restart() {
    echo "重启容器..."
    docker restart ${CONTAINER_NAME}
    echo "容器已重启！"
}

container_remove() {
    echo "停止并删除容器..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
    echo "容器已删除！"
}

# 显示主菜单
show_menu() {
    echo "请选择要执行的操作："
    echo "1. 安装 Docker（CentOS 7.9）"
    echo "2. 运行 Grok API 容器"
    echo "3. 查看容器状态"
    echo "4. 查看容器日志"
    echo "5. 重启容器"
    echo "6. 删除容器并重新创建"
    echo "7. 检测服务状态"
    echo "8. 退出"
    echo
    read -p "请输入选项 (1-8): " choice
}

# 主循环
while true; do
    show_menu
    
    case $choice in
        1)
            echo "开始安装 Docker..."
            
            # 1. 移除旧版本
            yum remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine

            # 2. 设置 Docker 仓库
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

            # 3. 安装 Docker
            yum install -y docker-ce docker-ce-cli containerd.io

            # 4. 启动 Docker 服务
            systemctl start docker

            # 5. 设置 Docker 开机自启
            systemctl enable docker

            # 6. 验证安装
            docker run hello-world

            echo "Docker 安装完成！"
            echo "如果需要免 sudo 运行 docker，请执行："
            echo "sudo usermod -aG docker \$USER"
            echo "然后重新登录或重启系统"
            
            read -p "是否现在就运行 Grok API 容器？(y/n) " run_container
            if [ "$run_container" != "y" ]; then
                continue
            fi
            ;;
        2)
            # 检查 Docker 是否安装
            if ! command -v docker &> /dev/null; then
                echo "错误：Docker 未安装！请先选择选项 1 安装 Docker。"
                continue
            fi
            ;;
        3)
            container_status
            read -p "按回车键继续..."
            continue
            ;;
        4)
            container_logs
            read -p "按回车键继续..."
            continue
            ;;
        5)
            container_restart
            read -p "按回车键继续..."
            continue
            ;;
        6)
            container_remove
            echo "准备重新创建容器..."
            ;;
        7)
            get_public_ip
            check_service
            read -p "按回车键继续..."
            continue
            ;;
        8)
            echo "退出程序..."
            exit 0
            ;;
        *)
            echo "无效的选项！"
            read -p "按回车键继续..."
            continue
            ;;
    esac

    echo "正在启动 Grok API 容器..."

    # 运行 Docker 容器
    docker run -it -d \
      --name ${CONTAINER_NAME} \
      -p ${PORT}:${PORT} \
      -e IS_TEMP_CONVERSATION=${IS_TEMP_CONVERSATION} \
      -e IS_TEMP_GROK2=${IS_TEMP_GROK2} \
      -e GROK2_CONCURRENCY_LEVEL=${GROK2_CONCURRENCY_LEVEL} \
      -e API_KEY=${API_KEY} \
      -e TUMY_KEY=${TUMY_KEY} \
      -e IS_CUSTOM_SSO=${IS_CUSTOM_SSO} \
      -e ISSHOW_SEARCH_RESULTS=${ISSHOW_SEARCH_RESULTS} \
      -e PORT=${PORT} \
      -e SHOW_THINKING=${SHOW_THINKING} \
      -e SSO=${SSO} \
      sanshao85/grok3-api-free:latest 

    echo "容器启动完成！"
    
    # 自动检查服务状态
    echo "等待服务初始化..."
    for i in {15..1}; do
        echo -ne "\r⏳ 等待服务启动，还需 $i 秒..."
        sleep 1
    done
    echo -e "\n开始检测服务状态..."
    get_public_ip
    check_service
    
    read -p "按回车键返回主菜单..."
done 