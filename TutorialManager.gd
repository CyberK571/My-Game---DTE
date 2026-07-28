extends Node
# Each step is a Dictionary with:
#   "text"    : String shown in the dialogue box
#   "trigger" : "press" (player presses Enter/Space) or "action" (something happens in game)
#   "action"  : String name of the action to wait for (only needed if trigger == "action")
var steps = [
	{ "text": "Welcome, captain! To the game of Snack Supreme and the Quest for Delivery!                                                                                                                              (Press Enter to Continue)", "trigger": "press" },
	{ "text": "As Captain, you and your ship, Snack Supreme, must Sail through the Seas with the Goal of Delivering Delicious Food to Clients!", "trigger": "press" },
	{ "text": "Today, you must deliver to 4 clients who reside on 4 islands across 4 different seas, however it is not as easy as it seems...", "trigger": "press" },
	{ "text": "You Must Utilize your Skills and Abilities to Overcome Challenges along the Way!", "trigger": "press" },
	{ "text": "You're ready to sail and Deliver! Press Enter to begin your adventure.", "trigger": "press" },
]
var current_step := 0
var tutorial_active := true
var tutorial_complete := false
signal step_changed(text: String)
signal tutorial_finished
func _ready():
	if tutorial_complete:
		tutorial_active = false
		return
	show_current_step()
func show_current_step():
	if current_step >= steps.size():
		finish_tutorial()
		return
	var step = steps[current_step]
	emit_signal("step_changed", step["text"])
func _input(event):
	if not tutorial_active:
		return
	if steps[current_step]["trigger"] == "press":
		if event.is_action_pressed("ui_accept"):
			advance()
func report_action(action_name: String):
	if not tutorial_active:
		return
	var step = steps[current_step]
	if step["trigger"] == "action" and step["action"] == action_name:
		advance()
func advance():
	current_step += 1
	show_current_step()
func finish_tutorial():
	tutorial_active = false
	tutorial_complete = true
	emit_signal("tutorial_finished")
	set_process(false)
	set_process_input(false)
