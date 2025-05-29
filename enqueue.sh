#!/bin/bash

URL_FILE="urls.txt"
# Redis 큐 초기화
redis-cli DEL queue:urls

# URL 목록을 Redis 큐에 삽입
cat urls.txt | while read url; do
  redis-cli LPUSH queue:urls "$url"
done

echo "✅ 작업 큐 등록 완료"
echo "$COUNT"  # main.sh에서 사용할 수 있게 출력
