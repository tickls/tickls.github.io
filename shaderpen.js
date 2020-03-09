'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

const prepareShader = (shaderString) => {

    // Hacked opengl es 3 support in o/\o
    const shaderHeader = 
        "#version 300 es\n" +
        "precision mediump float;\n" +
        "uniform vec3      iResolution;\n" +
        "uniform float     iTime;\n" +
        "uniform float     iChannelTime[4];\n" +
        "uniform vec4      iMouse;\n" +
        "uniform vec4      iDate;\n" +
        "uniform float     iSampleRate;\n" +
        "uniform vec3      iChannelResolution[4];\n" +
        "uniform int       iFrame;\n" +
        "uniform float     iTimeDelta;\n" +
        "uniform float     iFrameRate;\n" +
        "struct Channel\n"+
        "{\n"+
        "    vec3  resolution;\n"+
        "    float time;\n"+
        "};\n" +
        "void mainImage( out vec4 c,  in vec2 f );\n";

        const shaderFooter = 
          "out vec4 outColor;\n" +
          "void main(void) {\n" +
          "  vec4 color = vec4(0.0,0.0,0.0,1.0);\n" +
          "  mainImage(color, gl_FragCoord.xy);\n" +
          "  color.w = 1.0;\n" + 
          "  outColor = color;\n" +
          "}\n";

    return shaderHeader + shaderString + shaderFooter;
}

