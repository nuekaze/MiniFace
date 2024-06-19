extends Node3D

var character = null
var secondary = null
var is_vrm = 0
var secondary_is_vrm = 0

var skel = null
var face = null
var head = null
var hips = null
var left_arm = null
var right_arm = null

# Secondary for extra clothes
var secondary_skel = null
var secondary_head = null
var secondary_hips = null
var secondary_left_arm = null
var secondary_right_arm = null

var initial_hip_pos = Vector3(0.0, 0.0, 0.0)

var tracker = null

var config = {
		"model": {
			"path": "",
			"secondary_path": "",
			"facemesh": 1,
			"arm_angle": 0,
			"hm_ratio": 0.0
		},
		"camera": {
			"position": 0,
			"distance": 1.0,
			"height": 1.7,
			"light": {
				"enabled": 0,
				"temperature": 0,
				"strength": 0.0,
				"rotation": 0.0,
				"height": 0.0
			},
		},
		"tracker": {
			"method": -1,
			"iphone_ip": "",
			"smoothing": 0.3
		}
	}

# Tracking data is always in "VTube Studio like" format.
var tracking_data = {
	"Position": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	},
	"Rotation": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	},
	"Blendshapes": {
		# ARKit shapes goes first.
		"browDownLeft": 0.0,
		"browDownRight": 0.0,
		"browInnerUp": 0.0,
		"browOuterUpLeft": 0.0,
		"browOuterUpRight": 0.0,
		"cheekPuff": 0.0,
		"cheekSquintLeft": 0.0,
		"cheekSquintRight": 0.0,
		"eyeBlinkLeft": 0.0,
		"eyeBlinkRight": 0.0,
		"eyeLookDownLeft": 0.0,
		"eyeLookDownRight": 0.0,
		"eyeLookInLeft": 0.0,
		"eyeLookInRight": 0.0,
		"eyeLookOutLeft": 0.0,
		"eyeLookOutRight": 0.0,
		"eyeLookUpLeft": 0.0,
		"eyeLookUpRight": 0.0,
		"eyeSquintLeft": 0.0,
		"eyeSquintRight": 0.0,
		"eyeWideLeft": 0.0,
		"eyeWideRight": 0.0,
		"jawForward": 0.0,
		"jawLeft": 0.0,
		"jawOpen": 0.0,
		"jawRight": 0.0,
		"mouthClose": 0.0,
		"mouthDimpleLeft": 0.0,
		"mouthDimpleRight": 0.0,
		"mouthFrownLeft": 0.0,
		"mouthFrownRight": 0.0,
		"mouthFunnel": 0.0,
		"mouthLeft": 0.0,
		"mouthLowerDownLeft": 0.0,
		"mouthLowerDownRight": 0.0,
		"mouthPressLeft": 0.0,
		"mouthPressRight": 0.0,
		"mouthPucker": 0.0,
		"mouthRight": 0.0,
		"mouthRollLower": 0.0,
		"mouthRollUpper": 0.0,
		"mouthShrugLower": 0.0,
		"mouthShrugUpper": 0.0,
		"mouthSmileLeft": 0.0,
		"mouthSmileRight": 0.0,
		"mouthStretchLeft": 0.0,
		"mouthStretchRight": 0.0,
		"mouthUpperUpLeft": 0.0,
		"mouthUpperUpRight": 0.0,
		"noseSneerLeft": 0.0,
		"noseSneerRight": 0.0,
		"tongueOut": 0.0,
		# Vowels for OpenSeeFace
		"a": 0.0,
		"i": 0.0,
		"u": 0.0,
		"e": 0.0,
		"o": 0.0,
		"blink": 0.0,
		"blinkLeft": 0.0,
		"blinkRight": 0.0
	}
}

var rest_pose = {
	"Position": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	},
	"Rotation": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	}
}

# Loader functions

