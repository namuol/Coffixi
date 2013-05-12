###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/WebGLShaders', ->
  WebGLShaders = {}

  WebGLShaders.shaderVertexSrc = [
    "attribute vec2 aVertexPosition;"
    "attribute vec2 aTextureCoord;"
    "attribute float aColor;"
    "uniform mat4 uMVMatrix;"
    "varying vec2 vTextureCoord;"
    "varying float vColor;"
    "void main(void) {"
      "gl_Position = uMVMatrix * vec4(aVertexPosition, 1.0, 1.0);"
      "vTextureCoord = aTextureCoord;"
      "vColor = aColor;"
    "}"
  ]

  WebGLShaders.shaderFragmentSrc = [
    "precision mediump float;"
    "varying vec2 vTextureCoord;"
    "varying float vColor;"
    "uniform sampler2D uSampler;"
    "void main(void) {"
      "gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y));"
      "gl_FragColor = gl_FragColor * vColor;"
    "}"
  ]

  # SCREEN SHADER (for upscaling a fixed-size screen)
  WebGLShaders.screenShaderVertexSrc = [
    "attribute vec2 aVertexPosition;"
    "attribute vec2 aTextureCoord;"
    "varying vec2 vTextureCoord;"
    "void main(void) {"
      "gl_Position = vec4(aVertexPosition, 0.0, 1.0);"
      "vTextureCoord = aTextureCoord;"
    "}"
  ]

  WebGLShaders.screenShaderFragmentSrc = [
    "precision mediump float;"
    "varying vec2 vTextureCoord;"
    "uniform sampler2D uSampler;"
    "void main(void) {"
      "gl_FragColor = texture2D(uSampler, vTextureCoord);"
    "}"
  ]

  WebGLShaders.CompileShader = (gl, shaderSrc, shaderType) ->
    src = ""

    i = 0
    while i < shaderSrc.length
      src += shaderSrc[i]
      i++
    shader = undefined
    shader = gl.createShader(shaderType)
    gl.shaderSource shader, src
    gl.compileShader shader
    unless gl.getShaderParameter(shader, gl.COMPILE_STATUS)
      alert gl.getShaderInfoLog(shader)
      return null
    shader

  return WebGLShaders