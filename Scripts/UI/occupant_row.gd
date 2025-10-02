# Scripts/UI/OccupantRow.gd
extends HBoxContainer

@onready var sprite: TextureRect = $TextureRect
@onready var label: Label = $Label

func set_npc_info(npc: NPC):
	if not is_instance_valid(npc):
		return
	sprite.texture = npc.get_idle_sprite_texture()
	label.text = npc.npc_name
