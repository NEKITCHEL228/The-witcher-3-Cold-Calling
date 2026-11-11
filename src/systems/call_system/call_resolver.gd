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

static func get_outcome_probabilities(option: DialogueOption, monster: MonsterData, player_luck: float, item_multiplier: float = 1.0) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if option.possible_outcomes.is_empty():
		return results

	var total_base_w: float = 0.0
	var total_eff_w: float = 0.0
	var effective_luck: float = player_luck * item_multiplier

	# 1. Calculate base and effective weights
	var outcome_weights: Array[Dictionary] = []
	for out in option.possible_outcomes:
		var eff_w: float = out.base_weight
		var trait_mul: float = _calculate_trait_multiplier(option.approach_tag, monster, out.persuasion_delta >= 0.0)
		eff_w *= trait_mul

		if out.persuasion_delta > 0.0:
			eff_w *= (1.0 + maxf(0.0, effective_luck))
		elif out.persuasion_delta < 0.0:
			eff_w *= maxf(0.2, 1.0 - (effective_luck * 0.5))

		eff_w = maxf(1.0, eff_w)
		total_base_w += out.base_weight
		total_eff_w += eff_w
		outcome_weights.append({
			"outcome": out,
			"base_w": out.base_weight,
			"eff_w": eff_w
		})

	if total_base_w <= 0.0: total_base_w = 1.0
	if total_eff_w <= 0.0: total_eff_w = 1.0

	# 2. Compute percentages and modifier strings: e.g. "66% (+16%)"
	for item in outcome_weights:
		var out: DialogueOutcome = item["outcome"]
		var base_pct: int = int(round(item["base_w"] / total_base_w * 100.0))
		var eff_pct: int = int(round(item["eff_w"] / total_eff_w * 100.0))
		var diff: int = eff_pct - base_pct
		
		var mod_parts: Array[String] = []
		if diff > 0:
			mod_parts.append("+%d%%" % diff)
		elif diff < 0:
			mod_parts.append("%d%%" % diff)
		
		if item_multiplier > 1.05 or item_multiplier < 0.95:
			mod_parts.append("x%.1f" % item_multiplier)

		var mod_str: String = ""
		if not mod_parts.is_empty():
			mod_str = " (%s)" % "; ".join(mod_parts)

		results.append({
			"outcome": out,
			"base_pct": base_pct,
			"effective_pct": eff_pct,
			"diff": diff,
			"mod_str": mod_str,
			"concrete_text": out.get_concrete_effect_text()
		})

	return results

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
