varying highp vec2 textureCoordinate;
 
uniform sampler2D inputImageTexture;
uniform lowp float contrast;

void main()
{
 lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
 
 gl_FragColor = vec4(((textureColor.rgb - vec3(0.5)) * contrast + vec3(0.5)), textureColor.w);
}