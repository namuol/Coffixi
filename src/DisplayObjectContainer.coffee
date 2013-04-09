###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define [
  'DisplayObject'
], (DisplayObject) ->
  
  ###
  A DisplayObjectContainer represents a collection of display objects. It is the base class of all display objects that act as a container for other objects.
  @class DisplayObjectContainer
  @extends DisplayObject
  @constructor
  ###
  class DisplayObjectContainer extends DisplayObject
    constructor: ->
      super
      ###
      [read-only] The of children of this container.
      @property children {Array}
      ###
      @children = []
      
      @renderable = false

    ###
    Adds a child to the container.
    @method addChild
    @param  DisplayObject {DisplayObject}
    ###
    addChild: (child) ->
      child.parent.removeChild child  unless child.parent is `undefined`
      child.parent = this
      child.childIndex = @children.length
      @children.push child
      @stage.__addChild child  if @stage


    ###
    Adds a child to the container at a specified index. If the index is out of bounds an error will be thrown
    @method addChildAt
    @param DisplayObject {DisplayObject}
    @param index {Number}
    ###
    addChildAt: (child, index) ->
      if index >= 0 and index <= @children.length
        child.parent.removeChild child  unless child.parent is `undefined`
        if index is @children.length
          @children.push child
        else
          @children.splice index, 0, child
        child.parent = this
        child.childIndex = index
        length = @children.length
        i = index

        while i < length
          @children[i].childIndex = i
          i++
        @stage.__addChild child  if @stage
      else
        # error!
        throw new Error(child + " The index " + index + " supplied is out of bounds " + @children.length)


    ###
    Removes a child from the container.
    @method removeChild
    @param  DisplayObject {DisplayObject}
    ###
    removeChild: (child) ->
      index = @children.indexOf(child)
      if index != -1
        @stage.__removeChild child  if @stage
        child.parent = `undefined`
        
        #child.childIndex = 0
        @children.splice index, 1
        
        # update in dexs!
        i = index
        j = @children.length

        while i < j
          @children[i].childIndex -= 1
          i++
      else
        throw new Error(child + " The supplied DisplayObject must be a child of the caller " + this)

    ###
    @private
    ###
    updateTransform: ->
      return if not @visible
      super

      i = 0
      j = @children.length

      while i < j
        @children[i].updateTransform()
        i++
