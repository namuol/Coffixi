###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/filters/FilterBlock', [
	'Coffixi/utils/Module'
	'Coffixi/core/RenderTypes'
], (
	Module
	RenderTypes
) ->

  class FilterBlock extends Module
    constructor: (mask) ->
      @graphics = mask
      @visible = true
      @renderable = true
    
  	__renderType: RenderTypes.FILTERBLOCK
