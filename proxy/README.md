# bookmarker-proxy

BookMarker 앱과 YES24 Open API 사이의 중계 서버(Cloudflare Worker)입니다.

YES24는 API Key를 앱 바이너리에 넣지 말고 서버에서만 보관하도록 요구합니다. 그래서 앱은 이 Worker 주소만 호출하고, Worker가 Key를 붙여 YES24에 대신 요청합니다.

```
앱 ──▶ Worker (Key 보관, 허용 경로만 통과, 응답 캐싱) ──▶ YES24
```

## 경로

| Worker 경로 | YES24 API | 캐시 |
| --- | --- | --- |
| `/bestseller` | `/v1/category/bestseller` | 1시간 |
| `/newproduct` | `/v1/category/newproduct` | 1시간 |
| `/newproductAttention` | `/v1/category/newproductAttention` | 1시간 |
| `/search` | `/v1/goods/itemList` | 10분 |
| `/detail` | `/v1/goods/itemDetail` | 1일 |
| `/categories` | `/v1/category/list` | 1일 |

쿼리 파라미터(`query`, `categoryId`, `page`, `pageSize` 등)는 그대로 YES24에 전달됩니다.

## 명령어

```bash
npm install                                  # 처음 한 번
npx wrangler login                           # 처음 한 번 (브라우저에서 Allow)
npx wrangler deploy                          # 코드를 고칠 때마다
npx wrangler secret put YES24_API_KEY        # Key 등록 (처음 한 번, Key를 바꿀 때)
```
