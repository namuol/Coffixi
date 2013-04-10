###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/MovieClip', [
  './Sprite'
], (Sprite) ->
  ###
  A MovieClip is a simple way to display an animation depicted by a list of textures.
  @class MovieClip
  @extends Sprite
  @constructor
  @param textures {Array} an array of {Texture} objects that make up the animation
  ###
  class MovieClip extends Sprite
    constructor: (textures) ->
      super textures[0]
      
      ###
      The array of textures that make up the animation
      @property textures
      @type Array
      ###
      @textures = textures
      
      ###
      [read only] The index MovieClips current frame (this may not have to be a whole number)
      @property currentFrame
      @type Number
      ###
      @currentFrame = 0
      
      ###
      The speed that the MovieClip will play at. Higher is faster, lower is slower
      @property animationSpeed
      @type Number
      ###
      @animationSpeed = 1
      
      ###
      [read only] indicates if the MovieClip is currently playing
      @property playing
      @type Boolean
      ###
      @playing

    ###
    Stops the MovieClip
    @method stop
    ###
    stop: ->
      @playing = false

    ###
    Plays the MovieClip
    @method play
    ###
    play: ->
      @playing = true

    ###
    Stops the MovieClip and goes to a specific frame
    @method gotoAndStop
    @param frameNumber {Number} frame index to stop at
    ###
    gotoAndStop: (frameNumber) ->
      @playing = false
      @currentFrame = frameNumber
      round = (@currentFrame + 0.5) | 0
      @setTexture @textures[round % @textures.length]

    ###
    Goes to a specific frame and begins playing the MovieClip
    @method gotoAndPlay
    @param frameNumber {Number} frame index to start at
    ###
    gotoAndPlay: (frameNumber) ->
      @currentFrame = frameNumber
      @playing = true

    updateTransform: ->
      super
      return if not @playing

      @currentFrame += @animationSpeed
      round = (@currentFrame + 0.5) | 0
      @setTexture @textures[round % @textures.length]
  
  return MovieClip