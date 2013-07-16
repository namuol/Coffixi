###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/extras/CustomRenderable', [
  'Coffixi/display/DisplayObject'
], (
  DisplayObject
) ->

  ###
  Need to finalize this a bit more but works! Its in but will be working on this feature properly next..:)
  @class CustomRenderable
  @extends DisplayObject
  @constructor
  ###
  class CustomRenderable extends DisplayObject
    renderCanvas: (renderer) ->

    # override!
    initWebGL: (renderer) ->

    # override!
    renderWebGL: (renderGroup, projectionMatrix) ->