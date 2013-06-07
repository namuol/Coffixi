###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/loaders/AssetLoader', [
  '../utils/EventTarget'
  '../textures/Texture'
], (
  EventTarget
  Texture
) ->

  ###
  The image loader class is responsible for loading images file formats ("jpeg", "jpg", "png" and "gif")
  Once the image has been loaded it is stored in the texture cache and can be accessed though Texture.fromFrameId() and Sprite.fromFromeId()
  When loaded this class will dispatch a 'loaded' event
  @class ImageLoader
  @extends EventTarget
  @constructor
  @param {String} url The url of the image
  @param {Boolean} crossorigin
  ###
  class ImageLoader extends EventTarget
    constructor: (url, crossorigin) ->
      super
      @texture = Texture.fromImage(url, crossorigin)

    ###
    Loads image or takes it from cache
    ###
    load: ->
      unless @texture.baseTexture.hasLoaded
        scope = this
        @texture.baseTexture.addEventListener "loaded", ->
          scope.onLoaded()

      else
        @onLoaded()

    ###
    Invoked when image file is loaded or it is already cached and ready to use
    @private
    ###
    onLoaded: ->
      @emit
        type: "loaded"
        content: this