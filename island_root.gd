extends Node2D



func _ready():
	LevelUnlock.unlock("Island Scene")
	print("Unlock called: Island Scene")
	LevelUnlock.unlock("1st_island")  # match these IDs across all scripts
	await get_tree().create_timer(2.0).timeout
	DialogueManager.show_dialogue([
		"You've landed on the island.                                                                                (Enter to Continue)",
		"You Must Locate the keys and Fight off the Enemy",
		"Follow Your Minimap towards the Customer, Remember, your main quest is to deliver!",
		"Beware the Ramen Warrior that awaits for you just before the customer's house, aiming to defeat you and take your food!"
	])
