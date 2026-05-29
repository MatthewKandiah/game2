#version 450

#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec4 fragColour;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in flat int texIdx;

layout(binding = 1) uniform sampler2D texSamplers[2];

layout(location = 0) out vec4 outColour;

void main() {
  if (fragColour.a == 1) {
    outColour = fragColour;
    return;
  }
  vec4 sampledColour = textureLod(nonuniformEXT(texSamplers[texIdx]), texCoord, 0);
  if (sampledColour.a < 1 || sampledColour.r == 0) {
    discard;
  }
  outColour.rgb = fragColour.rgb;
  outColour.a = 1;
}
