extends Node3D

var character = null
var face = null
var skel = null
var is_vrm = 0
var left_arm = null
var right_arm = null
var hips = null
var initial_hip_pos = Vector3(0.0, 0.0, 0.0)
var head = null
var tracker = null

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


# Light calculation
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

# Loader functions

func load_model(path: String) -> Node3D:
	var gltf := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	
	var m_file = FileAccess.open(path, FileAccess.READ)
	var model = m_file.get_buffer(m_file.get_length())
	
	gltf.append_from_buffer(model, "", gltf_state, 8)
	var generated_scene = gltf.generate_scene(gltf_state)
	
	is_vrm = 0
	
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
	
	is_vrm = 1
	
	return generated_scene


# Process stuff

func _physics_process(delta):
		if skel:
			# Process bone rotations
			var tmp = Vector3(
					tracking_data["Position"]["x"] - rest_pose["Position"]["x"],
					tracking_data["Position"]["y"] - rest_pose["Position"]["y"],
					tracking_data["Position"]["z"] - rest_pose["Position"]["z"]
				) + initial_hip_pos
				
			skel.set_bone_pose_position(hips, 
				skel.get_bone_pose_position(hips) * $UI/VBoxContainer/Tracker/HSlider.value + 
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
			
			tmp = Quaternion.from_euler(Vector3(
					tracking_data["Rotation"]["x"] - rest_pose["Rotation"]["x"],
					tracking_data["Rotation"]["y"] - rest_pose["Rotation"]["y"],
					tracking_data["Rotation"]["z"] - rest_pose["Rotation"]["z"]
				) * (1.0 - $UI/VBoxContainer/Model/Settings/HSlider2.value))
			
			skel.set_bone_pose_rotation(head, 
				skel.get_bone_pose_rotation(head) * $UI/VBoxContainer/Tracker/HSlider.value + 
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

func _ready():
	# Init camera position once
	_on_camera_change(0.0)


# Signal functions

func _on_model_selected(path):
	# Unload any characters
	if character:
		$UI/VBoxContainer/Model/Settings.visible = false
		character.queue_free()
		character = null
		skel = null
		face = null
		$UI/VBoxContainer/Model/Settings/ItemList.clear()
	
	if not FileAccess.open(path, FileAccess.READ):
		return
	
	if 'vrm' in path:
		character = load_vrm_model(path)
	else:
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
			
	_on_arm_angle_change(0.0)

func _on_facemesh_selected(index):
	if $UI/VBoxContainer/Model/Settings/ItemList.get_selected_items():
		face = skel.get_node($UI/VBoxContainer/Model/Settings/ItemList.get_item_text(
			$UI/VBoxContainer/Model/Settings/ItemList.get_selected_items()[0]))
	else:
		print("Could not find facemesh")

func _on_camera_change(value):
	$Camera3D.position = Vector3(
		sin(deg_to_rad(float($UI/VBoxContainer/Camera/HSlider.value))) * float($UI/VBoxContainer/Camera/HSlider2.value),
		float($UI/VBoxContainer/Camera/HSlider3.value),
		cos(deg_to_rad(float($UI/VBoxContainer/Camera/HSlider.value))) * float($UI/VBoxContainer/Camera/HSlider2.value)
		)
	$Camera3D.rotation.y = deg_to_rad(float($UI/VBoxContainer/Camera/HSlider.value))

func _on_arm_angle_change(value):
	skel.set_bone_pose_rotation(left_arm, Quaternion.from_euler(Vector3(-deg_to_rad(float($UI/VBoxContainer/Model/Settings/HSlider.value)) + is_vrm * (PI/2), is_vrm * PI, 0.0)))
	skel.set_bone_pose_rotation(right_arm, Quaternion.from_euler(Vector3(-deg_to_rad(float($UI/VBoxContainer/Model/Settings/HSlider.value)) + is_vrm * (PI/2), is_vrm * PI, 0.0)))

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

func _on_load_button_pressed():
	$UI/VBoxContainer/Model/FileDialog.visible = true


# Light functions

func _on_light_enable(toggled_on):
	if toggled_on:
		$UI/VBoxContainer/Camera/Light.visible = true
		$DirectionalLight3D.visible = true
		$DirectionalLight3D.set_color(kelvin_to_rgb($UI/VBoxContainer/Camera/Light/HSlider.value))
		
	else:
		$UI/VBoxContainer/Camera/Light.visible = false
		$DirectionalLight3D.visible = false

func _on_light_color_changed(value):
	$DirectionalLight3D.set_color(kelvin_to_rgb($UI/VBoxContainer/Camera/Light/HSlider.value))
	


func _on_light_rotation_changed(value):
	$DirectionalLight3D.rotation.y = deg_to_rad(value)


func _on_light_up_down_changed(value):
	$DirectionalLight3D.rotation.x = deg_to_rad(value)


func _on_light_strength_change(value):
	$DirectionalLight3D.light_energy = value
