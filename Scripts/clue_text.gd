class_name ClueText
extends RefCounted

# turns mesh name like "gloves_fingerless_pink" into clue words like
# "pink fingerless gloves". mesh names remain the same.

# how each category reads in a clue.
# word: added on the end ("" means the piece name already says what it is, like crocs)
# plural: plural things don't get "a" or "an" in front
# color_last: the name ends with the color (shoes_crocs_blue), so move it to the front
const CATEGORY_RULES := {
	"hat": {"word": "hat", "plural": false},
	"glasses": {"word": "glasses", "plural": true},
	"gloves": {"word": "gloves", "plural": true, "color_last": true},
	"pants": {"word": "pants", "plural": true},
	"socks": {"word": "socks", "plural": true},
	"shoes": {"word": "", "plural": true, "color_last": true},
	"top": {"word": "", "plural": false},
	"costume": {"word": "costume", "plural": false},
}

# fixes for pieces whose names don't read well in a clue
const OVERRIDES := {
	# hats
	"hat_cap": "cap",
	"hat_cap_colourful": "colorful cap",
	"hat_crown": "crown",
	"hat_fries": "french fries hat",
	"hat_grad": "graduation cap",
	"hat_headphones": "pair of headphones",
	"hat_pylon": "traffic cone hat",
	"hat_top_hat": "top hat",
	"hat_toque": "hat with a pompom",
	"hat_viking": "viking helmet",
	# glasses
	"glasses_3d": "3D glasses",
	# gloves
	"gloves_black_white": "black and white gloves",
	# pants
	"pants_flare": "flared pants",
	"pants_joggers": "joggers",
	"pants_shorts": "shorts",
	# shoes
	"shoes_hightop_black": "black high-tops",
	"shoes_hightop_red": "red high-tops",
	"shoes_hightop_yellow": "yellow high-tops",
	"shoes_slippers_puppies": "puppy slippers",
	# tops
	"top_long": "long t-shirt",
	"top_polo": "polo shirt",
	"top_tank": "tank top",
	"top_tshirt": "t-shirt",
}


# usage: ClueText.describe("hat_turkey")  gives  "a turkey hat"
#        ClueText.describe("top_hoodie", "orange")  gives  "an orange hoodie"
static func describe(piece_name: String, color: String = "") -> String:
	var key := piece_name.to_lower()
	var parts := key.split("_")
	var category := parts[0]

	# face_ and anything unknown gets no clue
	if not CATEGORY_RULES.has(category):
		return ""
	var rule: Dictionary = CATEGORY_RULES[category]

	var words: String
	if OVERRIDES.has(key):
		# the override is already the finished noun phrase
		words = OVERRIDES[key]
	else:
		var middle := Array(parts.slice(1))
		# some names end with the color, so move it to the front
		if rule.get("color_last", false) and middle.size() > 1:
			middle.push_front(middle.pop_back())
		words = " ".join(PackedStringArray(middle))
		if rule["word"] != "":
			words += " " + rule["word"]

	# tops and pants get their color from the texture
	if color != "":
		words = color + " " + words
	words = words.strip_edges()
	if words == "":
		return ""

	# plural things have no article. everything else gets "a" or "an"
	if rule["plural"]:
		return words
	var article := "an" if words[0].to_lower() in "aeiou" else "a"
	return article + " " + words
