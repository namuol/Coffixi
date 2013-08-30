###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/display/DisplayObjectContainer', [
  './DisplayObject'
], (
  DisplayObject
) ->

  ###
  A DisplayObjectContainer represents a collection of display objects.
  It is the base class of all display objects that act as a container for other objects.

  @class DisplayObjectContainer
  @extends DisplayObject
  @constructor
  ###
  class DisplayObjectContainer extends DisplayObject
    constructor: ->
      super
      
      ###
      [read-only] The of children of this container.
      
      @property children
      @type Array<DisplayObject>
      @readOnly
      ###
      @children = []

    #TODO make visible a getter setter
    #
    #Object.defineProperty(DisplayObjectContainer.prototype, 'visible', {
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
    @param child {DisplayObject} The DisplayObject to add to the container
    ###
    addChild: (child) ->
      
      #// COULD BE THIS???
      child.parent.removeChild(child)  if child.parent?
      
      #	return;
      child.parent = this
      @children.push child
      
      # updae the stage refference..
      if @stage
        tmpChild = child
        loop
          tmpChild.stage = @stage
          tmpChild = tmpChild._iNext
          break unless tmpChild
      
      # LINKED LIST //
      
      # modify the list..
      childFirst = child.first
      childLast = child.last
      nextObject = undefined
      previousObject = undefined
      
      # this could be wrong if there is a filter??
      if @filter
        previousObject = @last._iPrev
      else
        previousObject = @last
      nextObject = previousObject._iNext
      
      # always true in this case
      #this.last = child.last;
      # need to make sure the parents last is updated too
      updateLast = this
      prevLast = previousObject
      while updateLast
        updateLast.last = child.last  if updateLast.last is prevLast
        updateLast = updateLast.parent
      if nextObject
        nextObject._iPrev = childLast
        childLast._iNext = nextObject
      childFirst._iPrev = previousObject
      previousObject._iNext = childFirst
      
      # need to remove any render groups..
      if @__renderGroup
        
        # being used by a renderTexture.. if it exists then it must be from a render texture;
        child.__renderGroup.removeDisplayObjectAndChildren child  if child.__renderGroup
        
        # add them to the new render group..
        @__renderGroup.addDisplayObjectAndChildren child


    ###
    Adds a child to the container at a specified index. If the index is out of bounds an error will be thrown

    @method addChildAt
    @param child {DisplayObject} The child to add
    @param index {Number} The index to place the child in
    ###
    addChildAt: (child, index) ->
      if index >= 0 and index <= @children.length
        child.parent.removeChild(child)  if child.parent?
        child.parent = this
        if @stage
          tmpChild = child
          loop
            tmpChild.stage = @stage
            tmpChild = tmpChild._iNext
            break unless tmpChild
        
        # modify the list..
        childFirst = child.first
        childLast = child.last
        nextObject = undefined
        previousObject = undefined
        if index is @children.length
          previousObject = @last
          updateLast = this #.parent;
          prevLast = @last
          while updateLast
            updateLast.last = child.last  if updateLast.last is prevLast
            updateLast = updateLast.parent
        else if index is 0
          previousObject = this
        else
          previousObject = @children[index - 1].last
        nextObject = previousObject._iNext
        
        # always true in this case
        if nextObject
          nextObject._iPrev = childLast
          childLast._iNext = nextObject
        childFirst._iPrev = previousObject
        previousObject._iNext = childFirst
        @children.splice index, 0, child
        
        # need to remove any render groups..
        if @__renderGroup
          
          # being used by a renderTexture.. if it exists then it must be from a render texture;
          child.__renderGroup.removeDisplayObjectAndChildren child  if child.__renderGroup
          
          # add them to the new render group..
          @__renderGroup.addDisplayObjectAndChildren child
      else
        throw new Error(child + " The index " + index + " supplied is out of bounds " + @children.length)


    ###
    [NYI] Swaps the depth of 2 displayObjects

    @method swapChildren
    @param child {DisplayObject}
    @param child2 {DisplayObject}
    @private
    ###
    swapChildren: (child, child2) ->
      
      #
      #	 * this funtion needs to be recoded.. 
      #	 * can be done a lot faster..
      #	 
      return


    # need to fix this function :/
    #
    #	// TODO I already know this??
    #	var index = this.children.indexOf( child );
    #	var index2 = this.children.indexOf( child2 );
    #	
    #	if ( index !== -1 && index2 !== -1 ) 
    #	{
    #		// cool
    #		
    #		/*
    #		if(this.stage)
    #		{
    #			// this is to satisfy the webGL batching..
    #			// TODO sure there is a nicer way to achieve this!
    #			this.stage.__removeChild(child);
    #			this.stage.__removeChild(child2);
    #			
    #			this.stage.__addChild(child);
    #			this.stage.__addChild(child2);
    #		}
    #		
    #		// swap the positions..
    #		this.children[index] = child2;
    #		this.children[index2] = child;
    #		
    #	}
    #	else
    #	{
    #		throw new Error(child + " Both the supplied DisplayObjects must be a child of the caller " + this);
    #	}

    ###
    Returns the Child at the specified index

    @method getChildAt
    @param index {Number} The index to get the child from
    ###
    getChildAt: (index) ->
      if index >= 0 and index < @children.length
        @children[index]
      else
        throw new Error(child + " Both the supplied DisplayObjects must be a child of the caller " + this)
    

    ###
    Removes a child from the container.

    @method removeChild
    @param child {DisplayObject} The DisplayObject to remove
    ###
    removeChild: (child) ->
      index = @children.indexOf(child)
      if index isnt -1
        
        # unlink //
        # modify the list..
        childFirst = child.first
        childLast = child.last
        nextObject = childLast._iNext
        previousObject = childFirst._iPrev
        nextObject._iPrev = previousObject  if nextObject
        previousObject._iNext = nextObject
        if @last is childLast
          tempLast = childFirst._iPrev
          
          # need to make sure the parents last is updated too
          updateLast = this
          while updateLast.last is childLast.last
            updateLast.last = tempLast
            updateLast = updateLast.parent
            break  unless updateLast
        childLast._iNext = null
        childFirst._iPrev = null
        
        # update the stage reference..
        if @stage
          tmpChild = child
          loop
            tmpChild.stage = null
            tmpChild = tmpChild._iNext
            break unless tmpChild
        
        # webGL trim
        child.__renderGroup.removeDisplayObjectAndChildren child  if child.__renderGroup
        child.parent = `undefined`
        @children.splice index, 1
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

    #
    # * Updates the container's children's transform for rendering
    # *
    # * @method updateTransform
    # * @private
    # 
    updateTransform: ->
      return  unless @visible
      
      super

      i = 0
      j = @children.length

      while i < j
        @children[i].updateTransform()
        i++
