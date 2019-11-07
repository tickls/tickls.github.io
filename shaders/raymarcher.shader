#define MAX_STEPS           100
#define MAX_SHADOW_STEPS	50.
#define MAX_DISTANCE        100.0
#define SURFACE_DISTANCE    0.001
#define MAX_BOUNCES			3.

const vec3 cameraPos = vec3(0, 0, 0);
const vec3 specularLightColor = vec3(1, 0.5, 0);
const vec3 ambientLightColor = vec3(.01);

struct Light {
    vec3 position;
    vec3 color;
};
    
#define NUMBER_OF_LIGHTS 1
Light lights[1];

//lights[0] = Light(vec3(0.), vec3(1.));

struct Material {
    vec3 color;
    float specular;
    float opacity;
    float reflectiveness;
};
  
struct Ray {
 	float marchDistance;
    Material material;
    float firstHitDistance;
};
 
const Material emptyMaterial = Material(vec3(0.,0.,0.), 0.5, 1., 0.);

float N21(vec2 p) {
    float mult = iTime;

    p = fract(p * vec2(237.74, 1201.17));
    p += dot(p, p+85.51);

    return fract(p.x*p.y);
}

Material getPlaneMatarialAtPos(vec3 posOnPlane) {
    
    float x = round(fract(posOnPlane.x));
    float y = round(fract(posOnPlane.z));
    
    float checkX = max(0., (x - (1. * y)));
    float checkY = max(0., (y - (1. * x)));

    return Material(vec3(1, 1, 1) * (checkX + checkY), 1., 1., 0.25);
    //return Material(vec3(0.5, 0, .8) * (checkX + checkY), 1., 1., 0.25);
    
//    return Material(vec3(0, 0, checkX + checkY), 0.24, 1.);
    //return vec4(0, 0, checkX + checkY, 0.3);
}

Material getSphere1Material() {
    return Material(vec3(0, 1, 0), .25, 1., 0.4);
}

Material getSphere2Material() {
    return Material(vec3(1, 1, 1), 0.1, 1., 0.7);
}

float getDistToPlane(vec3 position) {
    float planeHeight = -1.;
    
    return position.y - planeHeight;
 
    return min(position.y - planeHeight, 4. - position.y); // Assume the plane is on the floor
}

const vec4 sphere1Pos = vec4(0., .0, 4.0, 0.5); // Sphere Pos: xyz, Radius: w
const vec4 sphere2Pos = vec4(0., .0, 4.0, 0.5); // Sphere Pos: xyz, Radius: w

float sdTorus( vec3 p, vec2 t )
{
	vec2 q = vec2(length(p.xz)-t.x,p.y);
 	return length(q)-t.y;
}

float getDistToSphere(vec3 position, vec4 sphere) {
    return length(position - sphere.xyz) - sphere.w;
}

float getDistToTorus(vec3 position, vec3 torusPosition, vec2 torus) {
    return sdTorus(position - torusPosition, torus);
}

vec4 GetSphere1Pos() {
    return sphere1Pos;
    return sphere1Pos + vec4(sin(iTime/2.)*1., 2.5, 0,0);//cos(iTime), 0);
}

vec4 GetSphere2Pos() {
    //return sphere2Pos;
    return sphere2Pos + vec4(0,sin(iTime)/2., 0, 0);
}

float getDist(vec3 position) {
    //sphere2.z += sin(iTime);    
    float sphereDist1 = getDistToTorus(position, GetSphere1Pos().xyz, vec2(1, 0.05));
	float sphereDist2 = getDistToSphere(position, GetSphere2Pos());
    
    return min(min(sphereDist1, sphereDist2), getDistToPlane(position));
}


Material getMaterialAtPos(vec3 position) {
    //float sphereDist = getDistToSphere(position, GetSphere1Pos());
    float sphereDist = getDistToTorus(position, GetSphere1Pos().xyz, vec2(1, 0.2));
    float sphereDist2 = getDistToSphere(position, GetSphere2Pos());
    float planeDist = getDistToPlane(position);
    
    if(planeDist < sphereDist && planeDist < sphereDist2) {
        return getPlaneMatarialAtPos(position);
    }
    else if(sphereDist < sphereDist2) {
        return getSphere1Material();   
    }
    else {
     	return getSphere2Material();
    }
}

vec3 getNormal(vec3 position) {
    float distance = getDist(position);
    vec2 e = vec2(0.01, 0.0);

    vec3 normal = distance - vec3(
        getDist(position-e.xyy),
        getDist(position-e.yxy),
        getDist(position-e.yyx)
    );

    return normalize(normal);
}

