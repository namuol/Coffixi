###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/webgl/GLESShaders', ->
  GLESShaders = {}

  # the default super fast shader!
  GLESShaders.shaderFragmentSrc = [
    "precision mediump float;",
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
    "precision mediump float;",
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
    "precision mediump float;",
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
    shaderProgram = GLESShaders.compileProgram(gl, GLESShaders.primitiveShaderVertexSrc, GLESShaders.primitiveShaderFragmentSrc)
    gl.useProgram shaderProgram
    shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
    shaderProgram.colorAttribute = gl.getAttribLocation(shaderProgram, "aColor")
    shaderProgram.projectionVector = gl.getUniformLocation(shaderProgram, "projectionVector")
    shaderProgram.translationMatrix = gl.getUniformLocation(shaderProgram, "translationMatrix")
    shaderProgram.alpha = gl.getUniformLocation(shaderProgram, "alpha")
    GLESShaders.primitiveProgram = shaderProgram

  GLESShaders.initDefaultShader = (gl) ->
    shaderProgram = GLESShaders.compileProgram(gl, GLESShaders.shaderVertexSrc, GLESShaders.shaderFragmentSrc)
    gl.useProgram shaderProgram
    shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
    shaderProgram.projectionVector = gl.getUniformLocation(shaderProgram, "projectionVector")
    shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram, "aTextureCoord")
    shaderProgram.colorAttribute = gl.getAttribLocation(shaderProgram, "aColor")
    
    # shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix");
    shaderProgram.samplerUniform = gl.getUniformLocation(shaderProgram, "uSampler")
    GLESShaders.shaderProgram = shaderProgram

  GLESShaders.initDefaultStripShader = (gl) ->
    shaderProgram = GLESShaders.compileProgram(gl, GLESShaders.stripShaderVertexSrc, GLESShaders.stripShaderFragmentSrc)
    gl.useProgram shaderProgram
    shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
    shaderProgram.projectionVector = gl.getUniformLocation(shaderProgram, "projectionVector")
    shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram, "aTextureCoord")
    shaderProgram.translationMatrix = gl.getUniformLocation(shaderProgram, "translationMatrix")
    shaderProgram.alpha = gl.getUniformLocation(shaderProgram, "alpha")
    shaderProgram.colorAttribute = gl.getAttribLocation(shaderProgram, "aColor")
    shaderProgram.projectionVector = gl.getUniformLocation(shaderProgram, "projectionVector")
    shaderProgram.samplerUniform = gl.getUniformLocation(shaderProgram, "uSampler")
    GLESShaders.stripShaderProgram = shaderProgram

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
    shaderProgram = gl.createProgram()
    gl.attachShader shaderProgram, vertexShader
    gl.attachShader shaderProgram, fragmentShader
    gl.linkProgram shaderProgram
    alert "Could not initialise shaders"  unless gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
    shaderProgram

  GLESShaders.activateDefaultShader = (gl) ->
    shaderProgram = GLESShaders.shaderProgram
    gl.useProgram shaderProgram
    gl.enableVertexAttribArray shaderProgram.vertexPositionAttribute
    gl.enableVertexAttribArray shaderProgram.textureCoordAttribute
    gl.enableVertexAttribArray shaderProgram.colorAttribute

  GLESShaders.activatePrimitiveShader = (gl) ->
    gl.disableVertexAttribArray GLESShaders.shaderProgram.textureCoordAttribute
    gl.disableVertexAttribArray GLESShaders.shaderProgram.colorAttribute
    gl.useProgram GLESShaders.primitiveProgram
    gl.enableVertexAttribArray GLESShaders.primitiveProgram.vertexPositionAttribute
    gl.enableVertexAttribArray GLESShaders.primitiveProgram.colorAttribute

  return GLESShaders