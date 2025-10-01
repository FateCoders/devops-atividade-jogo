# TradeOfferItem.gd
extends HBoxContainer

signal offer_accepted(item_node, offer_data)

# As referências continuam as mesmas.
@onready var description_label = $HBoxContainer/DescriptionLabel
@onready var accept_button = $AcceptButton

var offer_data: Dictionary

func _ready():
	accept_button.pressed.connect(_on_accept_pressed)
	pass
	
func set_data(data: Dictionary):
	offer_data = data
	description_label.text = data.get("description", "Oferta inválida")

func disable_offer():
	accept_button.disabled = true
	accept_button.text = "Concluído"
	
func _on_accept_pressed():
	emit_signal("offer_accepted", self, offer_data)
	
func update_after_trade():
	var available_day = WorldTimeManager.current_day + 5 
	accept_button.disabled = true
	accept_button.text = "Dia %d" % available_day
