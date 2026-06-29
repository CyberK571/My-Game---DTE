extends Node

# Each step is a Dictionary with:
#   "text"    : String shown in the dialogue box
#   "trigger" : "press" (player presses Enter/Space) or "action" (something happens in game)
#   "action"  : String name of the action to wait for (only needed if trigger == "action")

var steps = [
	{ "text": "Welcome, captain! Use WASD or arrow keys to sail your ship.", "trigger": "action", "action": "moved" },
	{ "text": "Great! Now aim with your mouse and click to fire a cannonball.", "trigger": "action", "action": "shot" },
	{ "text": "Keep an eye on your fuel! Sail over a fuel pickup to collect it.", "trigger": "action", "action": "collected_fuel" },
	{ "text": "You're ready to sail! Press Enter to begin your adventure.", "trigger": "press" },
]

var current_step := 0
var tutorial_active := true

# TutorialUI will connect to this signal to update its text
signal step_changed(text: String)
signal tutorial_finished

func _ready():
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
	# Handle "press" trigger steps
	if steps[current_step]["trigger"] == "press":
		if event.is_action_pressed("ui_accept"):  # Enter or Space
			advance()

# Call this from your ship/ocean script when something happens
# e.g. TutorialManager.report_action("moved")
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
	emit_signal("tutorial_finished")
	# TutorialUI will hide itself when it receives tutorial_finished
