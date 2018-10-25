Application.Directives.directive 'confirmationNeeded', [->
  return {
    priority: 1
    terminal: true
    link: (scope, element, attrs)->
      msg = attrs.confirmationNeeded || "Are you sure?"
      clickAction = attrs.ngClick
      element.bind 'click', ->
        if attrs.confirmationNeededIf?
          confirmNeededIf = scope.$eval(attrs.confirmationNeededIf)
          if confirmNeededIf == true
            if ( window.confirm(msg) )
              scope.$eval(clickAction)
          else
            scope.$eval(clickAction)
        else
          if ( window.confirm(msg) )
            scope.$eval(clickAction)
    }
]
