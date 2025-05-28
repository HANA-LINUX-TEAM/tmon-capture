#!/bin/bash

SHM_DIR="/dev/shm/tmp-capture"
DEST_DIR="$HOME/tmon-capture/images"
LOG_FILE="$HOME/tmon-capture/logs/flush.log"

mkdir -p "$DEST_DIR"

inotifywait -m "$SHM_DIR" --event close_write |
while read -r dir action filename; do
  SRC_FILE="${SHM_DIR}/${filename}"
  DEST_FILE="${DEST_DIR}/${filename}"

  # 🔒 이미 존재하면 복사하지 않음
  if [ -e "$DEST_FILE" ]; then
    echo "⚠️ 이미 존재하는 파일: $filename → 복사 생략" | tee -a "$LOG_FILE"
    continue
  fi

  echo "📥 Detected: $filename → 디스크로 복사 중..." | tee -a "$LOG_FILE"
  cp -n "$SRC_FILE" "$DEST_FILE" && echo "✅ 복사 완료: $filename" | tee -a "$LOG_FILE"
done
