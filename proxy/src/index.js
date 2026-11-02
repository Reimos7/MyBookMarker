// BookMarker 앱과 YES24 Open API 사이의 중계 서버 (Cloudflare Worker)
// YES24 API 키는 코드에 두지 않고 Cloudflare secret(YES24_API_KEY)에만 보관한다

const YES24_BASE_URL = "https://apis.yes24.com";

// 앱이 호출할 수 있는 경로만 허용: 앱 경로 → YES24 경로, 캐시 시간(초)
const ROUTES = {
  "/bestseller": { path: "/v1/category/bestseller", ttl: 60 * 60 },
  "/newproduct": { path: "/v1/category/newproduct", ttl: 60 * 60 },
  "/newproductAttention": { path: "/v1/category/newproductAttention", ttl: 60 * 60 },
  "/search": { path: "/v1/goods/itemList", ttl: 60 * 10 },
  "/detail": { path: "/v1/goods/itemDetail", ttl: 60 * 60 * 24 },
  "/categories": { path: "/v1/category/list", ttl: 60 * 60 * 24 },
};

export default {
  async fetch(request, env, ctx) {
    if (request.method !== "GET") {
      return json({ error: "Method not allowed" }, 405);
    }

    const url = new URL(request.url);
    const route = ROUTES[url.pathname];

    // 목록에 없는 경로는 거절 (Worker 주소를 다른 용도로 쓰지 못하게)
    if (!route) {
      return json({ error: "Not found" }, 404);
    }

    // secret을 아직 넣지 않았을 때 원인을 바로 알 수 있게
    if (!env.YES24_API_KEY) {
      return json({ error: "YES24_API_KEY secret이 설정되지 않았습니다." }, 500);
    }

    // 같은 요청은 저장해 둔 결과로 응답 (YES24 호출 한도 절약)
    const cache = caches.default;
    const cacheKey = new Request(url.toString());
    const cached = await cache.match(cacheKey);
    if (cached) {
      return withHeader(cached, "X-Cache", "HIT");
    }

    // 앱이 보낸 쿼리(검색어, 페이지 등)는 그대로 YES24에 전달하고, 키는 여기서 붙임
    const upstreamURL = new URL(route.path, YES24_BASE_URL);
    upstreamURL.search = url.search;

    const upstream = await fetch(upstreamURL, {
      headers: {
        "X-Api-Key": env.YES24_API_KEY,
        Accept: "application/json",
      },
    });

    const response = new Response(upstream.body, upstream);
    response.headers.delete("Set-Cookie");
    response.headers.set("X-Cache", "MISS");

    // 성공한 응답만 캐시에 저장
    if (upstream.ok) {
      response.headers.set("Cache-Control", `public, max-age=${route.ttl}`);
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }

    return response;
  },
};

function json(body, status) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function withHeader(response, name, value) {
  const copy = new Response(response.body, response);
  copy.headers.set(name, value);
  return copy;
}
