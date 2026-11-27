# Single-Sign-On authentication using OpenID Connect

Configuration of an OpenID Connect provider is designed to be easier than the OAuth 2.0 authentication method.
Nevertheless, it is less powerful and allows only limited fields mapping to the OpenID `userinfo` endpoint.

We highly recommend using the [Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html) mechanism to get the configuration of the OpenID Connect provider.

When configuring an authentication provider using the OpenID Connect protocol, the following fields can be mapped automatically
to the corresponding OpenID Connect claims:

- user.uid
- user.email
- user.username
- profile.first_name
- profile.last_name
- profile.avatar
- profile.website
- profile.gender
- profile.birthday
- profile.phone
- profile.address

To use the automatic mapping, add one of the fields above and click on the magic wand button near to the "Userinfo claim" input.

To activate your new authentication provider, execute the following command within your fabmanager Docker container:

`rails fablab:auth:switch_provider[PROVIDER_NAME]`

**Note:** A container restart is required for the changes to take effect (for any change of the provider settings)!

## Known issues

```
Not found. Authentication passthru.
```
This issue may occur if you have misconfigured the environment variable `DEFAULT_HOST` and/or `DEFAULT_PROTOCOL`.
Especially, if you have an automatic redirection (e.g. from example.org to example.com), `DEFAULT_HOST` *MUST* be configured with the redirection target (here example.com).
Once you have reconfigured these variables, please switch back the active authentication provider to FabManager, restart the application, then delete the OIDC provider you configured and re-create a new one for the new settings to be used.

```
JSON::JWK::Set::KidNotFound (JSON::JWK::Set::KidNotFound)
```
This issue may occur if the ID Token signature algorithm is not set to `RSxxx` on your IDP.
Especially, this is not the default option when using LemonLDAP::NG, which uses `HSxxx` as the default algorithm, but you can configure it in `OpenID Connect Relaying Parties` > `my-fab-manager` > `Options` > `Security` > `ID Token signature algorithm`.
Using Keycloak, you can configure it in `Clients` > `my-fab-manager` > `Settings` > `Fine Grain OpenID Connect Configuration` > `ID Token Signature Algorithm`.
```
Issuer mismatch
```
Check that your configured issuer URL ends with a trailing slash.
