###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define [
  'Point'
  'Sprite'
], (Point, Sprite) ->
  ###
  The interaction manager deals with mouse and touch events. At this moment only Sprite's can be interactive.
  This manager also supports multitouch.
  @class InteractionManager
  @constructor
  @param stage {Stage}
  @type Stage
  ###
  class InteractionManager
    constructor: (stage) ->
      ###
      a refference to the stage
      @property stage
      @type Stage
      ###
      @stage = stage
      
      # helpers
      @tempPoint = new Point()
      
      #this.tempMatrix =  mat3.create();
      @mouseoverEnabled = true
      
      ###
      the mouse data
      @property mouse
      @type InteractionData
      ###
      @mouse = new InteractionManager.InteractionData()
      
      ###
      an object that stores current touches (InteractionData) by id reference
      @property touchs
      @type Object
      ###
      @touchs = {}
      
      #tiny little interactiveData pool!
      @pool = []
      @interactiveItems = []

    ###
    This method will disable rollover/rollout for ALL interactive items
    You may wish to use this an optimization if your app does not require rollover/rollout funcitonality
    @method disableMouseOver
    ###
    disableMouseOver: ->
      return  unless @mouseoverEnabled
      @mouseoverEnabled = false
      @target.view.removeEventListener "mousemove", @onMouseMove.bind(this)  if @target


    ###
    This method will enable rollover/rollout for ALL interactive items
    It is enabled by default
    @method enableMouseOver
    ###
    enableMouseOver: ->
      return  if @mouseoverEnabled
      @mouseoverEnabled = false
      @target.view.addEventListener "mousemove", @onMouseMove.bind(this)  if @target

    collectInteractiveSprite: (displayObject) ->
      children = displayObject.children
      length = children.length
      i = length - 1

      while i >= 0
        child = children[i]
        
        # only sprite's right now...
        if child instanceof Sprite
          @interactiveItems.push child  if child.interactive
        else
          
          # use this to optimize..
          continue  unless child.interactive
        @collectInteractiveSprite child  if child.children.length > 0
        i--

    setTarget: (target) ->
      @target = target
      target.view.addEventListener "mousemove", @onMouseMove.bind(this), true  if @mouseoverEnabled
      target.view.addEventListener "mousedown", @onMouseDown.bind(this), true
      target.view.addEventListener "mouseup", @onMouseUp.bind(this), true
      target.view.addEventListener "mouseout", @onMouseUp.bind(this), true
      
      # aint no multi touch just yet!
      target.view.addEventListener "touchstart", @onTouchStart.bind(this), true
      target.view.addEventListener "touchend", @onTouchEnd.bind(this), true
      target.view.addEventListener "touchmove", @onTouchMove.bind(this), true

    hitTest: (interactionData) ->
      if @dirty
        @dirty = false
        @interactiveItems = []
        
        # go through and collect all the objects that are interactive..
        @collectInteractiveSprite @stage
      tempPoint = @tempPoint
      tempMatrix = @tempMatrix
      global = interactionData.global
      length = @interactiveItems.length
      i = 0

      while i < length
        item = @interactiveItems[i]
        continue  unless item.visible
        
        # TODO this could do with some optimizing!
        # maybe store the inverse?
        # or do a lazy check first?
        #mat3.inverse(item.worldTransform, tempMatrix);
        #tempPoint.x = tempMatrix[0] * global.x + tempMatrix[1] * global.y + tempMatrix[2]; 
        #tempPoint.y = tempMatrix[4] * global.y + tempMatrix[3] * global.x + tempMatrix[5];
        
        # OPTIMIZED! assuming the matrix transform is affine.. which it totally shold be!
        worldTransform = item.worldTransform
        a00 = worldTransform[0]
        a01 = worldTransform[1]
        a02 = worldTransform[2]
        a10 = worldTransform[3]
        a11 = worldTransform[4]
        a12 = worldTransform[5]
        id = 1 / (a00 * a11 + a01 * -a10)
        tempPoint.x = a11 * id * global.x + -a01 * id * global.y + (a12 * a01 - a02 * a11) * id
        tempPoint.y = a00 * id * global.y + -a10 * id * global.x + (-a12 * a00 + a02 * a10) * id
        x1 = -item.width * item.anchor.x
        if tempPoint.x > x1 and tempPoint.x < x1 + item.width
          y1 = -item.height * item.anchor.y
          if tempPoint.y > y1 and tempPoint.y < y1 + item.height
            interactionData.local.x = tempPoint.x
            interactionData.local.y = tempPoint.y
            return item
        i++
      return null

    onMouseMove: (event) ->
      event.preventDefault()
      
      # TODO optimize by not check EVERY TIME! maybe half as often? //
      rect = @target.view.getBoundingClientRect()
      @mouse.global.x = (event.clientX - rect.left) * (@target.width / rect.width)
      @mouse.global.y = (event.clientY - rect.top) * (@target.height / rect.height)
      item = @hitTest(@mouse)
      unless @currentOver is item
        if @currentOver
          @mouse.target = @currentOver
          @currentOver.mouseout @mouse  if @currentOver.mouseout
          @currentOver = null
        @target.view.style.cursor = "default"
      if item
        return if @currentOver is item
        @currentOver = item
        @target.view.style.cursor = "pointer"
        @mouse.target = item
        item.mouseover @mouse  if item.mouseover

    onMouseDown: (event) ->
      rect = @target.view.getBoundingClientRect()
      @mouse.global.x = (event.clientX - rect.left) * (@target.width / rect.width)
      @mouse.global.y = (event.clientY - rect.top) * (@target.height / rect.height)
      item = @hitTest(@mouse)
      if item
        @currentDown = item
        @mouse.target = item
        item.mousedown @mouse  if item.mousedown

    onMouseUp: (event) ->
      if @currentOver
        @mouse.target = @currentOver
        @currentOver.mouseup @mouse  if @currentOver.mouseup
      if @currentDown
        @mouse.target = @currentDown
        
        # click!
        @currentDown.click @mouse  if @currentDown.click  if @currentOver is @currentDown
        @currentDown = null

    onTouchMove: (event) ->
      event.preventDefault()
      rect = @target.view.getBoundingClientRect()
      changedTouches = event.changedTouches
      i = 0

      while i < changedTouches.length
        touchEvent = changedTouches[i]
        touchData = @touchs[touchEvent.identifier]
        
        # update the touch position
        touchData.global.x = (touchEvent.clientX - rect.left) * (@target.width / rect.width)
        touchData.global.y = (touchEvent.clientY - rect.top) * (@target.height / rect.height)
        i++

    onTouchStart: (event) ->
      event.preventDefault()
      rect = @target.view.getBoundingClientRect()
      changedTouches = event.changedTouches
      i = 0

      while i < changedTouches.length
        touchEvent = changedTouches[i]
        touchData = @pool.pop()
        touchData = new InteractionManager.InteractionData()  unless touchData
        @touchs[touchEvent.identifier] = touchData
        touchData.global.x = (touchEvent.clientX - rect.left) * (@target.width / rect.width)
        touchData.global.y = (touchEvent.clientY - rect.top) * (@target.height / rect.height)
        item = @hitTest(touchData)
        if item
          touchData.currentDown = item
          touchData.target = item
          item.touchstart touchData  if item.touchstart
        i++

    onTouchEnd: (event) ->
      event.preventDefault()
      rect = @target.view.getBoundingClientRect()
      changedTouches = event.changedTouches
      i = 0

      while i < changedTouches.length
        touchEvent = changedTouches[i]
        touchData = @touchs[touchEvent.identifier]
        touchData.global.x = (touchEvent.clientX - rect.left) * (@target.width / rect.width)
        touchData.global.y = (touchEvent.clientY - rect.top) * (@target.height / rect.height)
        if touchData.currentDown
          touchData.currentDown.touchend touchData  if touchData.currentDown.touchend
          item = @hitTest(touchData)
          touchData.currentDown.tap touchData  if touchData.currentDown.tap  if item is touchData.currentDown
          touchData.currentDown = null
        
        # remove the touch..
        @pool.push touchData
        @touchs[touchEvent.identifier] = null
        i++

  class InteractionManager.InteractionData
    ###
    @class InteractionData
    @constructor
    ###
    constructor: ->
      ###
      This point stores the global coords of where the touch/mouse event happened
      @property global
      @type Point
      ###
      @global = new Point()
      
      ###
      This point stores the local coords of where the touch/mouse event happened
      @property local
      @type Point
      ###
      @local = new Point()
      
      ###
      The target Sprite that was interacted with
      @property target
      @type Sprite
      ###
      @target

  return InteractionManager