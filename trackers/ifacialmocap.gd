extends Node

var listening_thread: Thread
var polling_thread: Thread
var running = false
var client: PacketPeerUDP

var solver = preload("res://trackers/solvers/vowels.gd")

signal publish_new_data

const vowels = ['a', 'i', 'u', 'e', 'o']
const jvowels = ['あ', 'い', 'う', 'え', 'お']

const normalizations = {
	'a': 1.534770823748702, 
	'i': 2, 
	'u': 4.294774692471924, 
	'e': 2.3366845158182037, 
	'o': 2
	}

const vowel_targets = {
	"a": [0.6, 0.5],
	"i": [0.1, 0.7],
	"u": [0.2, -0.1],
	"e": [0.3, 0.6],
	"o": [0.6, -0.1]
}

var data = {
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
	"left_eye": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0,
		"w": 1.0
	},
	"right_eye": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0,
		"w": 1.0
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
		"vowels": {
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
}

func _listening_thread():
	var server := UDPServer.new()
	server.listen(49983)
	
	while running:
		server.poll()
		if server.is_connection_available():
			var peer = server.take_connection()
			var packet = peer.get_packet()
			var d = packet.get_string_from_utf8()
			
			if d:
				d = d.split("|")
				for i in 52:
					var t = d[i+1].split("-")
					var key = t[0]
					var val = t[1]
					key = key.replace("_R", "Right").replace("_L", "Left")
					val = float(val) / 100.0
					
					data["Blendshapes"][key] = val

				var pos_rots = d[54].split('#')[1].split(',')
				data["Position"]['x'] = float(pos_rots[3])
				data["Position"]['y'] = float(pos_rots[4])
				data["Position"]['z'] = float(pos_rots[5])
				
				data["Rotation"]['x'] = deg_to_rad(float(pos_rots[0]))
				data["Rotation"]['y'] = deg_to_rad(float(pos_rots[1]))
				data["Rotation"]['z'] = deg_to_rad(float(pos_rots[2]))
				
				var open = data["Blendshapes"]["jawOpen"]
				var wide = (max(data["Blendshapes"]["mouthDimpleLeft"], data["Blendshapes"]["mouthDimpleRight"]) * 5 - data["Blendshapes"]["mouthPucker"])
				
				data["Blendshapes"]["vowels"]["a"] = 0.0
				data["Blendshapes"]["vowels"]["i"] = 0.0
				data["Blendshapes"]["vowels"]["u"] = 0.0
				data["Blendshapes"]["vowels"]["e"] = 0.0
				data["Blendshapes"]["vowels"]["o"] = 0.0
				data["Blendshapes"]["vowels"]["あ"] = 0.0
				data["Blendshapes"]["vowels"]["い"] = 0.0
				data["Blendshapes"]["vowels"]["う"] = 0.0
				data["Blendshapes"]["vowels"]["え"] = 0.0
				data["Blendshapes"]["vowels"]["お"] = 0.0
				
				var scores = [0,0,0,0,0]
				
				# Shapes for viwels are in most cases japanese characters using the MMD specification.
				scores[0] = solver.get_vowel_score(vowel_targets["a"], [open, wide], normalizations["a"])
				scores[1] = solver.get_vowel_score(vowel_targets["i"], [open, wide], normalizations["i"])
				scores[2] = solver.get_vowel_score(vowel_targets["u"], [open, wide], normalizations["u"])
				scores[3] = solver.get_vowel_score(vowel_targets["e"], [open, wide], normalizations["e"])
				scores[4] = solver.get_vowel_score(vowel_targets["o"], [open, wide], normalizations["o"])
				
				var high = 0
				for s in range(5):
					if scores[s] > scores[high] and scores[s] > 0.2:
						high = s
				
				data["Blendshapes"]["vowels"][vowels[high]] = scores[high]
				data["Blendshapes"]["vowels"][jvowels[high]] = scores[high]
				
				data["Blendshapes"]["vowels"]["ウィンク"] = data["Blendshapes"]["eyeBlinkLeft"]
				data["Blendshapes"]["vowels"]["ウィンク右"] = data["Blendshapes"]["eyeBlinkRight"]
				
				# Solve rotations for eyes
				# Left eye
				var q = Quaternion.from_euler(Vector3(
					(PI/3) * (data["Blendshapes"]["eyeLookDownLeft"] - data["Blendshapes"]["eyeLookUpLeft"]),
					(PI/3) * (data["Blendshapes"]["eyeLookOutLeft"] - data["Blendshapes"]["eyeLookInLeft"]),
					0.0
				))
				data["left_eye"]["x"] = q.x
				data["left_eye"]["y"] = q.y
				data["left_eye"]["z"] = q.z
				data["left_eye"]["w"] = q.w
				
				# Right eye
				q = Quaternion.from_euler(Vector3(
					(PI/3) * (data["Blendshapes"]["eyeLookDownRight"] - data["Blendshapes"]["eyeLookUpRight"]),
					(PI/3) * (data["Blendshapes"]["eyeLookInRight"] - data["Blendshapes"]["eyeLookOutRight"]),
					0.0
				))
				data["right_eye"]["x"] = q.x
				data["right_eye"]["y"] = q.y
				data["right_eye"]["z"] = q.z
				data["right_eye"]["w"] = q.w
				
				emit_signal("publish_new_data", data)
		
		# Sleep a bit to make sure we don't overdo it
		await get_tree().create_timer(0.02).timeout
	
func _ready():
	running = true
	listening_thread = Thread.new()
	listening_thread.start(_listening_thread.bind())
	client = PacketPeerUDP.new()
	
	
func start_poller(ip):
	client.connect_to_host(ip, 49983)
	$PollTimer.start(1.0)

func _exit_tree():
	running = false
	listening_thread.wait_to_finish()

func _on_poll():
	client.put_packet('iFacialMocap_sahuasouryya9218sauhuiayeta91555dy3719'.to_utf8_buffer())
