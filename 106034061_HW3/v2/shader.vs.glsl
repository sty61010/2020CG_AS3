#version 330

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec3 aNormal;
layout (location = 3) in vec2 aTexCoord;
out vec2 texCoord;

//uniform mat4 um4p;    // projection matrix
//uniform mat4 um4v;    // camera viewing transformation matrix
//uniform mat4 um4m;    // rotation matrix

out vec3 vertexInViewToFS;    // calculate lighting of vertex in camera space
out vec3 normalInViewToFS;    // calculate lighting of normal in camera space
out vec4 colorInVertex;           // vertex lighting color
vec4 vertexInView;
vec4 normalInView;
struct LightInfo{
    vec4 position;
    vec4 spotDirection;
    vec4 La;            // Ambient light intensity
    vec4 Ld;            // Diffuse light intensity
    vec4 Ls;            // Specular light intensity
    float spotExponent;
    float spotCutoff;
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
};
struct MaterialInfo{
    vec4 Ka;
    vec4 Kd;
    vec4 Ks;
    float shininess;
};
uniform mat4 um4p;    // Projection matrix
uniform mat4 shaderV;    // Viewing  matrix
//uniform mat4 um4n;    // Model normalization matrix
uniform mat4 shaderM;    // Model matrix
uniform int lightIdx;            // Use this variable to contrl perpixel lighting mode
uniform LightInfo light[3];
uniform MaterialInfo material;

vec4 directionalLight(vec3 N, vec3 V){
    vec4 lightInView = shaderV * light[0].position;    // the position of the light in camera space
//    lightInView *=-1;
    vec3 S = normalize(lightInView.xyz + V);
    vec3 H = normalize(S + V);                        // Half vector
    // GT: calculate diffuse coefficient and specular coefficient here
    float dc = dot(N,S);
//    float sc = pow(max(dot(N, H), 0), 64);
    float sc = pow(max(dot(N, H), 0), material.shininess);
    return light[0].La * material.Ka + dc * light[0].Ld * material.Kd + sc * light[0].Ls * material.Ks;
}

vec4 pointLight(vec3 N, vec3 V){
    // GT: Calculate point light intensity here
    vec4 lightInView = shaderV * light[1].position;    // the position of the light in camera space
//    lightInView *=-1;
    vec3 S = normalize(lightInView.xyz + V);
    vec3 H = normalize(S + V);                        // Half vector
    // GT: calculate diffuse coefficient and specular coefficient here
    float dc = max(dot(N,S), 0);
//    float sc = pow(max(dot(N, H), 0), 64);
    float sc = pow(max(dot(N, H), 0), material.shininess);
//    float d = length(lightInView.xyz + V)-1;
    float d = length(vertexInViewToFS - lightInView.xyz);
    float fp = 1.0/(light[1].constantAttenuation + light[1].linearAttenuation * d + light[1].quadraticAttenuation * d * d);
    return light[1].La * material.Ka + fp * (dc * light[1].Ld * material.Kd + sc * light[1].Ls * material.Ks);
}

vec4 spotLight(vec3 N, vec3 V){
    // GT: Calculate spot light intensity here
    vec4 lightInView = shaderV * light[2].position;
    vec3 S = normalize(lightInView.xyz + V);
    vec3 H = normalize(S + V);
    // GT: also need diffuse and specular coefficient
    float dc = dot(N, S);
//    float sc = pow(max(dot(N, H), 0), 64);
    float sc = pow(max(dot(N, H), 0), material.shininess);
//    vec3 VP = vertexInViewToFS - lightInView.xyz;
    float Distance = length(vertexInViewToFS - lightInView.xyz);
    vec3 spotDirectionInView = vec4(shaderV * light[2].spotDirection).xyz;
    float spotExponent = light[2].spotExponent;
    float spotDot = dot(normalize(vertexInViewToFS - lightInView.xyz), normalize(spotDirectionInView));
    float cutoff = cos(light[2].spotCutoff);
    float spotFactor = (spotDot > cutoff) ? pow(spotDot, spotExponent) : 0.0;
    float f_att = min(1.0 / (light[2].constantAttenuation +
                      light[2].linearAttenuation * Distance +
                      light[2].quadraticAttenuation * Distance * Distance), 1) * spotFactor;
    return light[2].La * material.Ka + ( dc * light[2].Ld * material.Kd + sc * light[2].Ls * material.Ks) * f_att;
}

void main() {
//debug

//    vertexInView = shaderV * um4n * shaderM * vec4(aPos, 1.0);
    vertexInView = shaderV *  shaderM * vec4(aPos, 1.0);
//    normalInView = transpose( inverse(shaderV * um4n * shaderM)) * vec4(aNormal, 0.0);
    normalInView = transpose( inverse(shaderV * shaderM)) * vec4(aNormal, 0.0);
    vertexInViewToFS = vertexInView.xyz;
    normalInViewToFS = normalInView.xyz;

    vec3 N = normalize(normalInView.xyz);        // N represents normalized normal of the model in camera space
    vec3 V = -vertexInView.xyz;                    // V represents the vector from the vertex of the model to the camera position
    if(lightIdx == 0){
        colorInVertex = directionalLight(N, V);}
    else if(lightIdx == 1){
        colorInVertex = pointLight(N, V);}
    else if(lightIdx == 2){
        colorInVertex = spotLight(N ,V);}
    texCoord = aTexCoord;
    
    gl_Position = um4p * shaderV * shaderM * vec4(aPos, 1.0);
//	gl_Position = um4p * um4v * um4m * vec4(aPos, 1.0);
}
