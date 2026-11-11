extends Node

## Global EventBus for "The Witcher 3: Cold Calling"
## Handles decoupled cross-scene signals.

# Call Lifecycle Signals
@warning_ignore("unused_signal")
signal call_started(monster: MonsterData)
@warning_ignore("unused_signal")
signal call_turns_changed(turns_left: int, delta: int)
@warning_ignore("unused_signal")
signal persuasion_changed(new_value: float, delta: float)
@warning_ignore("unused_signal")
signal dialogue_chosen(option: DialogueOption)
@warning_ignore("unused_signal")
signal outcome_resolved(outcome: DialogueOutcome, monster_reaction: String)
@warning_ignore("unused_signal")
signal call_finished(is_success: bool, loan_amount: int)

# Daily & Progression Signals
@warning_ignore("unused_signal")
signal day_started(day_number: int, calls_limit: int)
@warning_ignore("unused_signal")
signal day_ended(day_number: int, quota_met: bool, total_loan_issued: int)
@warning_ignore("unused_signal")
signal quota_updated(current_amount: int, target_amount: int)
@warning_ignore("unused_signal")
signal player_balance_changed(new_balance: int, delta: int)
@warning_ignore("unused_signal")
signal stat_changed(stat_name: String, new_value: Variant)

# Shop Signals
@warning_ignore("unused_signal")
signal item_purchased(item: ShopItem)

# UI Signals
@warning_ignore("unused_signal")
signal log_message_posted(text: String, color: Color)
