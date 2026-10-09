extends RichTextLabel

func _ready() -> void:
	# 1. Clear any existing connections to prevent duplicates
	if meta_clicked.is_connected(_on_link_clicked):
		meta_clicked.disconnect(_on_link_clicked)
		
	# 2. Connect the built-in signal safely using code
	meta_clicked.connect(_on_link_clicked)

func _on_link_clicked(meta: Variant) -> void:
	var url_string = str(meta).strip_edges()
	
	# 3. Open the computer's web browser
	OS.shell_open(url_string)
