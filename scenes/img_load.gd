class_name ImgLoad
## Carga una imagen (PNG, JPG o WEBP) leyendo sus bytes. Funciona igual en el editor, en
## user:// y dentro del paquete del juego exportado (donde no hay archivos sueltos en el
## disco y Image.load_from_file con una ruta del sistema no los encuentra).

static func load(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
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
