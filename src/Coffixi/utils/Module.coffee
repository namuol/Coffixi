define 'Coffixi/utils/Module', ->
  # LOU TODO: Docs
    
  # From http://arcturo.github.io/library/coffeescript/03_classes.html

  moduleKeywords = ['onMixinStatic', 'onMixin', 'constructor', '__properties__']

  class Module
    @mixinStatic: (obj) ->
      for key, value of obj when key not in moduleKeywords
        @[key] = value

      obj.onMixinStatic?.call(@)
      return @
    
    @mixin: (obj) ->
      for key, value of obj when key not in moduleKeywords
        # Assign properties to the prototype
        @::[key] = value

      for own name, metaProperties of obj.__properties__
        Object.defineProperty @::, name, metaProperties

      obj.onMixin?.call(@)
      return @

    @property: (name, metaProperties) ->
      @::__properties__ ?= {}
      @::__properties__[name] = metaProperties
      Object.defineProperty @::, name, metaProperties

    # TODO @extend for JS extending/super calling

  return Module