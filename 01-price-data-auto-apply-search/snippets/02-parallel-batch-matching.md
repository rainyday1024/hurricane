# 02 · distinct 키 dedup + 8스레드 병렬 매칭 (stateless 자동매핑)

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**`ExecutorService` 고정 풀 + `ConcurrentHashMap` 수집 후 단일스레드 fill**

자재 1건당 배치 호출이 앱서버 → NLP 서버 왕복으로 1~2.5초 걸려 순차 처리 시 수십 초가 든다. 동일 (품명·규격·단위·월) 키를 dedup한 뒤 8스레드로 병렬화하고, 수집은 `ConcurrentHashMap`, DB 쓰기는 단일 스레드에서 단건 try-catch로 수행해 한 건 실패가 트랜잭션 전체를 롤백하지 않게 했다. 현가화 재매칭도 동일 패턴을 쓴다.

```java
// distinct (품명|규격|단위|발행월) 키로 중복 배치 호출 제거.
// 연속 공백 제거(배치가 연속 공백을 정규화하지 않음).
LinkedHashMap<String, String[]> keyToReq = new LinkedHashMap<>();
for (Map<String, Object> r : targets) {
    String item = nz(r.get("ITEM_NM")).replaceAll("\\s{2,}", "");
    String spec = nz(r.get("SPEC_NM"));
    String unit = nz(r.get("UNIT"));
    String ym   = nz(r.get("APPLY_YM"));
    String locn = nz(r.get("REGION_NM"));
    String key  = item + "|" + spec + "|" + unit + "|" + ym;
    keyToReq.putIfAbsent(key, new String[]{item, spec, unit, ym, locn});
}

final Map<String, Map<String, Object>> bestByKey = new ConcurrentHashMap<>();
ExecutorService pool = Executors.newFixedThreadPool(
        Math.min(8, Math.max(1, keyToReq.size())));
try {
    List<Future<?>> futures = new ArrayList<>();
    for (Map.Entry<String, String[]> e : keyToReq.entrySet()) {
        String[] q = e.getValue();
        futures.add(pool.submit(() -> {
            Map<String, Object> best = matchBestBySearch(q[0], q[1], q[2], q[3], q[4]); // /searchItem 1회
            if (best != null) bestByKey.put(e.getKey(), best);
        }));
    }
    for (Future<?> f : futures) {
        try { f.get(600, TimeUnit.SECONDS); }
        catch (Exception ex) { log.warn("match task failed: {}", ex.toString()); }
    }
} finally {
    pool.shutdownNow();
}

// 이후 단일 스레드에서 각 자재 행에 bestByKey 적용 → 자기 DB 저장 (단건 try-catch)
for (Map<String, Object> r : targets) {
    Map<String, Object> best = bestByKey.get(keyOf(r));
    if (best == null) continue;
    try {
        saveEstimateUnitPrice(toSaveParam(r, best)); // 자기 datasource 에만 기록
    } catch (Exception ex) {
        log.warn("save failed for {}: {}", r.get("ITEM_NM"), ex.toString());
    }
}
```
