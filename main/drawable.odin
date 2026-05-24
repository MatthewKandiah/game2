package main

Drawable :: struct {
  pos:             Pos,
  z:               f32,
  dim:             Dim,
  texture_data:    TextureData,
  override_colour: bool,
  colour:          Colour,
}

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
