class_name QuotaManager extends RefCounted

## Manages financial quotas, shift targets, and Geralt's commission earnings.

const BASE_QUOTAS: Array[int] = [
	15000, # Day 1
	25000, # Day 2
	40000, # Day 3
	60000, # Day 4
	90000  # Day 5
]

const COMMISSION_RATE: float = 0.05 # 5% of issued loan becomes Geralt's cash

static func get_quota_for_day(day_index: int) -> int:
	var idx := clampi(day_index - 1, 0, BASE_QUOTAS.size() - 1)
	return BASE_QUOTAS[idx]

static func calculate_commission(loan_amount: int) -> int:
	return int(float(loan_amount) * COMMISSION_RATE)

static func is_quota_satisfied(current_total: int, day_index: int) -> bool:
	return current_total >= get_quota_for_day(day_index)

