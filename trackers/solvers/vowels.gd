extends Node

static func solve_vowels(mouthX, mouthY):
	var ratioI = clamp(remap(mouthX, 0, 1, 0, 1) * 2 * remap(mouthY, 0, 1, 0.2, 0.7), 0, 1)
	var ratioA = mouthY * 0.4 + mouthY * (1 - ratioI) * 0.6
	var ratioU = mouthY * remap(1 - ratioI, 0, 1, 0, 0.3) * 0.1
	var ratioE = remap(ratioU, 0, 1, 0.2, 1) * (1 - ratioI) * 0.3
	var ratioO = (1 - ratioI) * remap(mouthY, 0, 1, 0.3, 1) * 0.4
	
	print([ratioA, ratioI, ratioU, ratioE, ratioO])
	
	return [ratioA, ratioI, ratioU, ratioE, ratioO]

static func get_vowel_score(target, sample, normalization):
	var rx = (sample[0] - target[0]) ** 2
	var ry = (sample[1] - target[1]) ** 2
	
	
	
	return 1 - (clamp(rx + ry, 0, 1) ** 0.5) * normalization
