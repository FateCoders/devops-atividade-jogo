extends Button

const ICON_UNLOCKED = preload("res://Assets/Sprites/Exported/HUD/Icons/star-on-icon.png")
const ICON_LOCKED = preload("res://Assets/Sprites/Exported/HUD/Icons/star-off-icon.png")

@onready var custom_tooltip = $CustomTooltip
@onready var tooltip_timer = $TooltipTimer

var achievement_data: Dictionary

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

func set_data(data: Dictionary):
	achievement_data = data
	text = "" 
	
	var tooltip_data = data.get("tooltip_data", {})
	
	if data.get("unlocked", false):
		icon = load(tooltip_data.get("icon", ICON_UNLOCKED.resource_path))
		disabled = false
	else:
		icon = ICON_LOCKED
		disabled = true

# --- Lógica do Tooltip ---
func _on_mouse_entered():
	tooltip_timer.start()

func _on_mouse_exited():
	tooltip_timer.stop()
	custom_tooltip.hide_tooltip()

func _on_tooltip_timer_timeout():
	var tooltip_data = achievement_data.get("tooltip_data", {})
	
	var final_tooltip_info = {
		"icon": tooltip_data.get("icon")
	}

	if achievement_data.get("unlocked", false):
		final_tooltip_info["tooltip"] = tooltip_data.get("tooltip", "Concluído!")
	else:
		final_tooltip_info["tooltip"] = tooltip_data.get("locked_tooltip", "???")

	custom_tooltip.show_tooltip(final_tooltip_info)
