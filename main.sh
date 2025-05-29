#!/bin/bash

BASE_DIR="$HOME/tmon-capture"
OUTPUT_DIR="$BASE_DIR/images"
LOG_DIR="$BASE_DIR/logs"


mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

# 시작 시 copy-worker 백그라운드 실행
#bash copy-worker.sh &
#COPY_PID=$!

mountpoint -q "$OUTPUT_DIR" || mount -t tmpfs -o size=2G tmpfs "$OUTPUT_DIR"

NUM_WORKERS=$(( $(nproc) * 2 ))

echo "🧵 시작: 병렬 worker $NUM_WORKERS 개 실행"
START_TS=$(date +%s)
for i in $(seq 1 "$NUM_WORKERS"); do
  bash worker.sh &
done

wait

#kill $COPY_PID

END_TS=$(date +%s)
TOTAL_TIME=$((END_TS - START_TS))

echo "⏱ 전체 처리 시간: $((END_TS - START_TS))초" | tee -a "$LOG_DIR/total_time.log"