func load_model(path: String) -> Node3D:
	var gltf := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	
	var m_file = FileAccess.open(path, FileAccess.READ)
	var model = m_file.get_buffer(m_file.get_length())
	
	gltf.append_from_buffer(model, "", gltf_state, 8)
	var generated_scene = gltf.generate_scene(gltf_state)
	
	return generated_scene

func load_vrm_model(path: String) -> Node3D:
	var gltf: GLTFDocument = GLTFDocument.new()
	var vrm_extension: GLTFDocumentExtension = preload("res://addons/vrm/vrm_extension.gd").new()
	gltf.register_gltf_document_extension(vrm_extension, true)
	
	var state: GLTFState = GLTFState.new()
	# state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_BASISU

	# Ensure Tangents is required for meshes with blend shapes as of Godot 4.2.
	#EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS = 8
	# EditorSceneFormatImporter may not be available in release builds, so hardcode 8 for flags
	var err = gltf.append_from_file(path, state, 8)
	if err != OK:
		gltf.unregister_gltf_document_extension(vrm_extension)
		return null
	
	var generated_scene = gltf.generate_scene(state)
	gltf.unregister_gltf_document_extension(vrm_extension)
	
	return generated_scene


# Process stuff
func _physics_process(_delta):
		if skel:
			# Process bone rotations
			var tmp = Vector3(
					tracking_data["Position"]["x"] - rest_pose["Position"]["x"],
					tracking_data["Position"]["y"] - rest_pose["Position"]["y"],
					-tracking_data["Position"]["z"] - rest_pose["Position"]["z"]
				) + initial_hip_pos
				
			skel.set_bone_pose_position(hips, 
				skel.get_bone_pose_position(hips) * $UI/VBoxContainer/Tracker/HSlider.value + 
				tmp * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
			)
			
			if secondary:
				secondary_skel.set_bone_pose_position(secondary_hips, 
					secondary_skel.get_bone_pose_position(secondary_hips) * $UI/VBoxContainer/Tracker/HSlider.value + 
					tmp * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
				)
			
			tmp = Quaternion.from_euler(Vector3(
					tracking_data["Rotation"]["x"] - rest_pose["Rotation"]["x"],
					tracking_data["Rotation"]["y"] - rest_pose["Rotation"]["y"],
					tracking_data["Rotation"]["z"] - rest_pose["Rotation"]["z"]
				) * $UI/VBoxContainer/Model/Settings/HSlider2.value)
			
			skel.set_bone_pose_rotation(hips, 
				skel.get_bone_pose_rotation(hips) * $UI/VBoxContainer/Tracker/HSlider.value + 
				tmp * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
			)
			
			if secondary:
				secondary_skel.set_bone_pose_rotation(secondary_hips, 
					secondary_skel.get_bone_pose_rotation(secondary_hips) * $UI/VBoxContainer/Tracker/HSlider.value + 
					tmp * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
				)
			
			tmp = Quaternion.from_euler(Vector3(
					tracking_data["Rotation"]["x"] - rest_pose["Rotation"]["x"],
					tracking_data["Rotation"]["y"] - rest_pose["Rotation"]["y"],
					tracking_data["Rotation"]["z"] - rest_pose["Rotation"]["z"]
				) * (1.0 - $UI/VBoxContainer/Model/Settings/HSlider2.value))
			
			skel.set_bone_pose_rotation(head, 
				skel.get_bone_pose_rotation(head) * $UI/VBoxContainer/Tracker/HSlider.value + 
				tmp * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
			)
			
			if secondary:
				secondary_skel.set_bone_pose_rotation(secondary_head, 
					secondary_skel.get_bone_pose_rotation(secondary_head) * $UI/VBoxContainer/Tracker/HSlider.value + 
					tmp * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
				)
			
		if face:
			# Process blendshapes
			for b in tracking_data["Blendshapes"].keys():
				var i = face.find_blend_shape_by_name(b)
				if i != -1:
					face.set_blend_shape_value(i, 
						face.get_blend_shape_value(i) * $UI/VBoxContainer/Tracker/HSlider.value + 
						tracking_data["Blendshapes"][b] * (1.0 - $UI/VBoxContainer/Tracker/HSlider.value)
					)

