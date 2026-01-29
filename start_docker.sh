#!/bin/bash
# 快速启动 Docker 容器脚本

set -e

echo "========================================="
echo "A股自选股智能分析系统 - Docker 快速启动"
echo "========================================="
echo ""

# 切换到项目根目录
cd "$(dirname "$0")"

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "❌ 错误: .env 文件不存在"
    echo "请先创建 .env 文件并配置必要的环境变量"
    exit 1
fi

echo "✓ 检查 .env 文件存在"
echo ""

# 默认操作
ACTION="${1:-restart}"

case "$ACTION" in
    # 快速重启（不重新构建）
    restart)
        echo "🔄 快速重启容器（不重新构建）..."
        docker-compose -f ./docker/docker-compose.yml restart webui
        ;;

    # 完整重启（先停止再启动）
    reload)
        echo "🔄 完整重启容器（停止->启动）..."
        docker-compose -f ./docker/docker-compose.yml down
        docker-compose -f ./docker/docker-compose.yml up -d webui
        ;;

    # 重新构建并启动
    rebuild)
        echo "🔨 重新构建镜像并启动..."
        docker-compose -f ./docker/docker-compose.yml down
        docker-compose -f ./docker/docker-compose.yml build webui
        docker-compose -f ./docker/docker-compose.yml up -d webui
        ;;

    # 启动（如果未运行）
    start)
        echo "▶️  启动容器..."
        docker-compose -f ./docker/docker-compose.yml up -d webui
        ;;

    # 停止
    stop)
        echo "⏸️  停止容器..."
        docker-compose -f ./docker/docker-compose.yml stop webui
        ;;

    # 查看日志
    logs)
        echo "📋 查看容器日志..."
        docker-compose -f ./docker/docker-compose.yml logs -f webui
        ;;

    # 查看状态
    status)
        echo "📊 容器状态:"
        docker-compose -f ./docker/docker-compose.yml ps
        echo ""
        echo "📊 镜像信息:"
        docker images | grep -E "REPOSITORY|stock"
        ;;

    # 更新代码到容器（不重新构建）
    update)
        echo "📦 更新代码到容器..."
        if ! docker ps | grep -q stock-webui; then
            echo "❌ 容器未运行，请先启动容器"
            exit 1
        fi

        # 复制关键Python文件到容器
        echo "  → 复制 data_provider/akshare_fetcher.py"
        docker cp ./data_provider/akshare_fetcher.py stock-webui:/app/data_provider/
        echo "  → 复制 web/handlers.py"
        docker cp ./web/handlers.py stock-webui:/app/web/
        echo "  → 复制 web/templates.py"
        docker cp ./web/templates.py stock-webui:/app/web/

        echo ""
        echo "✓ 代码更新完成，重启容器..."
        docker-compose -f ./docker/docker-compose.yml restart webui
        ;;

    *)
        echo "用法: $0 [操作]"
        echo ""
        echo "操作选项:"
        echo "  restart  - 快速重启容器（默认，不重新构建）"
        echo "  reload   - 完整重启（停止->启动）"
        echo "  rebuild  - 重新构建镜像并启动"
        echo "  start    - 启动容器"
        echo "  stop     - 停止容器"
        echo "  logs     - 查看日志"
        echo "  status   - 查看状态"
        echo "  update   - 快速更新代码到容器（不重新构建）"
        echo ""
        echo "示例:"
        echo "  $0           # 快速重启"
        echo "  $0 rebuild   # 重新构建"
        echo "  $0 update    # 更新代码"
        echo "  $0 logs      # 查看日志"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "✓ 操作完成"
echo "========================================="
echo ""
echo "WebUI 地址: http://localhost:8888"
echo "健康检查:   curl http://localhost:8888/health"
echo "测试分析:   curl 'http://localhost:8888/analysis?code=03690'"
echo ""
echo "查看日志:   docker-compose -f ./docker/docker-compose.yml logs -f webui"
echo "进入容器:   docker exec -it stock-webui bash"
