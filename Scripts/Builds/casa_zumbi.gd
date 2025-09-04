extends StaticBody2D
# Exporte a cena do HUD para poder arrastá-la no inspetor
@export var hud_cena: PackedScene

func _on_zona_de_entrada_input_event(viewport, event, shape_idx):
	print("Evento de input recebido.")
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Clique detectado na porta!")
			# Coloque o seu código aqui para exibir o HUD


func _on_mouse_entered() -> void:
	print("Evento de input recebido.")
