###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/loaders/AssetLoader', [
  '../utils/EventTarget'
  '../textures/Texture'
  './ImageLoader'
  './SpriteSheetLoader'
], (
  EventTarget
  Texture
  ImageLoader
  SpriteSheetLoader
) ->

  ###
  A Class that loads a bunch of images / sprite sheet / bitmap font files. Once the assets have been loaded they are added to the PIXI Texture cache and can be accessed easily through PIXI.Texture.fromImage() and PIXI.Sprite.fromImage()
  When all items have been loaded this class will dispatch a "onLoaded" event
  As each individual item is loaded this class will dispatch a "onProgress" event
  @class AssetLoader
  @constructor
  @extends EventTarget
  @param {Array} assetURLs an array of image/sprite sheet urls that you would like loaded supported. Supported image formats include "jpeg", "jpg", "png", "gif". Supported sprite sheet data formats only include "JSON" at this time. Supported bitmap font data formats include "xml" and "fnt".
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
      @crossorigin = false
      @loadersByType =
        jpg: ImageLoader
        jpeg: ImageLoader
        png: ImageLoader
        gif: ImageLoader
        json: SpriteSheetLoader

    ###
    Fired when an item has loaded
    @event onProgress
    ###

    ###
    Fired when all the assets have loaded
    @event onComplete
    ###

    ###
    This will begin loading the assets sequentially
    ###
    load: ->
      scope = this
      @loadCount = @assetURLs.length
      i = 0

      while i < @assetURLs.length
        fileName = @assetURLs[i]
        fileType = fileName.split(".").pop().toLowerCase()
        loaderClass = @loadersByType[fileType]
        throw new Error(fileType + " is an unsupported file type")  unless loaderClass
        loader = new loaderClass(fileName, @crossorigin)
        loader.addEventListener "loaded", ->
          scope.onAssetLoaded()

        loader.load()
        i++

    ###
    Invoked after each file is loaded
    @private
    ###
    onAssetLoaded: ->
      @loadCount--
      @emit
        type: "onProgress"
        content: this

      @onProgress()  if @onProgress
      if @loadCount is 0
        @emit
          type: "onComplete"
          content: this

        @onComplete()  if @onComplete