func _on_viewport_resize():
	$UI.size.y = get_viewport().size.y

func _ready():
	$UI.size.y = get_viewport().size.y
	get_viewport().connect("size_changed", _on_viewport_resize)
	# Check if there is saved config and load.
	var f = FileAccess.open("user://config.json", FileAccess.READ)
	if f:
		config = JSON.parse_string(f.get_as_text())
		
		# Load character if any.
		if config["model"]["path"] != "":
			_on_model_selected(config["model"]["path"])
		
		if config["model"]["secondary_path"] != "":
			_on_secondary_selected(config["model"]["secondary_path"])
		
		if character:
			$UI/VBoxContainer/Model/Settings/ItemList.select(config["model"]["facemesh"])
			_on_facemesh_selected(config["model"]["facemesh"])
			$UI/VBoxContainer/Model/Settings/HSlider.set_value_no_signal(config["model"]["arm_angle"])
			_on_arm_angle_change(config["model"]["arm_angle"])
			$UI/VBoxContainer/Model/Settings/HSlider2.set_value_no_signal(config["model"]["hm_ratio"])
		
		# Load camera.
		$UI/VBoxContainer/Camera/HSlider.set_value_no_signal(config["camera"]["position"])
		$UI/VBoxContainer/Camera/HSlider2.set_value_no_signal(config["camera"]["distance"])
		$UI/VBoxContainer/Camera/HSlider3.set_value_no_signal(config["camera"]["height"])
		_on_camera_change(0)
		
		# Load light
		$UI/VBoxContainer/Camera/HBoxContainer/CheckButton.button_pressed = config["camera"]["light"]["enabled"]
		$UI/VBoxContainer/Camera/Light/HSlider.set_value_no_signal(config["camera"]["light"]["temperature"])
		$UI/VBoxContainer/Camera/Light/HSlider4.set_value_no_signal(config["camera"]["light"]["strength"])
		$UI/VBoxContainer/Camera/Light/HSlider2.set_value_no_signal(config["camera"]["light"]["rotation"])
		$UI/VBoxContainer/Camera/Light/HSlider3.set_value_no_signal(config["camera"]["light"]["height"])
		_on_light_color_changed(config["camera"]["light"]["temperature"])
		_on_light_rotation_changed(config["camera"]["light"]["rotation"])
		_on_light_up_down_changed(config["camera"]["light"]["height"])
		_on_light_strength_change(config["camera"]["light"]["strength"])
		
		# Load tracker
		if config["tracker"]["method"] >= 0:
			$UI/VBoxContainer/Tracker/ItemList.select(config["tracker"]["method"])
		$UI/VBoxContainer/Tracker/VBoxContainer/TextEdit.text = config["tracker"]["iphone_ip"]
		$UI/VBoxContainer/Tracker/HSlider.set_value_no_signal(config["tracker"]["smoothing"])
		
		if config["tracker"]["method"] == 2:
			$UI/VBoxContainer/Tracker/VBoxContainer.visible = true

