class_name ShopItem extends Resource

## Items and buffs purchasable in the shop between shifts.

enum ItemType {
	LUCK_BOOST,            # Increases chances of positive outcome rolls
	EXTRA_DIALOGUE_SLOT,   # Expands available dialogue choices per turn (from 2 up to 4)
	HANGUP_PROTECTION,     # Protects from 1 instant hang-up per day
	QUOTA_DISCOUNT,        # Lowers today's quota requirement
	PERSUASION_STARTER,    # Starts every call with +20% initial persuasion
	SPECIAL_PERK           # Unlocks rare dialogue approaches
}

@export var id: String = ""
@export var item_name: String = "Крепкий офисный кофе"
@export_multiline var description: String = "Повышает концентрацию Геральта. +20% к удаче при бросках диалогов."
@export var cost: int = 500
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.LUCK_BOOST
@export var effect_value: float = 0.2
@export var is_consumed_on_use: bool = false
@export var is_permanent: bool = true

## Game Jam Theme annotation
@export var jam_theme_tag: String = "Побочный эффект"
@export var side_effect_text: String = "Может вызывать тремор пальцев и ускорение разговора."

