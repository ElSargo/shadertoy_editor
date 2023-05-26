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

float hash(vec2 p){
	return fract(3.12312*dot(p,p*01.123));
}
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UI4 uvec4(UI3, 1979697957U)
#define UIF (1.0 / float(0xffffffffU))
float hash13(uvec3 q)
{
	q *= UI3;
	uint n = (q.x ^ q.y ^ q.z) * UI0;
	return float(n) * UIF;
}

float hash(vec3 p)
{
	uvec3 q = uvec3(ivec3(p)) * UI3;
	uint n = (q.x ^ q.y ^ q.z) * UI0;
	return float(n) * UIF;
}



float smix(float a,float b,float t){
	return mix( a, b, smoothstep(0.,1.,t) ) ;
}

float n(vec2 p){
	vec2 f = floor(p);
	vec2 t = fract(p);
	vec2 tr = f + vec2(1.,1.);
	vec2 tl = f + vec2(0.,1.);
	vec2 br = f + vec2(1.,0.);
	vec2 bl = f;
	float htr = hash(tr);
	float htl = hash(tl);
	float hbr = hash(br);
	float hbl = hash(bl);
	float mt = smix(htl,htr,t.x);
	float mb = smix(hbl,hbr,t.x);
	return smix(mb,mt,t.y);
	
}

 vec4 nd( in vec3 x )
 {
    vec3 p = floor(x);
    vec3 w = fract(x);

    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);

    float a = hash( p+vec3(0,0,0) );
    float b = hash( p+vec3(1,0,0) );
    float c = hash( p+vec3(0,1,0) );
    float d = hash( p+vec3(1,1,0) );
    float e = hash( p+vec3(0,0,1) );
    float f = hash( p+vec3(1,0,1) );
    float g = hash( p+vec3(0,1,1) );
    float h = hash( p+vec3(1,1,1) );

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z),
                 2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                 k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                 k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
}

mat2 rot(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}


vec4 fbmd( in vec3 x )
{

    float f = 1.78;  // could be 2.0
    float s = 0.54;  // could be 0.5
    float a = 0.0;
    float b = 0.5;
    vec3  d = vec3(0.0);
    mat3  m = mat3(1.0,0.0,0.0,
    0.0,1.0,0.0,
    0.0,0.0,1.0);
    for( int i=0; i < 4; i++ )
    {
	    
        vec4 n = nd(x);
        a += b*n.x;          // accumulate values
        d += b*m*n.yzw;      // accumulate derivatives
        b *= s;
        x = f*m*x;
	x.xy *= rot(1.23123);
	x.zy *= rot(-2.23123);
        //m = f*m*mat3(1.,-1.,1.,-1,1.,-1.,1.,-1.,1.);
    }
    return vec4( a, d );
}



float fbm(vec2 p){
	float T = 0.;
	T += n(p);
	p *= rot(1.2);
	T += n(p*1.5)/1.5;
	p *= rot(1.2);
	T += n(p*2.5)/2.5;
	p *= rot(1.2);
	T += n(p*10.)/10.;
	p *= rot(1.2);
	T += n(p*20.)/20.;
	return T;
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
	float g = 0.;
	vec3 ccol = vec3(0.);
	if (rd.y > 0.) {
	
	
     		float cd = 10./rd.y;
		vec3 p = rd*cd;
		for (int i=0; i<1;i++){
		
			
			vec4 d = fbmd(p*vec3(0.1,20.,0.1)+.5+iTime*0.1);
			
			g +=max(0., d.x);
			vec3 col = mix(vec3(1.),vec3(0.2), smoothstep(0.,1.,dot(sun,d.yxz)));
			ccol += col;
		}
		clamp(ccol, vec3(0.), vec3(1.));
        } 
     return mix(mix(light,ccol,g),vec3(0.7), smoothstep(0.,-.1,rd.y));
}




const int raymarchsteps = 150;
float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float map(vec3 p){
    p.x += (sin(p.y*10.)+sin(p.z*10.))*0.06;
    p.z += (sin(p.x*10.)+sin(p.y*10.))*0.06;
    p.y += (sin(p.x*10.)+sin(p.z*10.))*0.06;
    float d = sdSphere(p, 1.);
    d = min(d, p.y+1.);
	if (d < 1.){
		d += fbmd(p).x*0.5;
	}
    return d;
}

float intersection(vec3 ro, vec3 rd){
    float T=0.;
    for(int i=0;i<raymarchsteps;i++){
        float d = map(ro+rd*T);
        T += d;
        if (abs(d) < 0.002*T  || T > 100.){
            break;
        }
    }
    return T;
}

vec3 softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k ){
    float res = 1.0;
	float t = mint;
    for (int i=0; i<20; i++ )
    {
	    if (t > maxt){
		break;    
	    }
        float h = map(ro + rd*t);
        if( h<0.001 )
            return vec3(0.0);
        res = min( res, k*h/t );
        t += h;
    }
    return res*exp(res*vec3(4.,2.,1.)*0.1);//*smoothstep(0.,1., fbm(ro.xz*0.1+iTime) );
}

vec3 calcNormal( in vec3  p , float T) // for function f(p)
{
    float h = 0.0001 * T; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*map( p + k.xyy*h ) + 
                      k.yyx*map( p + k.yyx*h ) + 
                      k.yxy*map( p + k.yxy*h ) + 
                      k.xxx*map( p + k.xxx*h ) );
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
    
    vec3 sun = normalize(vec3(sin(iTime),1.,cos(iTime)));
    vec3 scl = vec3(1.10,0.892,0.631);
            vec3 pos = vec3(0,63.72,0);
    vec3 bcl = vec3(1.000,1.000,1.000);
    if (dist < 0.1){
    
        vec3 nor = calcNormal(p, T);
        float occ = calcAO(p, nor)*0.95+0.05;
        vec3 sha = softshadow(p, sun, 0.01, 5., 4.);
        float nds = max(0., dot(nor, sun));
        vec3 hvc = normalize(sun - rd);
        vec3 ref = reflect(rd, nor);
        float frez = pow(sqrt(1.+dot(rd, ref)*0.5),9.);
        col += 8.*bcl*scl*nds*sha*scl;
        col += 5.*max(0.001, pow(dot(nor, hvc),70.));
        col += getSky(vec3(ref.x,ref.y,ref.z), pos, sun)*occ*frez*0.7;
        col += pow(smoothstep(1.,-0.1,dot(-sun, nor)),.1)*scl*bcl*2.*occ;
        //col = vec3(frez);
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

void mainImage( out vec4 fragColor , in vec2 fragCoord)
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 nuv = (uv-0.5)*vec2(1.,iResolution.y/iResolution.x);
    
    vec3 ro = vec3(0., 0., 4.);
    vec3 rd = normalize(vec3(nuv, -0.7));
    
    vec3 col = render(ro, rd);
    
    col /= 8.;
    col = pow(col,vec3(.8));
    col *= smoothstep(.9,0.1,length(uv-0.5));
    fragColor =  vec4(aces_tonemap(col),1.0);
}
