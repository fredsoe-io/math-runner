class_name DivisionGenerator
extends QuestionGenerator

func generate_question() -> Question:
	# Start from the answer and multiply up, so the division always goes up evenly.
	# The number range applies to the divisor and the answer, like a times table.
	var answer = random_number()
	var divisor = randi_range(max(min_value, 1), max(max_value, 1)) # Never divide by 0
	return make_question(str(answer * divisor, " ÷ ", divisor, " = ?"), answer)
