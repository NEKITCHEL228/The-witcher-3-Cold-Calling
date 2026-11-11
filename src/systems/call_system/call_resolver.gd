class_name CallResolver extends RefCounted

## Resolves dice rolls, trait interactions, and player luck to pick dialogue outcomes.

static func resolve(option: DialogueOption, monster: MonsterData, player_luck: float) -> DialogueOutcome:
	if option.possible_outcomes.is_empty():
		var fallback := DialogueOutcome.new()
		fallback.outcome_title = "Неловкая пауза"
		fallback.monster_reaction_text = "Хм... И что вы замолчали?"
		fallback.persuasion_delta = 0.0
		return fallback

	var weighted_outcomes: Array[Dictionary] = []
	var total_weight: float = 0.0

	for outcome in option.possible_outcomes:
		var effective_weight: float = outcome.base_weight

		# 1. Trait interaction modifiers
		var trait_multiplier: float = _calculate_trait_multiplier(option.approach_tag, monster, outcome.persuasion_delta >= 0.0)
		effective_weight *= trait_multiplier

		# 2. Player luck modifier
		if outcome.persuasion_delta > 0.0:
			# Luck boosts positive persuasion chances
			effective_weight *= (1.0 + maxf(0.0, player_luck))
		elif outcome.persuasion_delta < 0.0:
			# Luck diminishes negative persuasion chances (clamped)
			effective_weight *= maxf(0.2, 1.0 - (player_luck * 0.5))

		# Ensure weight is always positive
		effective_weight = maxf(1.0, effective_weight)
		weighted_outcomes.append({
			"outcome": outcome,
			"weight": effective_weight
		})
		total_weight += effective_weight

	# 3. Roll random value
	var roll: float = randf_range(0.0, total_weight)
	var current_accumulator: float = 0.0

	for item in weighted_outcomes:
		current_accumulator += item["weight"]
		if roll <= current_accumulator:
			return item["outcome"]

	# Fallback to last outcome
	return weighted_outcomes.back()["outcome"]

static func _calculate_trait_multiplier(approach_tag: String, monster: MonsterData, is_positive_outcome: bool) -> float:
	var multiplier: float = 1.0

	for m_trait in monster.traits:
		if m_trait == null:
			continue
		
		# If monster trait is weak to this approach:
		if approach_tag in m_trait.weak_against_approaches:
			if is_positive_outcome:
				multiplier *= m_trait.affinity_multiplier
			else:
				multiplier /= maxf(1.1, m_trait.affinity_multiplier)

		# If monster trait is strong / resistant to this approach:
		if approach_tag in m_trait.strong_against_approaches:
			if is_positive_outcome:
				multiplier /= maxf(1.1, m_trait.affinity_multiplier)
			else:
				multiplier *= m_trait.affinity_multiplier

	return multiplier
