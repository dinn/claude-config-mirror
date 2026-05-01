# claude-config-mirror

`~/.claude/CLAUDE.md` 의 화이트리스트 섹션만 추출해 보관하는 private 미러. Anthropic 클라우드 routine이 매월 1회 이 미러를 fetch해 정합성을 감사한다.

## 동작

1. `wl-sections.txt` — 미러할 H2 헤더 목록 (예: `## LLM 코딩 가드레일`)
2. `extract.sh` — `~/.claude/CLAUDE.md` 를 읽어 WL 섹션만 추출 → `CLAUDE.md` 에 쓰고 push

WL에 등록된 H2만 미러에 포함. 등록되지 않은 H2는 silently 제외. 별도 denylist는 운영하지 않는다 — denylist 자체가 섹션 이름을 노출시키므로.

## 가드 (push 전)

1. source(`~/.claude/CLAUDE.md`)·`wl-sections.txt` 존재
2. 원격 repo visibility가 PRIVATE — 아니면 push 거부

WL에 등록된 헤더가 source에 없어도 거부하지 않음. 그 섹션이 미러에 포함되지 않을 뿐.

가드 위반 시 macOS notification 발송.

## 트리거

- Claude Code `PostToolUse` 훅 (`~/.claude/CLAUDE.md` 편집 시) → `extract.sh` 자동 실행
- 수동: `./extract.sh`

## 매월 감사

매월 1일 09:00 KST, Anthropic 클라우드 routine이 `CLAUDE.md` raw를 fetch해 다음을 평가:
- Claude Code 기본 시스템 프롬프트와의 dilution
- 새 모델·CLI 행동 변경에 의한 무력화
- last commit date 기반 staleness

권고 있을 때만 알림, 없으면 heartbeat 한 줄.
