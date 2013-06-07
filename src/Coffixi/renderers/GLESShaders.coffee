###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/GLESShaders', ->
  GLESShaders = {}

  GLESShaders.shaderVertexSrc = [
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

  GLESShaders.shaderFragmentSrc = [
    "#ifdef GL_ES"
    "precision mediump float;"
    "#endif"
    "varying vec2 vTextureCoord;"
    "varying float vColor;"
    "uniform sampler2D uSampler;"
    "void main(void) {"
      "gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y));"
      "gl_FragColor = gl_FragColor * vColor;"
    "}"
  ]

  # SCREEN SHADER (for upscaling a fixed-size screen)
  GLESShaders.screenShaderVertexSrc = [
    "attribute vec2 aVertexPosition;"
    "attribute vec2 aTextureCoord;"
    "varying vec2 vTextureCoord;"
    "void main(void) {"
      "gl_Position = vec4(aVertexPosition, 0.0, 1.0);"
      "vTextureCoord = aTextureCoord;"
    "}"
  ]

  GLESShaders.screenShaderFragmentSrc = [
    "#ifdef GL_ES"
    "precision mediump float;"
    "#endif"
    "varying vec2 vTextureCoord;"
    "uniform sampler2D uSampler;"
    "void main(void) {"
      "gl_FragColor = texture2D(uSampler, vTextureCoord);"
    "}"
  ]

  GLESShaders.CompileVertexShader = (gl, shaderSrc) -> GLESShaders.CompileShader gl, shaderSrc, gl.VERTEX_SHADER
  GLESShaders.CompileFragmentShader = (gl, shaderSrc) -> GLESShaders.CompileShader gl, shaderSrc, gl.FRAGMENT_SHADER

  GLESShaders.CompileShader = (gl, shaderSrc, shaderType) ->
    src = ""

    i = 0
    while i < shaderSrc.length
      src += shaderSrc[i] + '\n'
      i++
    shader = undefined
    shader = gl.createShader(shaderType)
    gl.shaderSource shader, src
    gl.compileShader shader
    unless gl.getShaderParameter(shader, gl.COMPILE_STATUS)
      alert gl.getShaderInfoLog(shader)
      return null
    shader

  return GLESShaders