var ShaderPen = function () {
  // eslint-disable-line no-unused-vars
  function ShaderPen(shaderString, noRender) {
    _classCallCheck(this, ShaderPen);

    // shadertoy differences
    var ioTest = /\(\s*out\s+vec4\s+(\S+)\s*,\s*in\s+vec2\s+(\S+)\s*\)/;
    var io = shaderString.match(ioTest);
    //shaderString = shaderString.replace('mainImage', 'main');
    //shaderString = shaderString.replace(ioTest, '()');

    // shadertoy built in uniforms
    var uniforms = this.uniforms = {
      iResolution: {
        type: 'vec3',
        value: [window.innerWidth, window.innerHeight, 0]
      },
      iTime: {
        type: 'float',
        value: 0
      },
      iTimeDelta: {
        type: 'float',
        value: 0
      },
      iFrame: {
        type: 'int',
        value: 0
      },
      iMouse: {
        type: 'vec4',
        value: [0, 0, 0, 0]
      }
    };

    const versionStr = '#version 300 es';

    // create, position, and add canvas
    var canvas = this.canvas = document.createElement('canvas');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    canvas.style.position = 'fixed';
    canvas.style.left = 0;
    canvas.style.top = 0;
    document.body.append(canvas);

    // get webgl context and set clearColor
    var gl = this.gl = canvas.getContext('webgl2');
    gl.clearColor(0, 0, 0, 0);

    // compile basic vertex shader to make rect fill screen
    var vertexShader = this.vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, versionStr + '\n out vec4 fragColor;\n      in vec2 position;\n      void main() {\n      gl_Position = vec4(position, 0.0, 1.0);\n      }\n    ');
    gl.compileShader(vertexShader);

    shaderString = prepareShader(shaderString);

    // compile fragment shader from string passed in
    //console.log("*********************************************************************");
    //console.log("processed shader: " + shaderString);

    const lines = shaderString.split('\n');

    //for(var i = 0; i < lines.length; i++) {
    //    console.log(`${i+1}. ${lines[i]}`);
    //}


    var fragmentShader = this.fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, shaderString);
    gl.compileShader(fragmentShader);

    // make program from shaders
    var program = this.program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    // vertices for basic rectangle to fill screen
    var vertices = this.vertices = new Float32Array([-1, 1, 1, 1, 1, -1, -1, 1, 1, -1, -1, -1]);

    var buffer = this.buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);

    gl.useProgram(program);

    program.position = gl.getAttribLocation(program, 'position');
    gl.enableVertexAttribArray(program.position);
    gl.vertexAttribPointer(program.position, 2, gl.FLOAT, false, 0, 0);

    // get all uniform locations from shaders
    Object.keys(uniforms).forEach(function (key, i) {
      uniforms[key].location = gl.getUniformLocation(program, key);
    });

    // report webgl errors
    this.reportErrors();

    this.currentMouse = {
      x: 0,
      y: 0
    };

    this.mouseTarget = {
      x: 0,
      y: 0
    };

    // bind contexts
    this._bind('mouseDown', 'mouseMove', 'mouseUp', 'render', 'resize');

    // add event listeners
    window.addEventListener('mousedown', this.mouseDown);
    window.addEventListener('mousemove', this.mouseMove);
    window.addEventListener('mouseup', this.mouseUp);
    window.addEventListener('resize', this.resize);

    // auto render unless otherwise specified
    if (noRender !== 'NO_RENDER') {
      this.render();
    }
  }

  _createClass(ShaderPen, [{
    key: '_bind',
    value: function _bind() {
      var _this = this;

      for (var _len = arguments.length, methods = Array(_len), _key = 0; _key < _len; _key++) {
        methods[_key] = arguments[_key];
      }

      methods.forEach(function (method) {
        return _this[method] = _this[method].bind(_this);
      });
    }
  }, {
    key: 'mouseDown',
    value: function mouseDown(e) {
      this.mousedown = true;
      this.uniforms.iMouse.value[2] = e.clientX;
      this.uniforms.iMouse.value[3] = e.clientY;
    }
  }, {
    key: 'mouseMove',
    value: function mouseMove(e) {
      //if (this.mousedown) {
        this.mouseTarget = {
          x: e.clientX,
          y: e.clientY
        }

        return;
        const weightAverage = (v,w,N = 100) => {
          return ((v * (N - 1)) + w) / N;
        };

        this.prevMouse.x = weightAverage(this.prevMouse.x, e.clientX);
        this.prevMouse.y = weightAverage(this.prevMouse.y, e.clientY);

        this.uniforms.iMouse.value[0] = this.prevMouse.x;//e.clientX;
        this.uniforms.iMouse.value[1] = this.prevMouse.y;//e.clientY;
      // }
    }
  }, {
    key: 'mouseUp',
    value: function mouseUp(e) {
      this.mousedown = false;
      this.uniforms.iMouse.value[2] = 0;
      this.uniforms.iMouse.value[3] = 0;
    }
  }, {
    key: 'render',
    value: function render(timestamp) {
      const weightAverage = (v,w,N = 50) => {
        return ((v * (N - 1)) + w) / N;
      };

      this.currentMouse.x = weightAverage(this.currentMouse.x, this.mouseTarget.x);
      this.currentMouse.y = weightAverage(this.currentMouse.y, this.mouseTarget.y);

      this.uniforms.iMouse.value[0] = this.currentMouse.x;//e.clientX;
      this.uniforms.iMouse.value[1] = this.currentMouse.y;//e.clientY;


      var _this2 = this;

      var gl = this.gl;

      var delta = this.lastTime ? (timestamp - this.lastTime) / 1000 : 0;
      this.lastTime = timestamp;

      this.uniforms.iTime.value += delta;
      this.uniforms.iTimeDelta.value = delta;
      this.uniforms.iFrame.value++;

      gl.clear(gl.COLOR_BUFFER_BIT);

      Object.keys(this.uniforms).forEach(function (key) {
        var t = _this2.uniforms[key].type;
        var method = t.match(/vec/) ? t[t.length - 1] + 'fv' : '1' + t[0];
        gl['uniform' + method](_this2.uniforms[key].location, _this2.uniforms[key].value);
      });

      gl.drawArrays(gl.TRIANGLES, 0, this.vertices.length / 2);

      requestAnimationFrame(this.render);
    }
  }, {
    key: 'reportErrors',
    value: function reportErrors() {
      var gl = this.gl;

      if (!gl.getShaderParameter(this.vertexShader, gl.COMPILE_STATUS)) {
        console.log(gl.getShaderInfoLog(this.vertexShader));
      }

      if (!gl.getShaderParameter(this.fragmentShader, gl.COMPILE_STATUS)) {
        console.log(gl.getShaderInfoLog(this.fragmentShader));
      }

      if (!gl.getProgramParameter(this.program, gl.LINK_STATUS)) {
        console.log(gl.getProgramInfoLog(this.program));
      }
    }
  }, {
    key: 'resize',
    value: function resize() {
      this.canvas.width = this.uniforms.iResolution.value[0] = window.innerWidth;
      this.canvas.height = this.uniforms.iResolution.value[1] = window.innerHeight;

      this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    }
  }]);

  return ShaderPen;
}();