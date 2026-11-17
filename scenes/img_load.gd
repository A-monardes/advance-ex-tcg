class_name ImgLoad
## Carga una imagen (PNG, JPG o WEBP) leyendo sus bytes. Funciona igual en el editor, en
## user:// y dentro del paquete del juego exportado (donde no hay archivos sueltos en el
## disco y Image.load_from_file con una ruta del sistema no los encuentra).

## ¿Existe el archivo? En el juego exportado las imágenes y sonidos del proyecto no quedan
## como archivo suelto (Godot guarda la versión importada): también cuenta esa.
static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or (path.begins_with("res://") and ResourceLoader.exists(path))


static func load(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return _imported(path)
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return _imported(path)
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	match path.get_extension().to_lower():
		"png": err = img.load_png_from_buffer(bytes)
		"jpg", "jpeg": err = img.load_jpg_from_buffer(bytes)
		"webp": err = img.load_webp_from_buffer(bytes)
		"bmp": err = img.load_bmp_from_buffer(bytes)
		"tga": err = img.load_tga_from_buffer(bytes)
	if err != OK:
		return null
	return img


## En el juego exportado las imágenes del proyecto no quedan como archivo suelto: Godot
## guarda la versión importada. Se carga esa y se le saca la imagen.
static func _imported(path: String) -> Image:
	if not path.begins_with("res://") or not ResourceLoader.exists(path):
		return null
	var tex = ResourceLoader.load(path)
	if tex is Texture2D:
		var img: Image = tex.get_image()
		if img != null and not img.is_empty():
			if img.is_compressed():
				img.decompress()
			return img
	return null
