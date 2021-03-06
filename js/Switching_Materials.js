// scene/demo-specific variables go here
var sceneIsDynamic = false;
var camFlightSpeed = 300;
var gui;
var ableToEngagePointerLock = true;
var materialController;
var matType = 0;
var changeLeftSphereMaterial = false;
var changeRightSphereMaterial = false;


function init_GUI() {

        materialController = {
                LSphereMaterial: 4,
                RSphereMaterial: 2
        };

        function leftMatChanger() {
                changeLeftSphereMaterial = true;
        }
        
        function rightMatChanger() {
                changeRightSphereMaterial = true;
        } 

        gui = new dat.GUI();
        
        gui.add( materialController, 'LSphereMaterial', 1, 7, 1 ).onChange( leftMatChanger );
        gui.add( materialController, 'RSphereMaterial', 1, 7, 1 ).onChange( rightMatChanger );
        
        leftMatChanger();
        rightMatChanger();

        gui.domElement.style.webkitUserSelect = "none";
        gui.domElement.style.MozUserSelect = "none";
        
        window.addEventListener('resize', onWindowResize, false);

        if ( 'ontouchstart' in window ) {
                mouseControl = false;
                // if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
                isPaused = false;
                pixelRatio = 0.5;
                ableToEngagePointerLock = true;

                mobileJoystickControls = new MobileJoystickControls ({
                        //showJoystick: true,
                        guiDomElement: gui.domElement,
                        enableMultiTouch: true
                });	
        }

        if (mouseControl) {

                window.addEventListener( 'wheel', onMouseWheel, false );

                window.addEventListener("click", function(event) {
                        event.preventDefault();	
                }, false);
                window.addEventListener("dblclick", function(event) {
                        event.preventDefault();	
                }, false);
                
                document.body.addEventListener("click", function(event) {
                        if (!ableToEngagePointerLock)
                                return;
                        this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
                        this.requestPointerLock();
                }, false);


                var pointerlockChange = function ( event ) {

                        if ( document.pointerLockElement === document.body || 
                            document.mozPointerLockElement === document.body || document.webkitPointerLockElement === document.body ) {

                                isPaused = false;

                        } else {

                                isPaused = true;

                        }

                };

                // Hook pointer lock state change events
                document.addEventListener( 'pointerlockchange', pointerlockChange, false );
                document.addEventListener( 'mozpointerlockchange', pointerlockChange, false );
                document.addEventListener( 'webkitpointerlockchange', pointerlockChange, false );

        }

        if (mouseControl) {
                gui.domElement.addEventListener("mouseenter", function(event) {
                                ableToEngagePointerLock = false;	
                }, false);
                gui.domElement.addEventListener("mouseleave", function(event) {
                                ableToEngagePointerLock = true;
                }, false);
        }

        /*
        // Fullscreen API
        document.addEventListener("click", function() {
        	
        	if ( !document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement ) {

        		if (document.documentElement.requestFullscreen) {
        			document.documentElement.requestFullscreen();
        			
        		} else if (document.documentElement.mozRequestFullScreen) {
        			document.documentElement.mozRequestFullScreen();
        		
        		} else if (document.documentElement.webkitRequestFullscreen) {
        			document.documentElement.webkitRequestFullscreen();
        		
        		}

        	}
        });
        */

        initTHREEjs(); // boilerplate: init necessary three.js items and scene/demo-specific objects

} // end function init_GUI()



function MaterialObject() {
// a list of material types and their corresponding numbers are found in the 'pathTracingCommon.js' file
        this.type = 1; // default is '1': diffuse type
        this.color = new THREE.Color(1.0, 1.0, 1.0);
        //this.emission = new THREE.Color(0.0, 0.0, 0.0);   
}

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here

        // set camera's field of view
        worldCamera.fov = 50;

        // position and orient camera
        cameraControlsObject.position.set(278, 170, 320);
        ///cameraControlsYawObject.rotation.y = 0.0;
        // look slightly upward
        cameraControlsPitchObject.rotation.x = 0.005;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {

                tPreviousTexture: { type: "t", value: screenTextureRenderTarget.texture },
					
                uCameraIsMoving: { type: "b1", value: false },
                uCameraJustStartedMoving: { type: "b1", value: false },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: 500.0 },

                uLeftSphereMaterialType: { type: "f", value: 0.0 },
                uRightSphereMaterialType: { type: "f", value: 0.0 },
                uLeftSphereColor: { type: "v3", value: new THREE.Color() },
                uRightSphereColor: { type: "v3", value: new THREE.Color() },
                //uLeftSphereEmissive: { type: "v3", value: new THREE.Color() },
                //uRightSphereEmissive: { type: "v3", value: new THREE.Color() },
                
                uResolution: { type: "v2", value: new THREE.Vector2() },
                
                uRandomVector: { type: "v3", value: new THREE.Vector3() },
        
                uCameraMatrix: { type: "m4", value: new THREE.Matrix4() }
        
        };

        pathTracingDefines = {
        	//NUMBER_OF_TRIANGLES: total_number_of_triangles
        };

        // load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
        fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText) {
                pathTracingVertexShader = shaderText;

                createPathTracingMaterial();
        });

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial() {

        fileLoader.load('shaders/Switching_Materials_Fragment.glsl', function (shaderText) {
                
                pathTracingFragmentShader = shaderText;

                pathTracingMaterial = new THREE.ShaderMaterial({
                        uniforms: pathTracingUniforms,
                        defines: pathTracingDefines,
                        vertexShader: pathTracingVertexShader,
                        fragmentShader: pathTracingFragmentShader,
                        depthTest: false,
                        depthWrite: false
                });

                pathTracingMesh = new THREE.Mesh(pathTracingGeometry, pathTracingMaterial);
                pathTracingScene.add(pathTracingMesh);

                // the following keeps the large scene ShaderMaterial quad right in front 
                //   of the camera at all times. This is necessary because without it, the scene 
                //   quad will fall out of view and get clipped when the camera rotates past 180 degrees.
                worldCamera.add(pathTracingMesh);
                
        });

} // end function createPathTracingMaterial()



