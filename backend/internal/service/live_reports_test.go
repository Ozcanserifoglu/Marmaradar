package service

import (
	"testing"
	"time"
)

func TestResolveLiveSettlementState_ExactThresholds(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	future := now.Add(time.Minute)

	state, settle := resolveLiveSettlementState(liveConfirmThreshold, future, now, false)
	if !settle || state != "confirmed" {
		t.Fatalf("confirm threshold should settle confirmed, got state=%q settle=%v", state, settle)
	}

	state, settle = resolveLiveSettlementState(liveRejectThreshold, future, now, false)
	if !settle || state != "rejected" {
		t.Fatalf("reject threshold should settle rejected, got state=%q settle=%v", state, settle)
	}
}

func TestResolveLiveSettlementState_ExpiryPaths(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	expired := now.Add(-time.Second)

	cases := []struct {
		name        string
		score       float64
		wantState   string
		wantSettled bool
	}{
		{name: "expired positive score confirms", score: 0.2, wantState: "confirmed", wantSettled: true},
		{name: "expired negative score rejects", score: -0.2, wantState: "rejected", wantSettled: true},
		{name: "expired zero score expires", score: 0, wantState: "expired", wantSettled: true},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			state, settled := resolveLiveSettlementState(tc.score, expired, now, true)
			if settled != tc.wantSettled || state != tc.wantState {
				t.Fatalf("score=%f got state=%q settled=%v want state=%q settled=%v",
					tc.score, state, settled, tc.wantState, tc.wantSettled)
			}
		})
	}
}

func TestResolveLiveSettlementState_NoSettleWhenPendingAndNotExpired(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	future := now.Add(10 * time.Minute)
	state, settled := resolveLiveSettlementState(0.1, future, now, true)
	if settled || state != "" {
		t.Fatalf("expected no settlement, got state=%q settled=%v", state, settled)
	}
}

func TestLiveReporterXPDelta(t *testing.T) {
	t.Parallel()

	if got := liveReporterXPDelta("confirmed"); got != 40 {
		t.Fatalf("confirmed xp delta mismatch: %d", got)
	}
	if got := liveReporterXPDelta("rejected"); got != -10 {
		t.Fatalf("rejected xp delta mismatch: %d", got)
	}
	if got := liveReporterXPDelta("expired"); got != 0 {
		t.Fatalf("expired xp delta mismatch: %d", got)
	}
}
