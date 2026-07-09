# 05 · MERGE — 프론트(배치) 값 우선 저장 + 채움 ≠ 확정

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**`MERGE` + `NVL` 프론트값 우선 / 시세 fallback, 적용여부(price_apply_yn) 불변**

공통코드 테이블을 항상 1행 드라이버로 두고 외부 시세 테이블을 `LEFT JOIN`해, 배치 데이터가 시세 테이블에 없어도 `USING` 서브쿼리가 0건이 되지 않게 했다. 가격/페이지는 프론트가 넘긴 배치 JSON 값을 우선하고 없을 때만 시세 fallback을 쓴다. 결정적으로 `MATCHED`에서 적용여부를 건드리지 않고 `INSERT`는 'N'으로 넣어, 자동적용/검색적용은 슬롯만 채우고 확정(선택 ✓ · 재료비단가)은 별도 경로로만 일어나게 정책을 저장 계층에서 강제한다.

```sql
MERGE INTO cost_estimate_unit_price t
USING (
  SELECT
    #{AGENCY_CD}      AS agency_cd,
    #{APPLY_YM}       AS apply_ym,
    #{PRICE_MGMT_NO}  AS price_mgmt_no,
    -- 프론트(배치 JSON) 값 우선, 미전달 시 시세 fallback
    -- → 엑셀 등 시세테이블에 없는 데이터소스도 저장된다
    NVL(TO_NUMBER(#{PRODUCT_PRICE,jdbcType=VARCHAR}), d.product_price) AS product_price,
    NVL(#{PAGE_VAL,jdbcType=VARCHAR}, d.page_val)                      AS page_val,
    c.code_nm
  FROM (
        SELECT code_nm
          FROM common_code
         WHERE code_class = 'AGENCY'
           AND common_cd = #{AGENCY_CD}
       ) c
       LEFT JOIN price_data d
         ON  d.agency_cd     = #{AGENCY_CD}
         AND d.apply_ym      = #{APPLY_YM}
         AND d.price_mgmt_no = #{PRICE_MGMT_NO}
) x
ON (   t.work_item_no = #{WORK_ITEM_NO}
   AND t.resource_cd  = #{RESOURCE_CD}
   AND t.exam_tp_cd   = #{AGENCY_CD})
WHEN MATCHED THEN UPDATE SET
  t.material_unit_price = x.product_price,
  t.remark             = x.page_val,
  t.delivery_cond_cd   = #{DELIVERY_COND_CD},
  t.match_score        = NVL(#{MATCH_SCORE,jdbcType=DECIMAL}, t.match_score),
  t.match_step_nm      = #{MATCH_STEP_NM}
  -- price_apply_yn 미설정: 슬롯 채움은 적용기관(✓)을 바꾸지 않는다 (채움 ≠ 확정)
WHEN NOT MATCHED THEN INSERT (
  work_item_no, resource_cd, exam_tp_cd, agency_cd, apply_ym, price_mgmt_no,
  material_unit_price, remark, delivery_cond_cd, match_score, match_step_nm,
  price_apply_yn
) VALUES (
  #{WORK_ITEM_NO}, #{RESOURCE_CD}, #{AGENCY_CD}, #{AGENCY_CD}, #{APPLY_YM}, #{PRICE_MGMT_NO},
  x.product_price, x.page_val, #{DELIVERY_COND_CD}, #{MATCH_SCORE,jdbcType=DECIMAL}, #{MATCH_STEP_NM},
  'N'  -- 신규 슬롯도 미확정으로 삽입
);
```
