extends Node

# Sinal para notificar a HUD sobre mudanças nos status
signal status_updated

var dinheiro = 0
var saude = 100
var fome = 100
var seguranca = 100
var relacoes = 100

func _ready():
	emit_signal("status_updated")

func mudar_status(nome_status, valor):
	match nome_status:
		"dinheiro":
			dinheiro += valor
		"saude":
			saude = clamp(saude + valor, 0, 100)
		"fome":
			fome = clamp(fome + valor, 0, 100)
		"seguranca":
			seguranca = clamp(seguranca + valor, 0, 100)
		"relacoes":
			relacoes = clamp(relacoes + valor, 0, 100)

	emit_signal("status_updated")

	print("Status alterado: ", nome_status, ", Novo valor: ", get(nome_status))

func get_status_value(nome_status):
	return get(nome_status)

func mudar_dinheiro(valor):
	dinheiro += valor
	emit_signal("status_updated")