// called automatically from within the animate() function
function updateVariablesAndUniforms() {
        
        if (changeLeftSphereMaterial) {
                                        
                matType = Math.floor(materialController.LSphereMaterial);
                pathTracingUniforms.uLeftSphereMaterialType.value = matType;

                //if (matType == 0) { // LIGHT
                //        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.0, 0.0, 0.0);
                //        pathTracingUniforms.uLeftSphereEmissive.value.setRGB(1.0, 0.0, 1.0);
                //}
                if (matType == 1) { // DIFF
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 1.0, 1.0);   
                }
                else if (matType == 2) { // REFR
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.6, 1.0, 0.9); 
                }
                else if (matType == 3) { // SPEC
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.000000, 0.765557, 0.336057); // Gold
                        // other metals
                        // Aluminum: (0.913183, 0.921494, 0.924524) / Copper: (0.955008, 0.637427, 0.538163) / Silver: (0.971519, 0.959915, 0.915324)   
                }
                else if (matType == 4) { // COAT
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 1.0, 1.0);   
                }
                else if (matType == 5) { // CARCOAT
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.7, 0.001, 0.001);   
                }
                else if (matType == 6) { // TRANSLUCENT
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.5, 0.1, 0.0); //absorptionCoefficient 
                }
                else if (matType == 7) { // SPECSUB
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.01, 0.01, 0.04); //absorptionCoefficient   
                }

                cameraIsMoving = true;
                changeLeftSphereMaterial = false;
        }

        if (changeRightSphereMaterial) {

                matType = Math.floor(materialController.RSphereMaterial);
                pathTracingUniforms.uRightSphereMaterialType.value = matType;

                //if (matType == 0) { // LIGHT
                //        pathTracingUniforms.uRightSphereColor.value.setRGB(0.0, 0.0, 0.0);
                //        pathTracingUniforms.uRightSphereEmissive.value.setRGB(1.0, 0.0, 1.0);    
                //}
                if (matType == 1) { // DIFF
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 1.0);   
                }
                else if (matType == 2) { // REFR
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 1.0);
                }
                else if (matType == 3) { // SPEC
                        pathTracingUniforms.uRightSphereColor.value.setRGB(0.913183, 0.921494, 0.924524); // Aluminum
                        // other metals
                        // Gold: (1.000000, 0.765557, 0.336057) / Copper: (0.955008, 0.637427, 0.538163) / Silver: (0.971519, 0.959915, 0.915324)   
                }
                else if (matType == 4) { // COAT
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 0.0);   
                }
                else if (matType == 5) { // CARCOAT
                        pathTracingUniforms.uRightSphereColor.value.setRGB(0.1, 0.2, 0.45);
                }
                else if (matType == 6) { // TRANSLUCENT
                        pathTracingUniforms.uRightSphereColor.value.setRGB(0.0, 0.18, 0.2); //absorptionCoefficient
                }
                else if (matType == 7) { // SPECSUB
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 0.01, 0.2); //absorptionCoefficient    
                }

                cameraIsMoving = true;
                changeRightSphereMaterial = false;
        }

        if (cameraIsMoving) {
                sampleCounter = 1.0;
                frameCounter += 1.0;

                if (!cameraRecentlyMoving) {
                        cameraJustStartedMoving = true;
                        cameraRecentlyMoving = true;
                }
        }

        if ( !cameraIsMoving ) {
                sampleCounter += 1.0; // for progressive refinement of image
                if (sceneIsDynamic)
                        sampleCounter = 1.0; // reset for continuous updating of image
                
                frameCounter  += 1.0;
                if (cameraRecentlyMoving)
                        frameCounter = 1.0;

                cameraRecentlyMoving = false;  
        }

        
        pathTracingUniforms.uCameraIsMoving.value = cameraIsMoving;
        pathTracingUniforms.uCameraJustStartedMoving.value = cameraJustStartedMoving;
        pathTracingUniforms.uSampleCounter.value = sampleCounter;
        pathTracingUniforms.uFrameCounter.value = frameCounter;
        pathTracingUniforms.uRandomVector.value = randomVector.set( Math.random(), Math.random(), Math.random() );
        
        // CAMERA
        cameraControlsObject.updateMatrixWorld(true);			
        pathTracingUniforms.uCameraMatrix.value.copy( worldCamera.matrixWorld );
        screenOutputMaterial.uniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;
        
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateVariablesAndUniforms()



init_GUI(); // init app and start animating
