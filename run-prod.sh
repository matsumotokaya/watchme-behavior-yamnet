#!/bin/bash

# ECR設定
ECR_REGISTRY="754724220380.dkr.ecr.ap-southeast-2.amazonaws.com"
ECR_REPOSITORY="watchme-api-behavior-features"
IMAGE_TAG="latest"
REGION="ap-southeast-2"

# カラー出力設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Sound Event Detection API - 本番デプロイ開始${NC}"
echo "=================================="

# 1. ECRにログイン
echo -e "\n${YELLOW}📝 ECRにログイン中...${NC}"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECRログインに失敗しました${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ECRログイン成功${NC}"

# 2. 最新イメージをプル
echo -e "\n${YELLOW}📥 最新イメージをプル中...${NC}"
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ イメージプルに失敗しました${NC}"
    exit 1
fi
echo -e "${GREEN}✅ イメージプル成功${NC}"

# 3. 既存コンテナを停止
echo -e "\n${YELLOW}🛑 既存コンテナを停止中...${NC}"
docker-compose -f docker-compose.prod.yml down
echo -e "${GREEN}✅ 既存コンテナ停止完了${NC}"

# 4. 新しいコンテナを起動
echo -e "\n${YELLOW}🚀 新しいコンテナを起動中...${NC}"
docker-compose -f docker-compose.prod.yml up -d
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ コンテナ起動に失敗しました${NC}"
    exit 1
fi
echo -e "${GREEN}✅ コンテナ起動成功${NC}"

# 5. ヘルスチェック
echo -e "\n${YELLOW}🏥 ヘルスチェック中...${NC}"
sleep 5
for i in {1..10}; do
    if curl -f http://localhost:8004/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ヘルスチェック成功${NC}"
        break
    else
        if [ $i -eq 10 ]; then
            echo -e "${RED}❌ ヘルスチェック失敗${NC}"
            echo -e "${YELLOW}ログを確認してください:${NC}"
            docker-compose -f docker-compose.prod.yml logs --tail=50
            exit 1
        fi
        echo -e "${YELLOW}待機中... ($i/10)${NC}"
        sleep 3
    fi
done

# 6. デプロイ完了
echo -e "\n${GREEN}=================================="
echo -e "🎉 デプロイが正常に完了しました！"
echo -e "==================================\n"
echo -e "コンテナ状態:"
docker-compose -f docker-compose.prod.yml ps
echo -e "\n外部URL: https://api.hey-watch.me/behavior-features/"
echo -e "\nログ確認:"
echo -e "  ${YELLOW}docker-compose -f docker-compose.prod.yml logs -f${NC}"