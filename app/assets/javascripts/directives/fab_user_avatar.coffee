Application.Directives.directive 'fabUserAvatar', [ ->
    {
    restrict: 'E'
    scope:
        userAvatar: "=ngModel"
        avatarClass: '@'
    templateUrl: '<%= asset_path "shared/_user_avatar.html" %>'
    }
]

