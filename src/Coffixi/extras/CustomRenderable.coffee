###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/extras/CustomRenderable', [
  'Coffixi/display/DisplayObject'
], (
  DisplayObject
) ->

  ###*
  This object is one that will allow you to specify custom rendering functions based on render type

  @class CustomRenderable
  @extends DisplayObject
  @constructor
  ###
  class CustomRenderable extends DisplayObject
    constructor: ->
      super

    ###*
    If this object is being rendered by a CanvasRenderer it will call this callback

    @method renderCanvas
    @param renderer {CanvasRenderer} The renderer instance
    ###
    renderCanvas: (renderer) ->

    # override!

    ###*
    If this object is being rendered by a WebGLRenderer it will call this callback to initialize

    @method initWebGL
    @param renderer {WebGLRenderer} The renderer instance
    ###
    initWebGL: (renderer) ->

    # override!

    ###*
    If this object is being rendered by a WebGLRenderer it will call this callback

    @method renderGLES
    @param renderer {WebGLRenderer} The renderer instance
    ###
    renderGLES: (renderGroup, projectionMatrix) ->

    # not sure if both needed? but ya have for now!
    # override!
