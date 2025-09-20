extends Node

const FIRST_NAMES = [
  "Abayomi", "Olufemi", "Dandara", "Nzinga", "Luena", "Kalunga", "Omolu",
  "Oxum", "Yemanjá", "Ogum", "Akin", "Makena", "Tupã", "Zumbi", "Ayanda",
  "Joaquim", "Manoel", "Francisco", "Maria", "Josefa", "Ana", "Domingos", "Sururu"
]

const LAST_NAMES = [
  "de Angola", "da Guiné", "do Congo", "de Benguela", 
  "da Cruz", "da Conceição", "dos Reis", "da Silva", 
  "de Jesus", "do Rosário", "da Luz", "dos Santos", "do Sururu"
]

func _ready():
	randomize()

func get_random_name() -> String:
	var first = FIRST_NAMES.pick_random()
	var last = LAST_NAMES.pick_random()
	return "%s %s" % [first, last]
