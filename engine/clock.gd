class_name Clock
extends RefCounted
## Reloj de las animaciones de dibujo. Normalmente es Time.get_ticks_msec(); las pruebas de
## capturas (tests/golden_shots.gd) lo congelan para que cada captura salga igual.

static var frozen := -1


static func ms() -> int:
	return frozen if frozen >= 0 else Time.get_ticks_msec()
