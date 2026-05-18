#!/bin/bash

# 项目打包脚本 - 生成干净的代码包
# 用法: ./package.sh [输出文件名]

# 自动获取当前目录名作为项目目录名
PROJECT_DIR=$(basename "repo")

# 设置输出文件名（默认：label-当前目录名.zip）
OUTPUT_NAME=${1:-"repo.zip"}

echo "📦 开始打包项目..."
echo "📁 项目目录: $PROJECT_DIR"
echo "💾 输出文件: $OUTPUT_NAME"
echo ""

# 如果已存在同名文件，先删除
if [ -f "$OUTPUT_NAME" ]; then
  echo "🗑️  检测到已存在的 $OUTPUT_NAME，正在删除..."
  rm -f "$OUTPUT_NAME"
  echo "✅ 已删除旧文件"
  echo ""
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/$PROJECT_DIR"

# 复制项目文件到临时目录
echo "📋 复制项目文件..."
mkdir -p "$PACKAGE_DIR"
rsync -a --progress \
  --exclude='.gitignore' \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='dist' \
  --exclude='build' \
  --exclude='target' \
  --exclude='.DS_Store' \
  --exclude='*.log' \
  --exclude='coverage' \
  --exclude='.next' \
  --exclude='.cache' \
  --exclude='*.swp' \
  --exclude='*.swo' \
  --exclude='.vscode' \
  --exclude='.idea' \
  --exclude='*.zip' \
  --exclude='package.sh' \
  --exclude='.github' \
  --exclude='Dockerfile' \
  --exclude='docker-compose.yml' \
  --include='README.md' \
  --exclude='*.md' \
  --include='requirements.txt' \
  --exclude='*.txt' \
  --exclude='run.sh' \
  . "$PACKAGE_DIR/"

echo ""
echo "🗜️  压缩文件..."

# 保存当前目录
CURRENT_DIR=$(pwd)

# 切换到临时目录并压缩
cd "$TEMP_DIR" || {
  echo "❌ 错误: 无法切换到临时目录"
  rm -rf "$TEMP_DIR"
  exit 1
}

zip -r -q "$CURRENT_DIR/$OUTPUT_NAME" "$PROJECT_DIR" || {
  echo "❌ 错误: 压缩失败"
  rm -rf "$TEMP_DIR"
  exit 1
}

# 返回原目录
cd "$CURRENT_DIR"

# 清理临时目录
rm -rf "$TEMP_DIR"

# 检查文件是否存在
if [ ! -f "$OUTPUT_NAME" ]; then
  echo "❌ 错误: 压缩文件未创建"
  exit 1
fi

# 获取文件大小
SIZE=$(du -h "$OUTPUT_NAME" | cut -f1)

echo ""
echo "✅ 打包完成！"
echo "📦 文件: $OUTPUT_NAME"
echo "📊 大小: $SIZE"
echo ""
echo "💡 提示: 可以使用以下命令解压："
echo "   unzip $OUTPUT_NAME"
