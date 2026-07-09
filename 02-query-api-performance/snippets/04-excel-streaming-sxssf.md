# 04. SXSSFWorkbook + MyBatis ResultHandler 엑셀 스트리밍

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**커서 스트리밍 + 상수 메모리 엑셀.**

전체 결과를 `List`로 받지 않고 MyBatis `ResultHandler`로 커서를 흘리면서 즉시 `SXSSF` 시트에 쓴다. `SXSSFWorkbook`은 슬라이딩 윈도우(100행)만 힙에 두고 나머지를 임시파일로 내리므로, 행 수와 무관하게 힙 사용이 일정하다. `dispose()`로 임시파일을 반드시 회수한다. `fetchSize=1000`으로 DB 라운드트립도 줄인다.

```java
try (SXSSFWorkbook wb = new SXSSFWorkbook(100)) {   // 메모리 100행만, 나머지 디스크 flush
    SXSSFSheet sheet = wb.createSheet("단가목록");

    // 헤더/스타일 준비 (ExcelGridUtil.getHeaderStyle / getNumberStyle ...)
    CellStyle centerStyle = ExcelGridUtil.getCenterStyle(wb);
    CellStyle numberStyle = ExcelGridUtil.getNumberStyle(wb);
    final int[] rowNum = { 1 };

    ResultHandler<Map<String, Object>> handler = ctx -> {
        Map<String, Object> r = (Map<String, Object>) ctx.getResultObject();
        SXSSFRow row = sheet.createRow(rowNum[0]++);
        ExcelGridUtil.createStyledCell(row, 0, rowNum[0] - 1, centerStyle);
        ExcelGridUtil.createStyledCell(row, 5, toDouble(r.get("materialPrice")), numberStyle);
        // ... 나머지 컬럼
    };

    standardPriceMapper.getResourcePriceListForExcel(param, handler);  // fetchSize=1000 커서

    response.setContentType(
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    wb.write(response.getOutputStream());
} finally {
    // try-with-resources close() 이후 임시파일 정리
    // (명시적 dispose 필요 시) wb.dispose();
}
```

엑셀용 SQL은 페이징 없이 전체를 인라인뷰 조인으로 한 번에 흘려보낸다. 조회와 셀 기록이 동시에 진행되므로 대용량에서도 힙이 튀지 않는다.
