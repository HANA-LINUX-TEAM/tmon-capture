#!/bin/bash

BASE_DIR="$HOME/tmon-capture"
OUTPUT_DIR="$BASE_DIR/images"
LOG_DIR="$BASE_DIR/logs"
TMP_OUTPUT_DIR="/dev/shm/tmp_capture"
WKHTML_CACHE_DIR="/dev/shm/wkhtml_cache_$$"

mkdir -p "$TMP_OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 초기 IP 할당
resolve_ip() {
  dig +short www.tmon.co.kr | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1
}

TMON_IP=$(resolve_ip)
TMON_HOST="www.tmon.co.kr"

# 성능 최적화용 환경 변수 설정
export QTWEBKIT_DISABLE_JIT=1
export QT_QPA_PLATFORM=offscreen

while true; do
  entry=$(redis-cli RPOP queue:urls)
  [ -z "$entry" ] && break

  deal_id=$(echo "$entry" | cut -d '|' -f1)
  count=$(echo "$entry" | cut -d '|' -f2)

  if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    count=1
  fi

  url="https://${TMON_IP}/deal/${deal_id}"
  id=$(echo -n "$url" | md5sum | cut -d ' ' -f1)
  output_path="${TMP_OUTPUT_DIR}/image_${id}.jpg"
 #output_path="${OUTPUT_DIR}/image_${id}.jpg"

  # 🔧 고정 IP 가정 → 연결 확인 및 재갱신 생략
  # nc -z -w 2 "$TMON_IP" 80
  # if [ $? -ne 0 ]; then
  #   echo "⚠️ netcat 연결 실패 → IP 재갱신 및 재큐잉"
  #   TMON_IP=$(resolve_ip)
  #   last_resolve_time=$(date +%s)
  #   redis-cli LPUSH queue:urls "${deal_id}|${count}"
  #   continue
  # fi

  START=$(date +%s)
  echo "▶️ [$count 회차] 처리 중: $url"

  wkhtmltoimage \
    --width 860 \
    --height 700 \
    --disable-javascript \
    --javascript-delay 0 \
    --load-error-handling ignore \
    --custom-header Host "$TMON_HOST" \
    --zoom 0.75 \
    --minimum-font-size 10 \
	--cache-dir "$WKHTML_CACHE_DIR" \
    "$url" "$output_path"

  result=$?

  END=$(date +%s)
  DURATION=$((END - START))

  if [ "$result" -ne 0 ]; then
    ((count++))
    echo "[RETRY] 실패 $count 회차 → 재큐잉: $url (${DURATION}초)" | tee -a "$LOG_DIR/error.log"
    redis-cli LPUSH queue:urls "${deal_id}|${count}"
    continue
  fi

  echo "✅ 저장 완료: $url (${DURATION}초)" | tee -a "$LOG_DIR/success.log"
done

