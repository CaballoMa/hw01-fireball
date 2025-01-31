import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, inFireBallColorVec : vec4, outFireBallColorVec : vec4, eyeDistance : number, time : number) {
    let model = mat4.create();
    let viewProj = mat4.create();

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setEyeDistance(eyeDistance);
    prog.setInFireBallColor(inFireBallColorVec);
    prog.setOutFireBallColor(outFireBallColorVec);
    
    prog.setTime(time);
    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }

  drawBackground(camera: Camera, prog: ShaderProgram, inCircleColorVec : vec4, outCircleColorVec : vec4, time : number) {
    prog.setTime(time);
    prog.setInCircleColor(inCircleColorVec);
    prog.setOutCircleColor(outCircleColorVec);
    prog.drawQuad();
  }
};

export default OpenGLRenderer;
