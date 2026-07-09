# 01. 물가 조인 키셋 세미조인 푸시다운 + 대표 1건 dedup

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**키셋 세미조인 푸시다운 + `ROW_NUMBER()` 최신 1건.**

수백만 행 규모의 물가 원본(`market_price_data`)을 직접 스캔하지 않고, 현재 화면이 실제 참조하는 `(기관, 발행월, 관리번호 앞16자리)` 키 집합을 먼저 만들어 `INNER JOIN`으로 밀어넣는다. 조인키 3컬럼이 복합 인덱스와 정확히 일치해 FULL SCAN이 아니라 `INDEX RANGE SCAN`으로 소수 행만 접근한다. 한 기관·월·자재에 여러 조사처 행이 있어도 `received_dt` 최신(`NULLS LAST`) 1건만 대표로 남긴다.

핵심 함정은 조인키가 자재코드가 아니라 **관리번호 문자열 앞 16자리 파생값**이라는 도메인 특성이다. 자재코드로 매칭하면 오답이 나온다.

```sql
LEFT JOIN (
  SELECT institution_code, publish_ym, price_key,
         product_name, spec_name, price_unit, page_no
    FROM (
      SELECT dd.institution_code,
             dd.publish_ym,
             dd.resource_code AS price_key,
             dd.product_name, dd.spec_name, dd.price_unit, dd.page_no,
             ROW_NUMBER() OVER (
               PARTITION BY dd.institution_code, dd.publish_ym, dd.resource_code
               ORDER BY dd.received_dt DESC NULLS LAST, dd.price_mgmt_no
             ) AS rn
        FROM market_price_data dd                     -- 수백만 행 (미가공 시 FULL SCAN)
        JOIN (                                          -- 현재 화면이 참조하는 키셋만
              SELECT DISTINCT
                     k.institution_code,
                     k.publish_ym,
                     SUBSTR(REPLACE(k.price_survey_no, '-', ''), 1, 16) AS price_key
                FROM cost_estimate_unit_price k
               WHERE k.work_unit_no = #{workUnitNo}
             ) ks
          ON  ks.institution_code = dd.institution_code
          AND ks.publish_ym       = dd.publish_ym
          AND ks.price_key        = dd.resource_code   -- 파생 조인키
    )
   WHERE rn = 1                                         -- 기관·월·자재별 최신 1건
) d
  ON  d.institution_code = e.institution_code
  AND d.publish_ym       = e.publish_ym
  AND d.price_key        = SUBSTR(REPLACE(e.price_survey_no, '-', ''), 1, 16)
```

조인키에 맞춘 복합 인덱스:

```sql
CREATE INDEX ix_price_data
    ON market_price_data (institution_code, publish_ym, resource_code);
-- 실행계획: FULL SCAN → INDEX RANGE SCAN (비용 대폭 감소, 조회 응답 수 초 → 1초 미만)
```

그리드 조회는 위 파생결과를 `GROUP BY`로 기관 슬롯을 `DECODE` 피벗해 한 행에 펼치고, 단건 패널 조회는 키셋 서브쿼리에 자재코드 조건을 추가해 좁힌다.
