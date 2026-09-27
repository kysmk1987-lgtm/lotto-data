# lotto-data

로또 6/45 당첨 이력과 통계 기반 추천 결과를 담은 **데이터 전용** 공개 저장소입니다.
분석 코드는 비공개 저장소에서 매주 자동 실행되어 이 저장소의 JSON 파일을 갱신합니다.

> ⚠️ **면책 고지**: 본 추천은 과거 통계 기반 참고용이며 당첨을 보장하지 않습니다.
> 로또 추첨은 매 회 독립적인 무작위 시행으로, 과거 결과는 미래 결과에 영향을 주지 않습니다.
> 백테스트에서도 추천 방식은 무작위 선택보다 나은 성과를 보이지 않았습니다(`recommendations.json` 의 `backtest` 참조).
> 당첨번호·당첨금·판매점 원자료의 출처는 동행복권(dhlottery.co.kr)이며, 정확한 정보는 공식 사이트에서 확인하세요.

## 파일

| 파일 | 내용 | URL |
|---|---|---|
| `history.json` | 1회부터 최신 회차까지 전체 당첨번호, 1~5등 당첨금·당첨자 수, 총판매액 (최신 회차가 먼저) | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/history.json |
| `recommendations.json` | 다음 회차 추천 세트(5/10/20게임, 4등 이상 목표), 번호별 점수, 적합도 규칙, 백테스트 결과 | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/recommendations.json |
| `stores.json` | 1·2등 당첨 판매점(262회부터), 좌표, 당첨 회차·방식 | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/stores.json |
| `analysis.json` | 내부 검토용 분석 보고서(마르코프, 그룹, 지아넬라, 통계, 무작위성 검정, 방법별·세트 전략 백테스트) | https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/analysis.json |

`stores.json` 이 8MB 를 넘으면 `stores_index.json`(당첨 목록 제외 + `bucket`)과 `stores_wins/{00..63}.json` 도 함께 배포됩니다.

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
     "first_prize_amount": 2592525282, "first_winners": 12,
     "prizes": [{"rank": 1, "amount": 2592525282, "winners": 12}, {"rank": 2, "amount": 45087397, "winners": 115},
                {"rank": 3, "amount": 1443902, "winners": 3591}, {"rank": 4, "amount": 50000, "winners": 174306},
                {"rank": 5, "amount": 5000, "winners": 2853501}],
     "total_sales": 128926419000}
  ]
}
```

- `draws`: 1회~`latest_round` 전 회차, 회차 **내림차순**
- `numbers`: 본번호 6개 오름차순, `bonus`: 보너스 번호
- `first_prize_amount`: 1등 1인당 당첨금(원), `first_winners`: 1등 당첨자 수.
  원자료에 없으면 `null`, 1등 당첨자가 없던 회차(이월)는 둘 다 `0`
- `prizes`: 1~5등 `{rank, amount(1인당 원), winners}` — 값이 없으면 `null`. `total_sales`: 회차 총판매액(원)

## recommendations.json (schema_version 1)

`schema_version`, `generated_at`, `target_round`, `last_round`, `games`(5게임), `number_scores`(1~45),
`backtest`, `disclaimer` 로 구성됩니다. 키 구조는 앱과의 계약이므로 변경되지 않습니다.
기존 키 뒤에 선택 필드가 추가됩니다: `method`, `sets`(`"5"`/`"10"`/`"20"` 게임 세트, `games` == `sets["5"]`),
`set_strategies`, `constraints`(앱에서 적합도를 똑같이 계산하기 위한 규칙), `strategy`(한국어 설명).

## stores.json (schema_version 1)

`coverage`(`first_from_round`/`second_from_round` = 262, `third_available` = false), `note`, `stores[]`.
각 판매점: `id, name, address, region, lat, lng, phone, first, second, third(null), wins[[회차, 등위, 방식]]`(+ `online`, `status`).
`wins` 는 최신 회차 먼저, 판매점은 1등 횟수 → 2등 횟수 내림차순. 인터넷 판매점은 `lat`/`lng` 가 `null`.
3등 당첨 판매점은 동행복권이 공개하지 않습니다.

## analysis.json (schema_version 1)

최상위 키: `schema_version`, `generated_at`, `target_round`, `last_round`, `recommendation_method`, `markov`, `grouping`,
`gianella`, `stats_catalog`, `randomness`, `backtest`, `portfolio`, `ge4`, `disclaimer`.
모든 이론 분포는 8,145,060개 조합 전수 열거로 계산한 정확한 값이며, 각 섹션에는 p-값과 한국어 해석이 함께 들어 있습니다.
이 분석은 과거 데이터의 서술과 검증일 뿐이며, 방법별 백테스트에서 어느 방법도 무작위보다 유의하게 낫지 않았습니다.
