define 'Coffixi/utils/Module', ->
  # LOU TODO: Docs
    
  # From http://arcturo.github.io/library/coffeescript/03_classes.html

  moduleKeywords = ['onMixinStatic', 'onMixin', 'constructor']

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

      obj.onMixin?.call(@)
      return @

    # TODO @extend for JS extending/super calling
    @extend: (props) ->
      __super__ = @
      __wrapped__ = (superFunc, func) ->
        return ->
          @super = superFunc
          ret = func.apply @, arguments
          delete @super
          return ret

      if props.hasOwnProperty 'constructor'
        __ctor__ = ->
          @super = __super__::constructor
          props.constructor.apply @, arguments
          delete @super
          return @
      else
        __ctor__ = -> __super__::constructor.apply @, arguments

      class __CLASS__ extends __super__
        constructor: __ctor__
        for own key,val of props
          if (typeof val is 'function') and (typeof __super__::[key] is 'function')
            __CLASS__::[key] = __wrapped__(__super__::[key], val)
          else
            __CLASS__::[key] = val

      return __CLASS__

  window.Module = Module

  return Module