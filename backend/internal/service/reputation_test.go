package service

import (
	"testing"

	"github.com/google/uuid"
)

func TestRankForXPThresholds(t *testing.T) {
	t.Parallel()

	cases := []struct {
		name     string
		xp       int64
		wantCode string
	}{
		{name: "below first threshold", xp: 499, wantCode: "caylak"},
		{name: "exact gozcu threshold", xp: 500, wantCode: "gozcu"},
		{name: "exact yolun_hakimi threshold", xp: 1500, wantCode: "yolun_hakimi"},
		{name: "exact radar_avcisi threshold", xp: 4000, wantCode: "radar_avcisi"},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got := rankForXP(tc.xp)
			if got.Code != tc.wantCode {
				t.Fatalf("rankForXP(%d)=%s want %s", tc.xp, got.Code, tc.wantCode)
			}
		})
	}
}

func TestNextRankForXP(t *testing.T) {
	t.Parallel()

	next := nextRankForXP(1499)
	if next == nil || next.Code != "yolun_hakimi" {
		t.Fatalf("nextRankForXP(1499) mismatch: %#v", next)
	}

	top := nextRankForXP(99999)
	if top != nil {
		t.Fatalf("nextRankForXP top level should be nil, got %#v", top)
	}
}

func TestReputationEventKeysDeterministic(t *testing.T) {
	t.Parallel()

	reportID := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	userID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	driveID := uuid.MustParse("33333333-3333-3333-3333-333333333333")

	if a, b := reputationEventKeyDrive(driveID), reputationEventKeyDrive(driveID); a != b {
		t.Fatalf("drive event keys should match: %q vs %q", a, b)
	}
	if a, b := reputationEventKeyLiveVote(reportID, userID), reputationEventKeyLiveVote(reportID, userID); a != b {
		t.Fatalf("live vote event keys should match: %q vs %q", a, b)
	}
	if a, b := reputationEventKeyCrowdVoteUp(7, userID), reputationEventKeyCrowdVoteUp(7, userID); a != b {
		t.Fatalf("crowd vote event keys should match: %q vs %q", a, b)
	}
}

func TestReputationEventKeysDifferentInputs(t *testing.T) {
	t.Parallel()

	reportA := uuid.MustParse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
	reportB := uuid.MustParse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")
	userA := uuid.MustParse("cccccccc-cccc-cccc-cccc-cccccccccccc")
	userB := uuid.MustParse("dddddddd-dddd-dddd-dddd-dddddddddddd")

	if reputationEventKeyLiveVote(reportA, userA) == reputationEventKeyLiveVote(reportA, userB) {
		t.Fatal("different users must not share same live vote event key")
	}
	if reputationEventKeyLiveSettleReporter(reportA) == reputationEventKeyLiveSettleReporter(reportB) {
		t.Fatal("different reports must not share same reporter settlement key")
	}
}

func TestEloDeltaForOutcome(t *testing.T) {
	t.Parallel()

	winDelta := eloDeltaForOutcome(1000, true)
	lossDelta := eloDeltaForOutcome(1000, false)
	if winDelta <= 0 {
		t.Fatalf("expected positive win delta, got %f", winDelta)
	}
	if lossDelta >= 0 {
		t.Fatalf("expected negative loss delta, got %f", lossDelta)
	}
	if winDelta+lossDelta > 0.0001 || winDelta+lossDelta < -0.0001 {
		t.Fatalf("expected roughly symmetric deltas, got win=%f loss=%f", winDelta, lossDelta)
	}
}
