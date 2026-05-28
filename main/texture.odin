package main

TextureType :: enum {
  Sprite,
  Mask,
}

TextureData :: struct {
  base:    Pos,
  dim:     Dim,
  tex_idx: i32,
  type:    TextureType,
}

FontTexture :: enum {
  Ubuntu,
  UbuntuMono,
}
font_texture_to_idx :: proc(ft: FontTexture) -> i32 {
  return cast(i32)ft
}
FONT_TEXTURE_PATHS := [FontTexture]string {
  .Ubuntu     = "assets/Ubuntu-R.ttf",
  .UbuntuMono = "assets/UbuntuMono-R.ttf",
}
FONT_IMAGE_OUT_PATHS := [FontTexture]cstring {
  .Ubuntu     = "build/Ubuntu-R.png",
  .UbuntuMono = "build/UbuntuMono-R.png",
}
FONT_TEXTURE_ASSETS_COUNT :: len(FONT_TEXTURE_PATHS)
MASK_FRAGMENT_SHADER_EXPECTED_TEXTURE_COUNT :: 2
#assert(
  FONT_TEXTURE_ASSETS_COUNT == MASK_FRAGMENT_SHADER_EXPECTED_TEXTURE_COUNT,
  "fragment shader hardcodes expected number of texture samplers it can handle, if this fails because we've changed the number of texture assets, we need to remember to update the fragment shader too",
)

Texture :: enum {
  Gradient,
  Yellow,
}
texture_to_idx :: proc(t: Texture) -> i32 {
  return cast(i32)t
}
TEXTURE_PATHS :: [Texture]cstring {
  .Gradient = "assets/gradient.png",
  .Yellow   = "assets/yellow.png",
}
TEXTURE_ASSETS_COUNT :: len(TEXTURE_PATHS)
SPRITE_FRAGMENT_SHADER_EXPECTED_TEXTURE_COUNT :: 2
#assert(
  TEXTURE_ASSETS_COUNT == SPRITE_FRAGMENT_SHADER_EXPECTED_TEXTURE_COUNT,
  "fragment shader hardcodes expected number of texture samplers it can handle, if this fails because we've changed the number of texture assets, we need to remember to update the fragment shader too",
)
