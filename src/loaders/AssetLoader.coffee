###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define [
  'utils/EventTarget'
  'textures/Texture'
  'loaders/SpriteSheetLoader'
], (EventTarget, Texture, SpriteSheetLoader) ->
  ###
  A Class that loads a bunch of images / sprite sheet files. Once the assets have been loaded they are added to the Texture cache and can be accessed easily through Texture.fromFrame(), Texture.fromImage() and Sprite.fromImage(), Sprite.fromFromeId()
  When all items have been loaded this class will dispatch a 'loaded' event
  As each individual item is loaded this class will dispatch a 'progress' event
  @class AssetLoader
  @constructor
  @extends EventTarget
  @param assetURLs {Array} an array of image/sprite sheet urls that you would like loaded supported. Supported image formats include "jpeg", "jpg", "png", "gif". Supported sprite sheet data formats only include "JSON" at this time
  ###
  class AssetLoader extends EventTarget
    constructor: (assetURLs) ->
      super
      
      ###
      The array of asset URLs that are going to be loaded
      @property assetURLs
      @type Array
      ###
      @assetURLs = assetURLs
      @assets = []
      @crossorigin = false

    ###
    Fired when an item has loaded
    @event onProgress
    ###

    ###
    Fired when all the assets have loaded
    @event onComplete
    ###

    load: ->
      @loadCount = @assetURLs.length
      imageTypes = ["jpeg", "jpg", "png", "gif"]
      spriteSheetTypes = ["json"]
      i = 0
      while i < @assetURLs.length
        filename = @assetURLs[i]
        fileType = filename.split(".").pop().toLowerCase()
        
        # what are we loading?
        type = null
        j = 0

        while j < imageTypes.length
          if fileType is imageTypes[j]
            type = "img"
            break
          j++
        unless type is "img"
          j = 0

          while j < spriteSheetTypes.length
            if fileType is spriteSheetTypes[j]
              type = "atlas"
              break
            j++
        if type is "img"
          texture = Texture.fromImage(filename, @crossorigin)
          unless texture.baseTexture.hasLoaded
            scope = this
            texture.baseTexture.addEventListener "loaded", (event) ->
              scope.onAssetLoaded()

            @assets.push texture
          else
            # already loaded!
            @loadCount--
            
            # if this hits zero here.. then everything was cached!
            if @loadCount is 0
              @dispatchEvent
                type: "onComplete"
                content: this

              @onComplete()  if @onComplete
        else if type is "atlas"
          spriteSheetLoader = new SpriteSheetLoader(filename)
          spriteSheetLoader.crossorigin = @crossorigin
          @assets.push spriteSheetLoader
          scope = this
          spriteSheetLoader.addEventListener "loaded", (event) ->
            scope.onAssetLoaded()

          spriteSheetLoader.load()
        else
          
          # dont know what the file is! :/
          #this.loadCount--;
          throw new Error(filename + " is an unsupported file type " + this)
        i++

    onAssetLoaded: ->
      @loadCount--
      @dispatchEvent
        type: "onProgress"
        content: this

      @onProgress()  if @onProgress
      if @loadCount is 0
        @dispatchEvent
          type: "onComplete"
          content: this

        @onComplete()  if @onComplete

  return AssetLoader