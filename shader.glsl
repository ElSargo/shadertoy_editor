const float Earth = 63.71;
const float AtRad = 64.01;
const float directScatterCoef = .02;
const float inDirectScatterCoef = .3;
const float sunCoef = .1;
const vec3 rgbScatter = vec3(1,2,4);

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

vec3 getSky(vec3 rd, vec3 pos, vec3 sun){
//Distances, proportaional to the real world
    float atDist = sphIntersect(pos, rd, vec3(0), AtRad).y;
    float snDist = sphIntersect(pos, sun,vec3(0), AtRad).y-1.1;
    
    float rds = dot(sun, rd);
    float ssc = (abs(rds)*0.5+0.5);
    vec3 tra = normalize(sun-rd);
    vec2 jab = vec2(
    max(tra.x, max(tra.y, tra.z)),
    min(tra.x, max(tra.y, tra.z))
    );
    float fla = pow(abs(sin(atan(jab.x,jab.y)*40.)), 100.)*.001;

    vec3 light = vec3(smoothstep(0.999, .9999, rds))*2.;
         light += atDist * (1.-abs(rd.y)) * ssc*0.2;
         light += (1.-exp(-rgbScatter*atDist*inDirectScatterCoef*(atDist*5.*.5+.5)));
         light *= exp(
             -rgbScatter*
             (atDist*directScatterCoef+snDist*sunCoef)
         );
         
     return light;
}

mat2 rot(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}


const int raymarchsteps = 150;
float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float map(vec3 p){
    float d = sdSphere(p, 1.);
    d = min(d, p.y+1.);
    return d;
}

float intersection(vec3 ro, vec3 rd){
    float T=0.;
    for(int i=0;i<raymarchsteps;i++){
        float d = map(ro+rd*T);
        T += d;
        if (abs(d) < 0.001*T  || T > 100.){
            break;
        }
    }
    return T;
}

vec3 softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k ){
    float res = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return vec3(0.0);
        res = min( res, k*h/t );
        t += h;
    }
    return res*exp(res*vec3(4.,2.,1.)*0.1);
}


vec3 calcNormal( in vec3 p , in float T){
    float h = 0.0001*T;
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h);
    }
    return normalize(n);
}
float calcAO(vec3 pos, vec3 nor){
	float occ = 0.0;
    float sca = .4;
    for( int i=0; i<5; i++ )
    {
            float h = 0.01 + 0.25*float(i)/4.0;
        float d = map( pos+h*nor);
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

vec3 render(vec3 ro, vec3 rd){
    float T = intersection(ro, rd);
    vec3 p = ro+rd*T;
    float dist = map(p);
    
    vec3 col = vec3(0.);
    
    vec3 sun = normalize(vec3(-5.2,1.,0.4));
    vec3 scl = vec3(0.910,0.792,0.631);
            vec3 pos = vec3(0,63.72,0);
    vec3 bcl = vec3(1.000,1.000,1.000);
    if (dist < 0.1){
    
        vec3 nor = calcNormal(p, T);
        float occ = calcAO(p, nor)*0.95+0.05;
        vec3 sha = softshadow(p, sun, 0.1, 5., 4.);
        float nds = max(0., dot(nor, sun));
        vec3 hvc = normalize(sun - rd);
        vec3 ref = reflect(rd, nor);
        float frez = .5+.5*dot(rd, ref);
        col += 8.*bcl*scl*nds*sha*scl;
        col += 5.*max(0.001, pow(dot(nor, hvc),70.));
        col += getSky(vec3(ref.x,abs(ref.y),ref.z), pos, sun)*occ*frez;
        col += pow(smoothstep(1.,-0.1,dot(-sun, nor)),.1)*scl*bcl*2.*occ;
        
    } else {
        col = getSky(rd, pos,sun)*5.;
    }
    return col;
}

vec3 aces_tonemap(vec3 color){	
	mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
	);
	mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
	);
	vec3 v = m1 * color;    
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 nuv = (uv-0.5)*vec2(1.,iResolution.y/iResolution.x);
    
    vec3 ro = vec3(0., 0., 4.);
    vec3 rd = normalize(vec3(nuv, -0.7));
    
    vec3 col = render(ro, rd)*2.;
    
    col /= 8.;
    col *= smoothstep(.9,0.1,length(uv-0.5));
    fragColor = vec4(aces_tonemap(col),1.0);
}