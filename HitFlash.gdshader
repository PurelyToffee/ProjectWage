shader_type canvas_item;

uniform bool active = false;
uniform sampler2D gradient : hint_default_white, repeat_disable, filter_linear;
uniform float stp = 1.;


void fragment() {
    vec4 original = texture(TEXTURE, UV);

	if (!active) {
        COLOR = original;
    }
	else
	{

		float val = (original.r + original.g + original.b)/3.0;
		float res = round(val/stp) * stp;
		
		if(val > 0.95){
			
			COLOR = texture(gradient, vec2(1., 0.5));
		}
		else
		{
			COLOR = texture(gradient, vec2(0., 0.5));
		}
		
	}
}