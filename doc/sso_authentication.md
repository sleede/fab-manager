# How to add an authentication method to the Fab-Manager ?

First, take a look at the [OmniAuth list of strategies](https://github.com/intridea/omniauth/wiki/List-of-Strategies) for the Strategy or Developer Strategy you want to add to the Fab-Manager.
 
For this guide, we will consider you want to add a generic *developer strategy*, like LDAP.

Create the OmniAuth implementation ( **lib/omni_auth/strategies/ldap_provider.rb** )

```ruby
# first require the OmniAuth gem you added to your Gemfile (see the link above for a list of gems)
require 'omniauth-ldap'
module OmniAuth
  module Strategies
    # in the class name, replace Ldap with the kind of authentication you are implementing
    class SsoLdapProvider < OmniAuth::Strategies::LDAP
      # implement the logic here, see the gem specific documentation for more details 
    end
  end
end
```

Create the ActiveRecord models ( **from the terminal** )

```bash
# in the models names, replace Ldap with the kind of authentication you are implementing 
# replace ldap_fields with the fields you need for implementing LDAP or whatever you are implementing
rails g model LdapProvider ...ldap_fields
rails g model LdapMapping ldap_provider:belongs_to local_field:string local_model:string ...ldap_fields
```
    
Complete the Provider Model ( **app/model/ldap_provider.rb** )

```ruby
class LdapProvider < ActiveRecord::Base
  has_one :auth_provider, as: :providable
  has_many :ldap_mappings, dependent: :destroy
  accepts_nested_attributes_for :ldap_mappings, allow_destroy: true

  # return the fields you want to protect from being directly managed by the Fab-Manager, typically mapped fields
  def protected_fields
    fields = []
    ldap_mappings.each do |mapping|
      fields.push(mapping.local_model+'.'+mapping.local_field)
    end
    fields
  end
  
  # return the link, that the current user will have to follow, to edit his profile on the SSO
  def profile_url
    # you can also create a profile_url field in the Database model
  end
end
```
Whitelist your implementation's fields in the controller ( **app/controllers/api/auth_providers_controller.rb** )

```ruby
class API::AuthProvidersController < API::ApiController
  ...
  private
    def provider_params
      if params['auth_provider']['providable_type'] == DatabaseProvider.name
        ...
      elsif if params['auth_provider']['providable_type'] == LdapProvider.name
        params.require(:auth_provider).permit(:name, :providable_type, providable_attributes: [
          # list here your LdapProvider model's fields, followed by the mappings :
          ldap_mappings_attributes: [
            :id, :local_model, :local_field, ...
            # add your other customs LdapMapping fields, don't forget the :_destroy symbol if
            # you want your admin to be able to remove mappings 
          ]
        ])
      end
    end
end 
```

List the fields to display in the JSON API view ( **app/views/api/auth_providers/show.json.jbuilder** )

```ruby
json.partial! 'api/auth_providers/auth_provider', auth_provider: @provider

...

if @provider.providable_type == LdapProvider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, ... # list LdapProvider fields here
    json.ldap_mappings_attributes @provider.providable.ldap_mappings do |m|
      json.extract! m, :id, :local_model, :local_field, ... # list LdapMapping fields here
    end
  end
end
```

Configure the initializer ( **config/initializers/devise.rb** )

```ruby
require_relative '../../lib/omni_auth/omni_auth'
...
elsif active_provider.providable_type == LdapProvider.name
  config.omniauth OmniAuth::Strategies::SsoLdapProvider.name.to_sym, # pass here the required parameters, see the gem documentation for details
end
```
    
Finally you have to create an admin interface with AngularJS:

- **app/assets/templates/admin/authentifications/_ldap.html.erb** must contains html input fields (partial html form) for the LdapProvider fields configuration
- **app/assets/templates/admin/authentifications/_ldap_mapping.html.erb** must contains html partial to configure the LdapMappings, see _oauth2_mapping.html.erb for a working example
- **app/assets/javascript/controllers/admin/authentifications.coffee**

```coffeescript
## list of supported authentication methods
METHODS = {
  ...
  'LdapProvider' : 'LDAP' # add the name of your ActiveRecord model class here as a hash key, associated with a human readable name as a hash value (string) 
}

Application.Controllers.controller "newAuthentificationController", ...

$scope.updateProvidable = -> 
  ...
  if $scope.provider.providable_type == 'LdapProvider'
    # you may want to do some stuff to initialize your provider here
    
$scope.registerProvider = ->
  ...
  # === LdapProvider ===
  else if $scope.provider.providable_type == 'LdapProvider'
    # here you may want to do some data validation
    # then: save the settings
    AuthProvider.save auth_provider: $scope.provider, (provider) ->
      # register was a success, display a message, redirect, etc.
```

And to include this interface into the existing one ( **app/assets/templates/admin/authentifications/edit.html.erb**)

```html
<form role="form" name="providerForm" class="form-horizontal" novalidate>
  ...
  <!-- Add the following ng-include inside the providerForm -->
  <ng-include src="'<%= asset_path 'admin/authentifications/_ldap.html'%>'" ng-if="provider.providable_type == 'LdapProvider'"></ng-include>
</form>
```

Do not forget that you can find examples and inspiration in the OAuth 2.0 implementation.