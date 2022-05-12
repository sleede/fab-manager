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
