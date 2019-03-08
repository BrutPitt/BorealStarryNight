#ifdef GL_ES
precision mediump float;
#endif

//Show comet
#define COMET

//varing light intensity for stars
//#define FRACTAL_SKY
//#define PULSED_STARS //for FRACTAL_SKY only

//Fixed external textures for sky and terrain...
//#ifdef EXTERNAL_TEXT

//for use in shadertoy environment or similia
//#define SHADERTOY

//For infrequent and mor smoothed comet
//#define SMOOTH_COMET

#ifdef EXTERNAL_TEXT
varying vec2 v_texCoord;
#endif


//#define SHADERTOY
#ifdef SHADERTOY

float time = iGlobalTime;
vec2 mouseR = vec2(0.);
vec2 mouseL = vec2(0.);
vec2 resolution = iResolution.xy;
// sampler2D skyTex;
// sampler2D landTex;

#else
uniform float time;
uniform vec2 mouseR;
uniform vec2 mouseL;
//vec2 mouse = vec2(0.0);
uniform vec2 resolution;
uniform sampler2D skyTex;
uniform sampler2D landTex;

#endif

const vec3 starColor = vec3(.43,.57,.97);

float contrast(float valImg, float contrast) { return clamp(contrast*(valImg-.5)+.5, 0., 1.); }
vec3  contrast(vec3 valImg, float contrast)  { return clamp(contrast*(valImg-.5)+.5, 0., 1.); }

float gammaCorrection(float imgVal, float gVal)  { return pow(imgVal, 1./gVal); }
vec3  gammaCorrection(vec3 imgVal, float gVal)   { return pow(imgVal, vec3(1./gVal)); }

//Get color luminance intensity
float cIntensity(vec3 col) { return dot(col, vec3(.299, .587, .114)); }


float hash( float n ) { return fract(sin(n)*758.5453); }
highp float rand(vec2 p) { return fract(sin(dot(p ,vec2(1552.9898,78.233))) * 43758.5453); }


