extends Area2D

@export_category("Capacidade da Construção")
@export var lotacao_maxima: int = 5

var personagens_abrigados: Array = []


func _on_body_entered(body) -> void:
	if not body.is_in_group("personagens"):
		return

	# 2. Verifica se a casa já está cheia.
	if personagens_abrigados.size() >= lotacao_maxima:
		print("A casa está cheia! Lotação: %d/%d" % [personagens_abrigados.size(), lotacao_maxima])
		return # Se estiver cheia, não deixa entrar.

	print("Um personagem encostou na casa!")
	
	personagens_abrigados.append(body)
	print("'%s' entrou na casa. Lotação atual: %d/%d" % [body.name, personagens_abrigados.size(), lotacao_maxima])
	
	body.hide()


func _on_body_exited(body) -> void:
	if personagens_abrigados.has(body):
		personagens_abrigados.erase(body)
		print("'%s' saiu da casa. Lotação atual: %d/%d" % [body.name, personagens_abrigados.size(), lotacao_maxima])
		
		body.show()
