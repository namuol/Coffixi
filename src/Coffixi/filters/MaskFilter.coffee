###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/filters/MaskFilter', ->
  
  class MaskFilter
    constructor: (graphics) ->
      # the graphics data that will be used for filtering
      @graphics