float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    float n = p.x + p.y*57.0 + p.z*800.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
		    mix(mix( hash(n+800.0), hash(n+801.0),f.x), mix( hash(n+857.0), hash(n+858.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{

    float f  = 0.50000*noise( p ); p *= 2.02;
          f += 0.25000*noise( p ); p *= 2.03;
          f += 0.12500*noise( p ); p *= 2.01;
          f += 0.06250*noise( p ); p *= 2.04;
          f += 0.03125*noise( p );
    return f*1.032258;
}


float fbm2( vec3 p )
{

    float f  = 0.50000*noise( p ); p *= 2.021;
          f += 0.25000*noise( p ); p *= 2.027;
          f += 0.12500*noise( p ); p *= 2.01;
          f += 0.06250*noise( p ); p *= 2.03;
          f += 0.03125*noise( p ); p *= 4.01;
          f += 0.015625*noise( p );p *= 8.04;
          f += 0.00753125*noise( p );
    return f*1.05;
}

float borealCloud(vec3 p)
{
	p+=fbm(vec3(p.x,p.y,0.0)*0.5)*2.25;
	float a = smoothstep(.0, .9, fbm(p*2.)*2.2-1.1);
    
	return a<0.0 ? 0.0 : a;
}

vec3 smoothCloud(vec3 c)
{
	
	c*=0.75-length(gl_FragCoord.xy / resolution.xy -0.5)*0.75;
	float w=length(c);
	c=mix(c*vec3(1.0,1.2,1.6),vec3(w)*vec3(1.,1.2,1.),w*1.25-.25);
	return clamp(c,0.,1.);
}

float fractalField(in vec3 p,float s,  int idx) {
   float strength = 7. + .03 * log(1.e-6 + fract(sin(time) * 4373.11));
   float accum = s/4.;
   float prev = 0.;
   float tw = 0.;
   for (int i = 0; i < 24; ++i) {
      float mag = dot(p, p);
      p = abs(p) / mag + vec3(-.5, -.4, -1.5);
      float w = exp(-float(i) / 4.8);
      accum += w * exp(-strength * pow(abs(mag - prev), 2.7));
      tw += w;
      prev = mag;
   }
   return max(0., 5. * accum / tw - .7);
}

vec3 nrand3( vec2 co )
{
   vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
   vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
   vec3 c = mix(a, b, 0.5);
   return c;
}

#ifdef PULSED_STARS
float starField(vec2 p)
{
   vec3 rnd = nrand3(p * resolution.x);
   float intensity = pow((1.+sin((time+27.)*rnd.x))*.5, 7.) ;
   return max(rnd.x * pow(rnd.y,7.) * intensity, 0.);

}
#else
float starField(vec2 p)
{
   vec3 rnd = nrand3(p * resolution.x);
   return pow(abs(rnd.x + rnd.y + rnd.z)/2.93,9.7);

}
#endif

#define iterations 16
#define formuparam 0.53 //77

#define volsteps 4
#define stepsize 0.00733

#define zoom   1.2700
#define tile   .850
#define speed  0.000

#define brightness 0.0007
#define darkmatter .1700
#define distfading 1.75
#define saturation .250


vec3 starr(vec2 UV)
{
    float ratio = resolution.y/resolution.x;
	//get coords and direction
	vec2 uv=UV*.3723+vec2(0.,-.085); //-mouseL;
	uv.y*= ratio;
	vec3 dir=vec3(uv*zoom/ratio,1.);

	dir.xz*=mat2(.803, .565, .565, .803);
	dir.xy*=mat2(.9935,.0998,.0998,.9935);

    vec3 from=vec3(-0.4299,-0.7817,-0.3568);

	//volumetric rendering
	float s=0.0902,fade=.7;
	float v=0.;
	for (int r=0; r<volsteps; r++) {
		vec3 p=from+s*dir*-9.9;
		p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
		float pa,a=pa=0.;

		for (int i=0; i<iterations; i++) {
			p=abs(p)/dot(p,p)-formuparam; // the magic formula
			a+=abs(length(p)-pa); // absolute sum of average change
			pa=length(p);
		}
		a*=a*a; // add contrast
		v+=fade;
		v+=s*a*brightness*fade; // coloring based on distance
		fade*=distfading; // distance fading
		s+=stepsize;
	}
    v = contrast(v *.009, .95)-.05;
    vec3 col = vec3(.43,.57,.97) * 1.7 * v;

    col = gammaCorrection(col, .7);

	return col + vec3(.67,.83,.97) * vec3(starField(UV)) * .9;

}

//besselham line function
//creates an oriented distance field from o to b and then applies a curve with smoothstep to sharpen it into a line
//p = point field, o = origin, b = bound, sw = StartingWidth, ew = EndingWidth, 
float shoothingStarLine(vec2 p, vec2 o, vec2 b, float sw, float ew){
	float d = distance(o, b);
	vec2  n = normalize(b - o);
	vec2 l = vec2( max(abs(dot(p - o, n.yx * vec2(-1.0, 1.0))), 0.0),
	               max(abs(dot(p - o, n) - d * 0.5) - d * 0.5, 0.0));
	return smoothstep( mix(sw, ew, 1.-distance(b,p)/d) , 0., l.x+l.y);
}

#ifdef SMOOTH_COMET
vec3 smoothComet(vec2 p)
{
const float modu = 16.;        // Timer in sec  4.
const float endPointY = .1; // Punto di sparizione Y
vec2 cmtVel = mod(time/modu+modu*.5, 2.) > 1. ? vec2(2., 1.4)*.5 : vec2(-2.,  1.4)*.5;  // Vel. component X,Y


    vec2 cmtPt = 1. - mod(time*cmtVel, modu);
    cmtPt.x +=1.;

    vec2 cmtStartPt, cmtEndPt;

    vec2 cmtLen = vec2(.125)*cmtVel*clamp(cmtPt.y*2., 0., 1.); //cmt lenght

    if(cmtPt.y < endPointY) {
        cmtEndPt   = cmtPt + cmtLen;
        if(cmtEndPt.y > endPointY) cmtStartPt = vec2(cmtPt.x + cmtLen.x*((endPointY - cmtPt.y)/cmtLen.y), endPointY);
        else                       return vec3(.0);
    }
    else {
        cmtStartPt = cmtPt;
        cmtEndPt = cmtStartPt+cmtLen;
    }


    float bright = clamp(smoothstep(-.2,.65,distance(cmtStartPt, cmtEndPt)),0.,1.);



    float q = clamp( (p.y+.2)*2., 0., 1.);
    float mag = q* 2.;
    vec2 dlt = vec2(.003) * cmtVel;

    return  ( bright  * .75 *  (smoothstep(0.993, 0.999, 1. - length(p - cmtStartPt)) +
                     shoothingStarLine(p, cmtStartPt, cmtStartPt+vec2(.06)*cmtVel,  0.009*mag, 0.003)) +   //bulbo cmta
              vec3(1., .7, .2) * .33 * shoothingStarLine(p, cmtStartPt,         cmtEndPt,        0.003*mag, .0003) +          // scia ...
              vec3(1., .5, .1) * .33 * shoothingStarLine(p, cmtStartPt+dlt,     cmtEndPt+dlt*2.*q, 0.002*mag ,.0002) +         // ...
              vec3(1., .3, .0) * .33 * shoothingStarLine(p, cmtStartPt+dlt+dlt, cmtEndPt+dlt*4.*q, 0.001*mag, .0001)            //
            ) * (bright) *
            q * q; //attenuation on Y
}
#else
vec3 comet(vec2 p)
{
const float modu = 4.;        // Timer in sec
const float endPointY = -.125; // Punto di sparizione Y
vec2 cmtVel = mod(time/modu+modu*.5, 2.) > 1. ? vec2(2., 1.4)*.5 : vec2(-2., 1.4)*.5;  // Velocity component X,Y
vec2 cmtLen = vec2(.25)*cmtVel; //cmt lenght

    vec2 cmtPt = 1. - mod(time*cmtVel, modu);
    cmtPt.x +=1.;

    vec2 cmtStartPt, cmtEndPt;

    if(cmtPt.y < endPointY) {
        cmtEndPt   = cmtPt + cmtLen;
        if(cmtEndPt.y > endPointY) cmtStartPt = vec2(cmtPt.x + cmtLen.x*((endPointY - cmtPt.y)/cmtLen.y), endPointY);
        else                       return vec3(.0);
    }
    else {
        cmtStartPt = cmtPt;
        cmtEndPt = cmtStartPt+cmtLen;
    }

    float bright = clamp(smoothstep(-.2,.65,distance(cmtStartPt, cmtEndPt)),0.,1.);

    vec2 dlt = vec2(.003) * cmtVel;

    float q = clamp( (p.y+.2)*2., 0., 1.);

    return  ( bright  * .75 *  (smoothstep(0.993, 0.999, 1. - length(p - cmtStartPt)) + shoothingStarLine(p, cmtStartPt, cmtStartPt+vec2(.06)*cmtVel,  0.009, 0.003)) +   //bulbo cmta
              vec3(1., .7, .2) * .33 * shoothingStarLine(p, cmtStartPt,         cmtEndPt,        0.003, .0003) +          // scia ...
              vec3(1., .5, .1) * .33 * shoothingStarLine(p, cmtStartPt+dlt,     cmtEndPt+dlt*2., 0.002 ,.0002) +         // ...
              vec3(1., .3, .0) * .33 * shoothingStarLine(p, cmtStartPt+dlt+dlt, cmtEndPt+dlt*4., 0.001, .0001)            //
            ) * (bright) *
            q ; //attenuation on Y
}
#endif

#define SMOOTH_V(V,R)  { float p = position.y-.2; if(p < (V)) { float a = p/(V); R *= a *a ;  } }

void main( void ) {

#ifdef SHADERTOY
    mouseL = iMouse.zw / resolution;
#endif
    vec2 mouseLeft = vec2(0.0);
    vec2 mouse = mouseL;

	vec2 position = ( gl_FragCoord.xy / resolution );
    vec2 uv = 2. * position - 1.;
	
    position.y+=0.2;

	vec2 coord= vec2((position.x-0.5)/position.y,1./(position.y+.2));

	float tm = time * .75 * .5;
	coord+=tm*0.0275 + vec2(1. - mouse.x, mouse.y);
	vec2 coord1=coord - tm*0.0275 + vec2(1. - mouse.x, mouse.y);

	
    vec2 ratio = resolution / max(resolution.x, resolution.y);;
    vec2 uvs = uv * ratio;

// Boreal effects
////////////////////////////////////
    // CloudColor * cloud * intensity
    vec3 boreal = vec3 (vec3(.1,1.,.5 )  * borealCloud(vec3(coord*vec2(1.2,1.), tm*0.22)) * .9  +
                        //vec3(.0,.7,.7 )  * borealCloud(vec3(coord1*vec2(.6,.6)  , tm*0.23)) * .5 +
                        vec3(.1,.9,.7) * borealCloud(vec3(coord*vec2(1.,.7)  , tm*0.27)) *  .9 +
                        vec3(.75,.3,.99) * borealCloud(vec3(coord1*vec2(.8,.6)  , tm*0.29)) *  .5 +
                        vec3(.0,.99,.99)  * borealCloud(vec3(coord1*vec2(.9,.5)  , tm*0.20)) *  .57);
                        

    SMOOTH_V(.5,boreal);
    SMOOTH_V(.35,boreal);
    SMOOTH_V(.27,boreal);

    boreal = smoothCloud(boreal);
    boreal = gammaCorrection(boreal,1.3);


#ifdef EXTERNAL_TEXT
	vec2 vCoord = vec2(v_texCoord.x, 1.-v_texCoord.y);
#endif


// Sky background (fractal)
////////////////////////////////////
#ifdef FRACTAL_SKY
    // point position sky fractal    
    vec3 skyPt = vec3(uvs / 6., 0) + vec3(-1.315, .39, 0.);  //pt + pos
    
    skyPt.xy += vec2(- mouseLeft.x*.5*ratio.x, - mouseLeft.y * .5*ratio.y);

    //fractal
    vec3 freq = vec3(0.3, 0.67, 0.87);
    float ff = fractalField(skyPt,freq.z, 27);

    vec3 sky =  vec3 (.75, 1., 1.4) * .05 * pow(2.4,ff*ff*ff)  * freq ;
#else
    vec3 sky =  vec3 (0.);
#endif

// Moon
////////////////////////////////////
    vec2 moonPos = vec2(0.77,-.57) * ratio;
    float len = 1. - length((uvs - moonPos) ) ;
    // moon
    vec3 moon = vec3(.99, .7, .3) * clamp(smoothstep(0.95, 0.957, len) - 
                                          smoothstep(0.93, 0.957, 1. - length(uvs - (moonPos + vec2(0.006, 0.006)) ) - .0045)
                                          , 0., 1.) 

                                          * 2.;
    vec3 haloMoon  = vec3(.0,  .2,  .7)  * 0.2     * smoothstep(0.4, 0.9057, len);
         haloMoon += vec3(.5,  .5,  .85) * 0.0725  * smoothstep(0.7, 0.995,  len);

// Shooting star
////////////////////////////////////
#ifdef COMET
    vec3 cometA = comet(uvs);
#endif


// Terrain
////////////////////////////////////
         float ground = smoothstep(0.07,0.0722,fbm2(vec3((position.x-mouse.x)*5.1, position.y,.0))*(position.y-0.158)*.9+0.01);

// Horizon Light
////////////////////////////////////
         float pos = 1. - position.y;
         vec3 sunrise = vec3(.6,.3,.99) * (pos >  .45  ? (pos - .45)  * .65  : 0.) +  
                        vec3(.0,.7,.99) * (pos >= .585 ? (pos - .585  ) * .6  : 0.) +
                        vec3(.5,.99,.99)* (pos >= .67  ? (pos - .67) * .99 : 0.) ; 

// StarField
////////////////////////////////////
#ifdef FRACTAL_SKY
         vec3 starColor = vec3(starField(uv));
#else

         vec3 starColor = starr(uv);
         SMOOTH_V(.37,starColor);
#endif

// Intensity attenuation
////////////////////////////////////
         float ib = clamp(1.0-cIntensity(boreal)*3.,0.,1.);
         ib*=ib;
         float im = 1.0-cIntensity(moon);
         float ih = 1.0-cIntensity(haloMoon)*8.;
         float is = 1.0-cIntensity(sunrise)*6.;


         sky += ((moon + haloMoon)*ib*ib) * is * is +
                sunrise +
#ifdef COMET
                cometA +
#endif
                starColor  * ib *ib /*vec3(.3,.63,.97)*/  * im * im * ih * ih * is * is;

		 gl_FragColor =  vec4(boreal + sky, 1.) * ground;

}
