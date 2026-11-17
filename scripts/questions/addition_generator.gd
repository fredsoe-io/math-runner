class_name AdditionGenerator
extends QuestionGenerator

func generate_question() -> Question:
	var a = random_number()
	var b = random_number()
	return make_question(str(a, " + ", b, " = ?"), a + b)