func _exit_tree():
	var f = FileAccess.open("user://config.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(config, '  '))

# Model signals
func _on_model_selected(path):
	# Unload any characters
	if character:
		_on_clear_model_pressed()
	
	if not FileAccess.open(path, FileAccess.READ):
		return
	
	if 'vrm' in path:
		is_vrm = 1
		character = load_vrm_model(path)
	else:
		is_vrm = 0
		character = load_model(path)
	
	if not character:
		return
	
	add_child(character)
	for n in character.get_children():
		if n is Skeleton3D:
			skel = n
			$UI/VBoxContainer/Model/Settings.visible = true
			break
			
		for nn in n.get_children():
			if nn is Skeleton3D:
				skel = nn
				$UI/VBoxContainer/Model/Settings.visible = true
				
	if not skel:
		print("Could not find skel")
		character.queue_free()
		$UI/VBoxContainer/Model/Settings.visible = false
		return
	
	# Get arm bones for angle
	for i in skel.get_bone_count():
		if 'arm' in skel.get_bone_name(i).to_lower():
			if 'L' in skel.get_bone_name(i) and 'lower' not in skel.get_bone_name(i).to_lower() and 'twist' not in skel.get_bone_name(i).to_lower() and not left_arm:
				left_arm = i
			if 'R' in skel.get_bone_name(i) and 'lower' not in skel.get_bone_name(i).to_lower() and 'twist' not in skel.get_bone_name(i).to_lower() and not right_arm:
				right_arm = i
		if 'head' in skel.get_bone_name(i).to_lower():
			head = i
		if 'hips' in skel.get_bone_name(i).to_lower():
			hips = i
			initial_hip_pos = skel.get_bone_pose_position(hips)
	
	for m in skel.get_children():
		if m is MeshInstance3D:
			$UI/VBoxContainer/Model/Settings/ItemList.add_item(m.name)
	
	config["model"]["path"] = path
	_on_arm_angle_change($UI/VBoxContainer/Model/Settings/HSlider.value)
	
func _on_secondary_selected(path):
	# Unload any current
	if secondary:
		_on_clear_secondary_pressed()
	
	if not FileAccess.open(path, FileAccess.READ):
		return
	
	if 'vrm' in path:
		secondary_is_vrm = 1
		secondary = load_vrm_model(path)
	else:
		secondary_is_vrm = 0
		secondary = load_model(path)
	
	if not secondary:
		return
	
	add_child(secondary)
	for n in secondary.get_children():
		if n is Skeleton3D:
			secondary_skel = n
			break
			
		for nn in n.get_children():
			if nn is Skeleton3D:
				secondary_skel = nn
				$UI/VBoxContainer/Model/Settings.visible = true
				
	if not secondary_skel:
		print("Could not find skel")
		secondary.queue_free()
		return
	
	# Get arm bones for angle
	for i in secondary_skel.get_bone_count():
		if 'arm' in secondary_skel.get_bone_name(i).to_lower():
			if 'L' in secondary_skel.get_bone_name(i) and 'lower' not in secondary_skel.get_bone_name(i).to_lower() and 'twist' not in secondary_skel.get_bone_name(i).to_lower() and not secondary_left_arm:
				secondary_left_arm = i
				
			if 'R' in secondary_skel.get_bone_name(i) and 'lower' not in secondary_skel.get_bone_name(i).to_lower() and 'twist' not in secondary_skel.get_bone_name(i).to_lower() and not secondary_right_arm:
				secondary_right_arm = i
				
		if 'head' in secondary_skel.get_bone_name(i).to_lower():
			secondary_head = i
			
		if 'hips' in secondary_skel.get_bone_name(i).to_lower():
			secondary_hips = i
	
	config["model"]["secondary_path"] = path
	_on_arm_angle_change($UI/VBoxContainer/Model/Settings/HSlider.value)

func _on_facemesh_selected(index):
	if $UI/VBoxContainer/Model/Settings/ItemList.get_selected_items():
		face = skel.get_node($UI/VBoxContainer/Model/Settings/ItemList.get_item_text(
			$UI/VBoxContainer/Model/Settings/ItemList.get_selected_items()[0]))
		config["model"]["facemesh"] = index
	else:
		print("Could not find facemesh")

func _on_camera_change(value):
	$Camera3D.position = Vector3(
		sin(deg_to_rad(float($UI/VBoxContainer/Camera/HSlider.value))) * float($UI/VBoxContainer/Camera/HSlider2.value),
		float($UI/VBoxContainer/Camera/HSlider3.value),
		cos(deg_to_rad(float($UI/VBoxContainer/Camera/HSlider.value))) * float($UI/VBoxContainer/Camera/HSlider2.value)
		)
	$Camera3D.rotation.y = deg_to_rad(float($UI/VBoxContainer/Camera/HSlider.value))
	
	config["camera"]["position"] = $UI/VBoxContainer/Camera/HSlider.value
	config["camera"]["distance"] = $UI/VBoxContainer/Camera/HSlider2.value
	config["camera"]["height"] = $UI/VBoxContainer/Camera/HSlider3.value

func _on_arm_angle_change(value):
	skel.set_bone_pose_rotation(left_arm, Quaternion.from_euler(Vector3(-deg_to_rad(float(value)) + is_vrm * (PI/2), is_vrm * PI, 0.0)))
	skel.set_bone_pose_rotation(right_arm, Quaternion.from_euler(Vector3(-deg_to_rad(float(value)) + is_vrm * (PI/2), is_vrm * PI, 0.0)))
	config["model"]["arm_angle"] = $UI/VBoxContainer/Model/Settings/HSlider.value
	
	if secondary:
		secondary_skel.set_bone_pose_rotation(secondary_left_arm, Quaternion.from_euler(Vector3(-deg_to_rad(float(value)) + secondary_is_vrm * (PI/2), secondary_is_vrm * PI, 0.0)))
		secondary_skel.set_bone_pose_rotation(secondary_right_arm, Quaternion.from_euler(Vector3(-deg_to_rad(float(value)) + secondary_is_vrm * (PI/2), secondary_is_vrm * PI, 0.0)))

func _on_load_button_pressed():
	$UI/VBoxContainer/Model/FileDialog.visible = true

func _on_load_secondary_pressed():
	$UI/VBoxContainer/Model/FileDialog2.visible = true

func _on_hm_ratio_changed(value):
	config["model"]["hm_ratio"] = value

# Light signals
func kelvin_to_rgb(temp):
	# Function stolen from https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
	var red = 0.0
	var green = 0.0
	var blue = 0.0
	
	# Process red
	if temp <= 66:
		red = 255
	else:
		red = 329.698727446 * (red ** -0.1332047592)
	if red < 0: red = 0
	elif red > 255: red = 255
		
	# Process green
	if temp <= 66:
		green = temp
		green = 99.4708025861 * log(green) - 161.1195681661
		
	else:
		green = temp - 60
		green = 288.1221695283 * (green ** -0.0755148492)
	if green < 0: green = 0
	if green > 255: green = 255
	
	# Process blue
	if temp >= 66:
		blue = 255
	else:
		if temp <= 19:
			blue = 0
		else:
			blue = temp - 10
			blue = 138.5177312231 * log(blue) - 305.0447927307
			if blue < 0: blue = 0
			if blue > 255: blue = 255
	
	return Color(red/255, green/255, blue/255, 1.0)

func _on_light_enable(toggled_on):
	if toggled_on:
		$UI/VBoxContainer/Camera/Light.visible = true
		$DirectionalLight3D.visible = true
		$DirectionalLight3D.set_color(kelvin_to_rgb($UI/VBoxContainer/Camera/Light/HSlider.value))
		config["camera"]["light"]["enabled"] = 1
		
	else:
		$UI/VBoxContainer/Camera/Light.visible = false
		$DirectionalLight3D.visible = false
		config["camera"]["light"]["enabled"] = 0

func _on_light_color_changed(value):
	$DirectionalLight3D.set_color(kelvin_to_rgb($UI/VBoxContainer/Camera/Light/HSlider.value))
	config["camera"]["light"]["temperature"] = $UI/VBoxContainer/Camera/Light/HSlider.value

func _on_light_rotation_changed(value):
	$DirectionalLight3D.rotation.y = deg_to_rad(value)
	config["camera"]["light"]["rotation"] = value

func _on_light_up_down_changed(value):
	$DirectionalLight3D.rotation.x = deg_to_rad(value)
	config["camera"]["light"]["height"] =  value

func _on_light_strength_change(value):
	$DirectionalLight3D.light_energy = value
	config["camera"]["light"]["strength"] = value

# Tracker signals
func _on_tracking_data_recived(new_data):
	tracking_data = new_data

func _on_tracking_toggle(toggled_on):
	if toggled_on:
		# Get the selected trackgin method
		$UI/VBoxContainer/Tracker/Button.text = "Stop"
		$UI/VBoxContainer/Tracker/ItemList.allow_reselect = false
		
		var t
		if $UI/VBoxContainer/Tracker/ItemList.get_selected_items():
			t = $UI/VBoxContainer/Tracker/ItemList.get_selected_items()[0]
		else:
			return
		
		if t == 0:
			tracker = load("res://trackers/mediapipe-vt.tscn").instantiate()
			add_child(tracker)
			tracker.connect("publish_new_data", _on_tracking_data_recived)
			
		elif t == 2:
			if not $UI/VBoxContainer/Tracker/VBoxContainer/TextEdit.text.is_valid_ip_address():
				return
				
			tracker = load("res://trackers/vtube_studio.tscn").instantiate()
			add_child(tracker)
			tracker.connect("publish_new_data", _on_tracking_data_recived)
			tracker.start_poller($UI/VBoxContainer/Tracker/VBoxContainer/TextEdit.text)
			
	else:
		# Stop all tracking
		if tracker:
			tracker.queue_free()
		
		$UI/VBoxContainer/Tracker/Button.text = "Start"
		$UI/VBoxContainer/Tracker/ItemList.allow_reselect = true

func _on_tracker_selected(index):
	if $UI/VBoxContainer/Tracker/ItemList.get_selected_items():
		$UI/VBoxContainer/Tracker/Button.disabled = false
		config["tracker"]["method"] = index
	else:
		$UI/VBoxContainer/Tracker/Button.disabled = true
		
	var t
	if $UI/VBoxContainer/Tracker/ItemList.get_selected_items():
		t = $UI/VBoxContainer/Tracker/ItemList.get_selected_items()[0]
		
	if t == 2:
		$UI/VBoxContainer/Tracker/VBoxContainer.visible = true
		
	else:
		$UI/VBoxContainer/Tracker/VBoxContainer.visible = false

func _on_position_reset():
	rest_pose["Position"]["x"] = tracking_data["Position"]["x"]
	rest_pose["Position"]["y"] = tracking_data["Position"]["y"]
	rest_pose["Position"]["z"] = tracking_data["Position"]["z"]
	rest_pose["Rotation"]["x"] = tracking_data["Rotation"]["x"]
	rest_pose["Rotation"]["y"] = tracking_data["Rotation"]["y"]
	rest_pose["Rotation"]["z"] = tracking_data["Rotation"]["z"]

func _on_smoothing_changed(value):
	config["tracker"]["smoothing"] = value

func _on_iphone_ip_changed():
	config["tracker"]["iphone_ip"] = $UI/VBoxContainer/Tracker/VBoxContainer/TextEdit.text

func _on_clear_model_pressed():
	if character:
		$UI/VBoxContainer/Model/Settings.visible = false
		character.queue_free()
		character = null
		skel = null
		face = null
		hips = null
		head = null
		left_arm = null
		right_arm = null
		$UI/VBoxContainer/Model/Settings/ItemList.clear()
	config["model"]["path"] = ""


func _on_clear_secondary_pressed():
	if secondary:
		secondary.queue_free()
		secondary = null
		secondary_skel = null
		secondary_hips = null
		secondary_head = null
		secondary_left_arm = null
		secondary_right_arm = null
	config["model"]["secondary_path"] = ""
