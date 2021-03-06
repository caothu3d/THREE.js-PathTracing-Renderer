#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 4
#define N_QUADS 5
#define N_BOXES 1


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_cappedcylinder_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_sphere_light>


mat4 makeRotateY(float rot)
{
	float s = sin(rot);
	float c = cos(rot);
	
	return mat4(
	 	c, 0, s, 0,
	 	0, 1, 0, 0,
	       -s, 0, c, 0,
	 	0, 0, 0, 1 
	);
}

mat4 makeRotateX(float rot)
{
	float s = sin(rot);
	float c = cos(rot);
	
	return mat4(
		1, 0,  0, 0,
		0, c, -s, 0,
		0, s,  c, 0,
		0, 0,  0, 1
	);
}

mat4 makeRotateZ(float rot)
{
	float s = sin(rot);
	float c = cos(rot);
	
	return mat4(
		c, -s, 0, 0,
		s,  c, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1
	);
}


//--------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, inout uvec2 seed )
//--------------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	vec3 n, n1, n2;
	vec3 intersectionPoint;
	vec3 offset;
	Ray warpedRay;

	/*
        for (int i = 0; i < N_SPHERES; i++)
        {
		if (i == 0) // Sphere Light
		{
			d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
			offset = vec3(0);
		}
		else if (i == 1 || i == 2) // Twisted Spheres
		{
			warpedRay = r;

			float torusThickness = 10.0;
			d = CappedCylinderIntersect( spheres[i].position - vec3(0, 0, torusThickness), spheres[i].position + vec3(0, 0, torusThickness), spheres[i].radius, warpedRay, n);
			if (d == INFINITY) continue;

			vec3 hitPos = warpedRay.origin + warpedRay.direction * d;
			vec3 hitVec = (hitPos - spheres[i].position);
			hitVec.z = 0.0;
			hitVec = normalize(hitVec);
			
			vec3 spherePos = spheres[i].position + (hitVec * (90.0 - torusThickness));

			d = SphereIntersect( torusThickness, spherePos, warpedRay );
			if (d < t)
			{
				t = d;
				intersectionPoint = warpedRay.origin + warpedRay.direction * d;
				intersec.normal = normalize(intersectionPoint - spherePos);
				intersec.emission = spheres[i].emission;
				intersec.color = spheres[i].color;
				intersec.type = spheres[i].type;
			}
		}
		else if (i == 3) // Cloudy Sphere
		{
			float dense = 1.0 + rand(seed);
			offset = (spheres[i].radius*0.5) * (vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0));
			d = SphereIntersect( spheres[i].radius * dense, spheres[i].position + offset, r);
		}
		
		if (d < t)
		{
			t = d;
			intersectionPoint = r.origin + r.direction * d;
			vec3 tempNormal = (intersectionPoint - (spheres[i].position + offset));
			intersec.normal = normalize(tempNormal);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
        }
	*/

	for (int i = 0; i < N_SPHERES; i++)
        {
		if (i == 0) // Sphere Light
		{
			d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
			offset = vec3(0);
		}
		else if (i == 1 || i == 2) // Twisted Spheres
		{
			d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
			if (d == INFINITY) continue;
			intersectionPoint = r.origin + r.direction * d;
			float angle = mod(intersectionPoint.y * 0.1, TWO_PI);
			mat4 m = makeRotateY(angle);
			vec3 o = ( m * vec4(intersectionPoint, 1.0) ).xyz;
			offset = o * 0.1;
			d = SphereIntersect( spheres[i].radius, spheres[i].position + offset, r);
		}
		else if (i == 3) // Cloudy Sphere
		{
			float dense = 1.0 + rand(seed);
			offset = (spheres[i].radius*0.5) * (vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0));
			d = SphereIntersect( spheres[i].radius * dense, spheres[i].position + offset, r);
		}
		
		if (d < t)
		{
			t = d;
			intersectionPoint = r.origin + r.direction * d;
			vec3 tempNormal = (intersectionPoint - (spheres[i].position + offset));
			intersec.normal = normalize(tempNormal);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
	}
	
	for (int i = 0; i < N_BOXES; i++)
        {
		warpedRay = r;
                warpedRay.origin.x -= 200.0;
                warpedRay.origin.y -= 200.0;
                warpedRay.origin.z += 300.0;
                
                d = BoxIntersect( boxes[i].minCorner * vec3(1.5, 1.0, 1.5), boxes[i].maxCorner * vec3(1.5, 1.0, 1.5), warpedRay, n );
                if (d == INFINITY) continue;
            	
                vec3 hitPos = warpedRay.origin + warpedRay.direction * d;
                //float angle = 0.25 * PI;
		float angle = mod(hitPos.y * 0.015, TWO_PI);
		mat4 m = makeRotateY(angle);
                m = inverse(m);
                warpedRay.origin = vec3( m * vec4(warpedRay.origin, 1.0) );
		warpedRay.direction = normalize(vec3( m * vec4(warpedRay.direction, 0.0) ));
                
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, warpedRay, n );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
                        intersec.normal = normalize(vec3( transpose(m) * vec4(intersec.normal, 0.0) ));
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
		}
        }
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
		if (d < t)
		{
			t = d;
			intersec.normal = (quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }

	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Sphere light = spheres[0];

	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 n, nl, x;
	vec3 dirToLight;
	vec3 tdir;
	
	float nc, nt, Re;
	float weight;
	float diffuseColorBleeding = 0.4; // range: 0.0 - 0.5, amount of color bleeding between surfaces

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	
	
        for (int bounces = 0; bounces < 5; bounces++)
	{
		
		float t = SceneIntersect(r, intersec, seed);
		
		if (t == INFINITY)
		{
                        break;
		}
		
		// if we reached something bright, don't spawn any more rays
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular || sampleLight)
			{
				accumCol = mask * intersec.emission;
			}
			
			break;
		}

		// if we reached this point and sampleLight failed to find a light above, exit early
		if (sampleLight)
		{
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			mask *= intersec.color;

			/*
			// Russian Roulette - if needed, this speeds up the framerate, at the cost of some dark noise
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
			{
				if (rand(seed) < p)
                                	mask *= 1.0 / p;
                        	else
                                	break;
			}
			*/

			bounceIsSpecular = false;

                        if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += nl;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
				
                }
		

                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}
		

		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);

			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl;

				//bounceIsSpecular = true; // turn on reflecting caustics, useful for water
			    	continue;	
			}
			else // transmit ray through surface
			{
				mask *= intersec.color;
				
				r = Ray(x, tdir);
				r.origin -= nl;

				bounceIsSpecular = true; // turn on refracting caustics
				continue;
			}
			
		} // end if (intersec.type == REFR)
		
		
                if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			// choose either specular reflection or diffuse
			if( rand(seed) < Re )
			{	
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl;
				continue;	
			}

			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += nl;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);
				
                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
			
		} //end if (intersec.type == COAT)
                
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return accumCol;      
}

//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 4.0;// Bright light
		    
	spheres[0] = Sphere( 200.0, vec3(275.0, 650.0, -280.0), L1, z, LIGHT);// Light Sphere
	
	spheres[1] = Sphere( 90.0, vec3(150.0,  91.0, -200.0),  z, vec3(0.4, 0.9, 1.0),  REFR);// Sphere Left
	spheres[2] = Sphere( 90.0, vec3(400.0,  91.0, -200.0),  z, vec3(1.0, 1.0, 1.0),  COAT);// Sphere Right
	spheres[3] = Sphere( 60.0, vec3(450.0, 380.0, -300.0),  z, vec3(1.0, 0.0, 1.0),  DIFF);// Cloud Sphere Top Right
	
	boxes[0]  = Box( vec3(-82, -170, -80), vec3(82, 170, 80), z, vec3(1.0, 1.0, 1.0), SPEC);// Tall Mirror Box Left
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0), z, vec3( 0.7, 0.05, 0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2), z, vec3(0.05, 0.05, 0.7 ), DIFF);// Right Wall Blue
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0), z, vec3( 1.0,  1.0,  1.0), DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Floor	
}


#include <pathtracing_main>
