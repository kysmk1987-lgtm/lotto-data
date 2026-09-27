# lotto-data

로또 6/45 당첨 이력과 통계 기반 추천 결과를 담은 **데이터 전용** 공개 저장소입니다.
분석 코드는 비공개 저장소에서 매주 자동 실행되어 이 저장소의 JSON 파일을 갱신합니다.

> ⚠️ **면책 고지**: 본 추천은 과거 통계 기반 참고용이며 당첨을 보장하지 않습니다.
> 로또 추첨은 매 회 독립적인 무작위 시행으로, 과거 결과는 미래 결과에 영향을 주지 않습니다.
> 백테스트에서도 추천 방식은 무작위 선택보다 나은 성과를 보이지 않았습니다(`recommendations.json` 의 `backtest` 참조).
> 당첨번호 원자료의 출처는 동행복권(dhlottery.co.kr)이며, 정확한 정보는 공식 사이트에서 확인하세요.

## 파일

| 파일 | 내용 | URL |
|---|---|---|
| `history.json` | 1회부터 최신 회차까지 전체 당첨번호 (최신 회차가 먼저) | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/history.json |
| `recommendations.json` | 다음 회차 추천 5게임, 번호별 점수, 백테스트 결과 | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/recommendations.json |
| `analysis.json` | 마르코프 전이행렬·몬테카를로, A/B/C 그룹 구성, 지아넬라 패턴, 각종 통계(관측 vs 이론), 무작위성 검정, 방법별 백테스트, N게임 커버리지/휠링 | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/analysis.json |

## 갱신 주기

매주 토요일 21:00 KST(추첨 직후)에 갱신을 시도하고, 결과 게시가 늦어지면 토 23:00, 일 09:00, 월 09:00 KST 에 재시도합니다.
내용이 바뀐 경우에만 커밋됩니다.

## history.json (schema_version 1)

```json
{
  "schema_version": 1,
  "generated_at": "2026-09-27T21:00:00+09:00",
  "latest_round": 1243,
  "draws": [
    {"round": 1243, "date": "2026-09-26", "numbers": [9, 18, 24, 38, 43, 44], "bonus": 35,
     "first_prize_amount": 2592525282, "first_winners": 12}
  ]
}
```

- `draws`: 1회~`latest_round` 전 회차, 회차 **내림차순**
- `numbers`: 본번호 6개 오름차순, `bonus`: 보너스 번호
- `first_prize_amount`: 1등 1인당 당첨금(원), `first_winners`: 1등 당첨자 수.
  원자료에 없으면 `null`, 1등 당첨자가 없던 회차(이월)는 둘 다 `0`

## recommendations.json (schema_version 1)

`schema_version`, `generated_at`, `target_round`, `last_round`, `games`(5게임), `number_scores`(1~45),
`backtest`, `disclaimer` 로 구성됩니다. 키 구조는 앱과의 계약이므로 변경되지 않습니다.
기존 키 뒤에 선택 필드 `method`(추천 기준 방법과 선택 이유)가 추가될 수 있습니다.

## analysis.json (schema_version 1)

최상위 키: `schema_version`, `generated_at`, `target_round`, `last_round`, `recommendation_method`, `markov`, `grouping`,
`gianella`, `stats_catalog`, `randomness`, `backtest`, `portfolio`, `disclaimer`.
모든 이론 분포는 8,145,060개 조합 전수 열거로 계산한 정확한 값이며, 각 섹션에는 p-값과 한국어 해석이 함께 들어 있습니다.
이 분석은 과거 데이터의 서술과 검증일 뿐이며, 방법별 백테스트에서 어느 방법도 무작위보다 유의하게 낫지 않았습니다.
