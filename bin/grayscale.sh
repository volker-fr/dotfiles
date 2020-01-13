#!/bin/sh
compton --inactive-dim 0.2 --backend glx --glx-fshader-win \
"
uniform float opacity;
uniform bool invert_color;
uniform sampler2D tex;

void main() {
    vec4 c = texture2D(tex, gl_TexCoord[0].xy);
    float y = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    gl_FragColor = vec4(y, y, y, 1.0);
}
"
