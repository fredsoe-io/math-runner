class_name SubtractionGenerator
extends QuestionGenerator

func generate_question() -> Question:
	var a = random_number()
	var b = random_number()
	if avoid_negative_numbers and a < b:
		# Swap so the biggest number comes first
		var smallest = a
		a = b
		b = smallest
	return make_question(str(a, " - ", b, " = ?"), a - b)
