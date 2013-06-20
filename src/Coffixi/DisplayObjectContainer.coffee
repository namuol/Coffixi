###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/DisplayObjectContainer', [
  './DisplayObject'
], (
  DisplayObject
) ->

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
      
      #s
      @renderable = false

      #TODO make visible a getter setter
      #
      #Object.defineProperty(PIXI.DisplayObjectContainer.prototype, 'visible', {
      #    get: function() {
      #        return this._visible;
      #    },
      #    set: function(value) {
      #        this._visible = value;
      #        
      #    }
      #});

    ###
    Adds a child to the container.
    @method addChild
    @param  DisplayObject {DisplayObject}
    ###
    addChild: (child) ->
      child.parent.removeChild(child) if child.parent?
      child.parent = this
      child.childIndex = @children.length
      @children.push child
      @stage.__addChild child  if @stage
      
      # need to remove any render groups..
      if @__renderGroup
        
        # being used by a renderTexture.. if it exists then it must be from a render texture;
        child.__renderGroup.removeDisplayObjectAndChildren child  if child.__renderGroup
        
        # add them to the new render group..
        @__renderGroup.addDisplayObjectAndChildren child

    ###
    Adds a child to the container at a specified index. If the index is out of bounds an error will be thrown
    @method addChildAt
    @param DisplayObject {DisplayObject}
    @param index {Number}
    ###
    addChildAt: (child, index) ->
      if index >= 0 and index <= @children.length
        child.parent.removeChild(child) if child.parent?
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
        
        # need to remove any render groups..
        if @__renderGroup
          
          # being used by a renderTexture.. if it exists then it must be from a render texture;
          child.__renderGroup.removeDisplayObjectAndChildren child  if child.__renderGroup
          
          # add them to the new render group..
          @__renderGroup.addDisplayObjectAndChildren child
      else
        # error!
        throw new Error(child + " The index " + index + " supplied is out of bounds " + @children.length)

    ###
    Swaps the depth of 2 displayObjects
    @method swapChildren
    @param  DisplayObject {DisplayObject}
    @param  DisplayObject2 {DisplayObject}
    ###
    swapChildren: (child, child2) ->
      
      # TODO I already know this??
      index = @children.indexOf(child)
      index2 = @children.indexOf(child2)
      if index isnt -1 and index2 isnt -1
        
        # cool
        if @stage
          
          # this is to satisfy the webGL batching..
          # TODO sure there is a nicer way to achieve this!
          @stage.__removeChild child
          @stage.__removeChild child2
          @stage.__addChild child
          @stage.__addChild child2
        
        # swap the indexes..
        child.childIndex = index2
        child2.childIndex = index
        
        # swap the positions..
        @children[index] = child2
        @children[index2] = child
      else
        throw new Error(child + " Both the supplied DisplayObjects must be a child of the caller " + this)

    ###
    Returns the Child at the specified index
    @method getChildAt
    @param  index {Number}
    ###
    getChildAt: (index) ->
      if index >= 0 and index < @children.length
        @children[index]
      else
        throw new Error(child + " Both the supplied DisplayObjects must be a child of the caller " + this)

    ###
    Removes a child from the container.
    @method removeChild
    @param  DisplayObject {DisplayObject}
    ###
    removeChild: (child) ->
      index = @children.indexOf(child)
      if index != -1
        @stage.__removeChild child  if @stage
        child.parent = undefined

        # webGL trim
        child.__renderGroup.removeDisplayObjectAndChildren child  if child.__renderGroup
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
    Removes all children from the container.
    @method clearChildren
    ###
    clearChildren: ->
      children = @children.slice 0
      for child in children
        @removeChild child
      @children = []

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