Ray rayMarch(vec3 rayOrigin, vec3 rayDirection, float maxBounces) {
    Ray ray = Ray(.0, emptyMaterial, .0);
    Material objMat;
    
    int i = 0; // Steps, we don't reset them on every bounce for performance reasons.

    for(float b = 1.; b <= maxBounces; b+=1.) {
        float currentDist = 0.0;
        
        for(; i < MAX_STEPS; i++) {
            vec3 position = rayOrigin + rayDirection * currentDist;//ray.marchDistance;
            float dist = getDist(position);

            ray.marchDistance += dist;
            currentDist += dist;

            if(currentDist/*ray.marchDistance*/ > MAX_DISTANCE) {
                return ray;
            }
            
            if(dist < SURFACE_DISTANCE) {
             	vec3 normalAtHitPos = getNormal(position);
                Material hitMaterial;
                
                if(b == 1.) {
                    ray.firstHitDistance = currentDist;
                    ray.material = getMaterialAtPos(position);
                }
                else {
                    hitMaterial = getMaterialAtPos(position);
                    float bounceCorr = 1. / b;
                    ray.material.color += hitMaterial.color.rgb * ray.material.reflectiveness * bounceCorr;
                }
           
                rayOrigin = position + normalAtHitPos * SURFACE_DISTANCE * 2.0;
                rayDirection = normalAtHitPos;
                currentDist = 0.;
                break;
            }
        }
    }

    return ray;
}

float rayMarchSoftShadow(vec3 rayOrigin, vec3 rayDirection, float k) {
    Ray ray = Ray(.0, emptyMaterial, .0);
    Material objMat;
    
    float res = 1.0;

    for(float i = 0.0; i < MAX_SHADOW_STEPS; i+=1.0f) {
        vec3 position = rayOrigin + rayDirection * i;//ray.marchDistance;
        float dist = getDist(position);

        if(dist < SURFACE_DISTANCE) {
            return 0.2;
        }
        
        res = min(res, k * dist / i);
        
        i+=dist;
    }

    return res;
}

vec3 getLightPos() {
	const vec3 lightPos = vec3(0, 2, 2);    
    
    return lightPos + vec3(cos(iTime)*1.8, 0, sin(iTime)*2.3);
}

float getShadow(vec3 position, vec3 direction, vec3 lightPos) {
    // Shadow
    //Ray ray = rayMarch(position + surfaceNormal * SURFACE_DISTANCE * 2.0, lightDir, 1.);
    
    // Shadow
    Ray ray = rayMarch(position, direction, 1.);
    
    if(ray.marchDistance < length(lightPos - position))
        return 0.2;
    
    return 1.0;
}

#define map getDist

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k)
{
    float res = 1.0;
    for( float t=mint; t < maxt; )
    {
        vec3 pos = ro + rd*t;
        float h = getDist(pos);
        if( h < SURFACE_DISTANCE)
            return 0.1;
        res = min( res, k*h/t );
        t += h;
    }
    
    return res;
}


vec3 getDiffuseLightAndShadow(vec3 position, vec3 surfaceNormal, vec3 lightPos) {
    // Basic Light
    vec3 lightDir = normalize(lightPos - position);
    float diffuse = dot(surfaceNormal, lightDir);
	
    //float shadow = getShadow(position + surfaceNormal * SURFACE_DISTANCE * 2.0, lightDir, lightPos);
    //float shadow = rayMarchSoftShadow(position + surfaceNormal * SURFACE_DISTANCE * 2.0, lightDir, 32.);
    
    vec3 ro = position + surfaceNormal * SURFACE_DISTANCE * 20.0;
    vec3 rd = lightDir;
    float shadow = softshadow(ro, rd, 0.0, 50.0, 20.0);

    return vec3(diffuse * shadow);
}

vec4 getLight(vec3 position, Material material) {
    vec3 lightPos = getLightPos();

    vec3 surfaceNormal = getNormal(position);
    vec3 lightDir = normalize(lightPos - position);

    vec3 diffuse = getDiffuseLightAndShadow(position, surfaceNormal, lightPos);

    return vec4(vec3(diffuse * material.color), 1.0);
    
    // Specular light
    vec3 viewDir = normalize(cameraPos - position);
	vec3 reflectDir = reflect(-lightDir, surfaceNormal); 

    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.);
	vec3 specular = material.specular * spec * specularLightColor;

    vec3 result = clamp((ambientLightColor + diffuse + specular) * material.color,
        0., 1.);

    return vec4(result, 1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 originalUv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 uv = originalUv * vec2(1., 1.);
    
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));
    Ray ray = rayMarch(cameraPos, rayDirection, MAX_BOUNCES);
    vec3 position = cameraPos + rayDirection * ray.firstHitDistance;
    
	fragColor = getLight(position, ray.material);
}
