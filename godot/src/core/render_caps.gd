class_name RenderCaps
## One question, asked everywhere: are we on the mobile-friendly
## Compatibility renderer (GL) or a full Forward+/Mobile Vulkan pipeline?
## Forward+-only environment features (SSAO/SSIL/SSR/volumetric fog) gate
## on this so the same scenes run clean on phones and web exports.

static var _cached := ""

static func is_compatibility() -> bool:
	if _cached == "":
		var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"))
		# Runtime override: web/mobile, headless automation (--headless runs
		# with no GPU, so Terrain3D clipmap shaders / Forward+-only effects
		# cannot ever work), or software GL (llvmpipe/swiftshader on CI Xvfb)
		# all take the compatibility fallback path.
		if OS.has_feature("web") or OS.has_feature("mobile") \
				or DisplayServer.get_name() == "headless":
			_cached = "compatibility"
		else:
			var adapter := str(RenderingServer.get_video_adapter_name()).to_lower()
			if adapter.contains("llvmpipe") or adapter.contains("swiftshader"):
				_cached = "compatibility"
			else:
				_cached = method
	return _cached.contains("compatibility")
