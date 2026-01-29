#!/bin/bash
# 服务器代理问题修复脚本

set -e

echo "========================================"
echo "服务器代理问题修复脚本"
echo "========================================"
echo ""

# 检查容器是否运行
if ! docker ps | grep -q stock-webui; then
    echo "❌ 容器 stock-webui 未运行，请先启动容器"
    exit 1
fi

echo "1. 检查当前代理配置..."
echo "----------------------------------------"
echo "容器内环境变量："
docker exec stock-webui env | grep -i proxy || echo "  ✓ 无代理环境变量"
echo ""

echo "2. 检查 main.py 代理设置..."
echo "----------------------------------------"
docker exec stock-webui sed -n "26,35p" /app/main.py
echo ""

echo "3. 修复 main.py 代理配置..."
echo "----------------------------------------"
docker exec stock-webui bash -c '
# 注释掉代理设置
sed -i "29,30s/^[[:space:]]*os\.environ/    # os.environ/" /app/main.py
echo "✓ main.py 代理已注释"
'

echo "4. 验证修复结果..."
echo "----------------------------------------"
docker exec stock-webui sed -n "26,35p" /app/main.py
echo ""

echo "5. 测试网络连接..."
echo "----------------------------------------"
if docker exec stock-webui curl -I -m 10 http://llmapi.bilibili.co/v1 2>&1 | grep -q "HTTP"; then
    echo "✓ API 地址可访问"
else
    echo "⚠️  API 地址访问失败，可能是网络问题"
fi
echo ""

echo "6. 重启容器..."
echo "----------------------------------------"
cd "$(dirname "$0")"
docker-compose -f ./docker/docker-compose.yml restart webui
echo "✓ 容器已重启"
echo ""

echo "========================================"
echo "修复完成！"
echo "========================================"
echo ""
echo "测试命令："
echo "  curl 'http://localhost:8888/analysis?code=600519'"
echo ""
echo "查看日志："
echo "  docker-compose -f ./docker/docker-compose.yml logs --tail=100 webui | grep -E 'OpenAI|LLM'"
