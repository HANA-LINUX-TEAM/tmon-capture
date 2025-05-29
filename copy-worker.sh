#!/bin/bash

TARGET_COUNT=$1
if [[ -z "$TARGET_COUNT" || "$TARGET_COUNT" -le 0 ]]; then
  echo "❌ 복사 개수 인자가 필요합니다"
  exit 1
fi

SHM_DIR="/dev/shm/tmp_images"
DEST_DIR="$HOME/tmon-capture/images"
LOG_FILE="$HOME/tmon-capture/logs/flush.log"
COPIED_COUNT=0

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

  ((COPIED_COUNT++))
  if [ "$COPIED_COUNT" -ge "$TARGET_COUNT" ]; then
    echo "✅ $COPIED_COUNT개 이미지 복사 완료 → 종료" | tee -a "$LOG_FILE"
    break
  fi
  
done
