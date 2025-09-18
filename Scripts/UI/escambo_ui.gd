# EscamboUI.gd
extends Control

const OfferItemScene = preload("res://Scenes/UI/EscamboItem.tscn")
@onready var offers_list_container = $PanelContainer/MarginContainer/VBoxContainer3/VBoxContainer/ScrollContainer/OffersListContainer
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer3/HBoxContainer/CloseButton
# ...

var target_quilombo_id: String

func _ready():
	close_button.pressed.connect(queue_free)

func start_trade(quilombo_id: String):
	target_quilombo_id = quilombo_id
	_populate_offers()

func _populate_offers():
	for child in offers_list_container.get_children():
		child.queue_free()
		
	var offers = QuilombosManager.get_all_quilombos()[target_quilombo_id].get("trade_offers", [])
	
	for offer_data in offers:
		var item = OfferItemScene.instantiate()
		offers_list_container.add_child(item)
		
		item.set_data(offer_data)
		
		item.offer_accepted.connect(_on_trade_offer_accepted)

func _on_trade_offer_accepted(item_node: HBoxContainer, offer_data: Dictionary):
	var offer_type = offer_data.get("type")
	var item = offer_data.get("item")
	var quantity = offer_data.get("quantity")
	var price = offer_data.get("price")
	
	if offer_type == "sell": # Nós vendemos para eles
		var cost = {item: quantity}
		if StatusManager.has_enough_resources(cost):
			StatusManager.mudar_status(item, -quantity)
			StatusManager.mudar_status("dinheiro", price)
			print("Venda realizada!")
			
			QuilombosManager.change_relation(target_quilombo_id, 5) # Aumenta a relação em 5
			QuilombosManager.set_offer_on_cooldown(target_quilombo_id, offer_data["id"])
			item_node.update_after_trade()
		else:
			print("Recursos insuficientes para vender.")
	
	elif offer_type == "buy": # Nós compramos deles
		var cost = {"dinheiro": price}
		if StatusManager.has_enough_resources(cost):
			StatusManager.mudar_status("dinheiro", -price)
			StatusManager.mudar_status(item, quantity)
			print("Compra realizada!")
			QuilombosManager.change_relation(target_quilombo_id, 5) # Aumenta a relação em 5
			QuilombosManager.set_offer_on_cooldown(target_quilombo_id, offer_data["id"])
			item_node.update_after_trade()
		else:
			print("Dinheiro insuficiente para comprar.")
