###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/webgl/GLESShaders', ->
  GLESShaders = {}

  # the default super fast shader!
  GLESShaders.shaderFragmentSrc = [
    "#ifdef GL_ES",
    "precision mediump float;",
    "#endif",
    "varying vec2 vTextureCoord;",
    "varying float vColor;",
    "uniform sampler2D uSampler;",
    "void main(void) {",
      "gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y));",
      "gl_FragColor = gl_FragColor * vColor;",
    "}"
  ]

  GLESShaders.shaderVertexSrc = [
    "attribute vec2 aVertexPosition;",
    "attribute vec2 aTextureCoord;",
    "attribute float aColor;",
    #"uniform mat4 uMVMatrix;",

    "uniform vec2 projectionVector;",
    "varying vec2 vTextureCoord;",
    "varying float vColor;",
    "void main(void) {",
      #"gl_Position = uMVMatrix * vec4(aVertexPosition, 1.0, 1.0);",,
      "gl_Position = vec4( aVertexPosition.x / projectionVector.x -1.0, aVertexPosition.y / -projectionVector.y + 1.0 , 0.0, 1.0);",
      "vTextureCoord = aTextureCoord;",
      "vColor = aColor;",
    "}"
  ]

  # the triangle strip shader..
  GLESShaders.stripShaderFragmentSrc = [
    "#ifdef GL_ES",
    "precision mediump float;",
    "#endif",
    "varying vec2 vTextureCoord;",
    "varying float vColor;",
    "uniform float alpha;",
    "uniform sampler2D uSampler;",
    "void main(void) {",
      "gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y));",
      "gl_FragColor = gl_FragColor * alpha;",
    "}"
  ]

  GLESShaders.stripShaderVertexSrc = [
    "attribute vec2 aVertexPosition;",
    "attribute vec2 aTextureCoord;",
    "attribute float aColor;",
    "uniform mat3 translationMatrix;",
    "uniform vec2 projectionVector;",
    "varying vec2 vTextureCoord;",
    "varying float vColor;",
    "void main(void) {",
      "vec3 v = translationMatrix * vec3(aVertexPosition, 1.0);",
      "gl_Position = vec4( v.x / projectionVector.x -1.0, v.y / -projectionVector.y + 1.0 , 0.0, 1.0);",
      "vTextureCoord = aTextureCoord;",
      "vColor = aColor;",
    "}"
  ]

  # primitive shader..
  GLESShaders.primitiveShaderFragmentSrc = [
    "#ifdef GL_ES",
    "precision mediump float;",
    "#endif",
    "varying vec4 vColor;",
    "void main(void) {",
      "gl_FragColor = vColor;",
    "}"
  ]

  GLESShaders.primitiveShaderVertexSrc = [
    "attribute vec2 aVertexPosition;",
    "attribute vec4 aColor;",
    "uniform mat3 translationMatrix;",
    "uniform vec2 projectionVector;",
    "uniform float alpha;",
    "varying vec4 vColor;",
    "void main(void) {",
      "vec3 v = translationMatrix * vec3(aVertexPosition, 1.0);",
      "gl_Position = vec4( v.x / projectionVector.x -1.0, v.y / -projectionVector.y + 1.0 , 0.0, 1.0);",
      "vColor = aColor  * alpha;",
    "}"
  ]

  GLESShaders.initPrimitiveShader = (gl) ->
    shader = {}
    shader.program = GLESShaders.compileProgram(gl, GLESShaders.primitiveShaderVertexSrc, GLESShaders.primitiveShaderFragmentSrc)
    gl.useProgram shader.program
    shader.vertexPositionAttribute = gl.getAttribLocation(shader.program, "aVertexPosition")
    shader.colorAttribute = gl.getAttribLocation(shader.program, "aColor")
    shader.projectionVector = gl.getUniformLocation(shader.program, "projectionVector")
    shader.translationMatrix = gl.getUniformLocation(shader.program, "translationMatrix")
    shader.alpha = gl.getUniformLocation(shader.program, "alpha")
    GLESShaders.primitiveShader = shader

  GLESShaders.initDefaultShader = (gl) ->
    shader = {}
    shader.program = GLESShaders.compileProgram(gl, GLESShaders.shaderVertexSrc, GLESShaders.shaderFragmentSrc)
    gl.useProgram shader.program
    shader.vertexPositionAttribute = gl.getAttribLocation(shader.program, "aVertexPosition")
    shader.projectionVector = gl.getUniformLocation(shader.program, "projectionVector")
    shader.textureCoordAttribute = gl.getAttribLocation(shader.program, "aTextureCoord")
    shader.colorAttribute = gl.getAttribLocation(shader.program, "aColor")
    
    # shader.mvMatrixUniform = gl.getUniformLocation(shader.program, "uMVMatrix");
    shader.samplerUniform = gl.getUniformLocation(shader.program, "uSampler")
    GLESShaders.defaultShader = shader

  GLESShaders.initDefaultStripShader = (gl) ->
    shader = {}
    shader.program = GLESShaders.compileProgram(gl, GLESShaders.stripShaderVertexSrc, GLESShaders.stripShaderFragmentSrc)
    gl.useProgram shader.program
    shader.vertexPositionAttribute = gl.getAttribLocation(shader.program, "aVertexPosition")
    shader.projectionVector = gl.getUniformLocation(shader.program, "projectionVector")
    shader.textureCoordAttribute = gl.getAttribLocation(shader.program, "aTextureCoord")
    shader.translationMatrix = gl.getUniformLocation(shader.program, "translationMatrix")
    shader.alpha = gl.getUniformLocation(shader.program, "alpha")
    shader.colorAttribute = gl.getAttribLocation(shader.program, "aColor")
    shader.projectionVector = gl.getUniformLocation(shader.program, "projectionVector")
    shader.samplerUniform = gl.getUniformLocation(shader.program, "uSampler")
    GLESShaders.stripShader = shader

  GLESShaders.CompileVertexShader = (gl, shaderSrc) ->
    GLESShaders._CompileShader gl, shaderSrc, gl.VERTEX_SHADER

  GLESShaders.CompileFragmentShader = (gl, shaderSrc) ->
    GLESShaders._CompileShader gl, shaderSrc, gl.FRAGMENT_SHADER

  GLESShaders._CompileShader = (gl, shaderSrc, shaderType) ->
    src = shaderSrc.join("\n")
    shader = gl.createShader(shaderType)
    gl.shaderSource shader, src
    gl.compileShader shader
    unless gl.getShaderParameter(shader, gl.COMPILE_STATUS)
      alert gl.getShaderInfoLog(shader)
      return null
    shader

  GLESShaders.compileProgram = (gl, vertexSrc, fragmentSrc) ->
    fragmentShader = GLESShaders.CompileFragmentShader(gl, fragmentSrc)
    vertexShader = GLESShaders.CompileVertexShader(gl, vertexSrc)
    program = gl.createProgram()
    gl.attachShader program, vertexShader
    gl.attachShader program, fragmentShader
    gl.linkProgram program
    alert "Could not initialise shaders"  unless gl.getProgramParameter(program, gl.LINK_STATUS)
    program

  GLESShaders.activateDefaultShader = (gl) ->
    shader = GLESShaders.defaultShader
    gl.useProgram shader.program
    gl.enableVertexAttribArray shader.vertexPositionAttribute
    gl.enableVertexAttribArray shader.textureCoordAttribute
    gl.enableVertexAttribArray shader.colorAttribute

  GLESShaders.activatePrimitiveShader = (gl) ->
    gl.disableVertexAttribArray GLESShaders.defaultShader.textureCoordAttribute
    gl.disableVertexAttribArray GLESShaders.defaultShader.colorAttribute
    gl.useProgram GLESShaders.primitiveShader.program
    gl.enableVertexAttribArray GLESShaders.primitiveShader.vertexPositionAttribute
    gl.enableVertexAttribArray GLESShaders.primitiveShader.colorAttribute

  return GLESShaders