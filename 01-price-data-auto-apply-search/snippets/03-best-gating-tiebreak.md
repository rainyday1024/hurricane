# 03 · 매칭 best 게이팅 + 결정적 tie-break

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**신뢰도 게이팅 + 점수 → 지역 일치 → 최저가 tie-break, 점수 클램프**

자동확정 위험을 통제하는 핵심 로직이다. 적용에 필요한 키(기관코드·단가관리번호)가 완비된 후보만 남기고, 최고 점수가 임계(applyMin) 미만이면 아예 적용하지 않는다. 동점일 때는 공사 지역과 일치하는 조사처를 우선하고 그 안에서 최저가를 고르는 결정적 규칙이라 재현 가능하다. 저장 시 점수는 DB 스케일(0~100)로 클램프해 `NUMBER(5,2)` 오버플로를 막는다.

```java
private Map<String, Object> pickBestForAutoMap(List<Map<String, Object>> list, String preferredLocn) {
    // 1) 적용키 완비 후보만
    List<Map<String, Object>> cands = new ArrayList<>();
    for (Map<String, Object> row : list) {
        if (!nz(row.get("AGENCY_CD")).isEmpty() && !nz(row.get("PRICE_MGMT_NO")).isEmpty()) {
            cands.add(row);
        }
    }
    if (cands.isEmpty()) return null;

    // 2) 게이팅: 최고 점수가 임계 미달 → 미적용
    double top = cands.stream().mapToDouble(this::candScore).max().getAsDouble();
    if (top < autoMapApplyMinScore) return null;

    List<Map<String, Object>> topGroup = filterByScore(cands, top);

    // 3a) 동률 시 지역명 일치 우선
    if (preferredLocn != null && !preferredLocn.isEmpty()) {
        List<Map<String, Object>> matched = filterByLocn(topGroup, preferredLocn);
        if (!matched.isEmpty()) topGroup = matched;
    }

    // 3b) 그 안에서 최저가
    Map<String, Object> best = null;
    double bestPrice = Double.MAX_VALUE;
    for (Map<String, Object> c : topGroup) {
        double p = toDouble(c.get("PRODUCT_PRICE_NUM"));
        if (p <= 0) p = toDouble(c.get("PRODUCT_PRICE"));
        if (p > 0 && p < bestPrice) { bestPrice = p; best = c; }
    }
    return best != null ? best : topGroup.get(0);
}

// 저장 시: matchScore = normalizeMatchScore(rawScore) // 0~100 클램프 → NUMBER(5,2) 오버플로 방지
private double normalizeMatchScore(double raw) {
    return Math.max(0d, Math.min(100d, raw));
}
```
