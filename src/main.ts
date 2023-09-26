import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js') ;
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  'Reset': resetValue,
  InFireBallColor: [229.5, 165.75, 76.5],
  OutFireBallColor: [229.5, 89.25, 25.5],
  InCircleColor: [229.5, 165.75, 76.5],
  OutCircleColor: [229.5, 89.25, 25.5],
  EyeDistance: 3.5
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let time:GLfloat = 0.0;

let tesselationsController: any;
let inFireBallColorController: any;
let outFireBallColorController: any;
let inCircleColorController: any;
let outCircleColorController: any;
let eyeDistanceController: any;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function resetValue()
{
  controls.tesselations = 5;
  controls.InFireBallColor = [229.5, 165.75, 76.5];
  controls.OutFireBallColor = [229.5, 89.25, 25.5];
  controls.InCircleColor = [229.5, 165.75, 76.5];
  controls.OutCircleColor = [229.5, 89.25, 25.5];
  controls.EyeDistance = 3.5;
  
  tesselationsController.updateDisplay();
  inFireBallColorController.updateDisplay();
  outFireBallColorController.updateDisplay();
  inCircleColorController.updateDisplay();
  outCircleColorController.updateDisplay();
  eyeDistanceController.updateDisplay();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  tesselationsController = gui.add(controls, 'tesselations', 0, 8).step(1);
  inFireBallColorController = gui.addColor(controls, 'InFireBallColor').name('InFireBallColor');
  outFireBallColorController = gui.addColor(controls, 'OutFireBallColor').name('OutFireBallColor');
  inCircleColorController = gui.addColor(controls, 'InCircleColor').name('InCircleColor');
  outCircleColorController = gui.addColor(controls, 'OutCircleColor').name('OutCircleColor');
  eyeDistanceController = gui.add(controls, 'EyeDistance', 1.5, 5.5).step(0.1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Reset');


  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();
  resetValue();
  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const fireBallShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);

  const bgShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    time += 1;
    let inFireBallColorVec = vec4.fromValues(controls.InFireBallColor[0] / 255., controls.InFireBallColor[1] / 255., controls.InFireBallColor[2] / 255., 1);
    let outFireBallColorVec = vec4.fromValues(controls.OutFireBallColor[0] / 255., controls.OutFireBallColor[1] / 255., controls.OutFireBallColor[2] / 255., 1);
    let inCircleColorVec = vec4.fromValues(controls.InCircleColor[0] / 255., controls.InCircleColor[1] / 255., controls.InCircleColor[2] / 255., 1);
    let outCircleColorVec = vec4.fromValues(controls.OutCircleColor[0] / 255., controls.OutCircleColor[1] / 255., controls.OutCircleColor[2] / 255., 1);
    let eyeDistance = controls.EyeDistance;

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    
    renderer.drawBackground(camera, bgShader, inCircleColorVec, outCircleColorVec, time);

    renderer.render(camera, fireBallShader, [
      icosphere,
      //square,
      //cube
    ], inFireBallColorVec, outFireBallColorVec, eyeDistance, time);


    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }


  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
