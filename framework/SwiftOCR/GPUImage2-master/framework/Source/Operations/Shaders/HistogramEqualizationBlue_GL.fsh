varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
    
    gl_FragColor = vec4(textureColor.r, textureColor.g, blueCurveValue, textureColor.a);
}