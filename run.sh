#!/bin/bash
set -e

echo "🔍 필수 패키지 확인 및 설치 중..."

# Redis CLI 확인
if ! command -v redis-cli >/dev/null 2>&1; then
  echo "📦 redis 설치 중..."
  sudo apt-get install -y redis
else
  echo "✅ redis 이미 설치됨"
fi

# wkhtmltoimage 확인
if ! command -v wkhtmltoimage >/dev/null 2>&1; then
  echo "📦 wkhtmltopdf (wkhtmltoimage 포함) 설치 중..."
  sudo apt-get install -y wkhtmltopdf
else
  echo "✅ wkhtmltoimage 이미 설치됨"
fi

# inotifywait 확인
if ! command -v inotifywait >/dev/null 2>&1; then
  echo "📦 inotify-tools 설치 중..."
  sudo apt-get install -y inotify-tools
else
  echo "✅ inotify-tools 이미 설치됨"
fi

echo "🔧 실행 권한 부여..."
chmod +x enqueue.sh worker.sh main.sh copy-worker.sh

echo "🗑️ 이전 로그 및 이미지 디렉토리 초기화..."
rm -rf ~/tmon-capture/images/*
rm -rf ~/tmon-capture/logs/*
mkdir -p ~/tmon-capture/images ~/tmon-capture/logs

echo "🚀 작업 큐 등록 시작..."
./enqueue.sh

echo "🚀 전체 병렬 처리 시작..."
./main.sh

echo "✅ 전체 완료!"
 
