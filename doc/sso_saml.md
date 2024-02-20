# Single-Sign-On authentication using SAML
This document provides instructions on how to configure SAML (Security Assertion Markup Language) in FabManager. SAML enables secure single sign-on (SSO) authentication between a service provider (SP), such as FabManager, and an identity provider (IdP), which could be your organization's authentication system.

## Configuration Steps:

1. Gather Required Information:
Before configuring SAML in FabManager, ensure you have the following information from your identity provider:

* Service provider entity ID
* Identity provider SSO service URL (required)
* Identity provider certificate fingerprint (SHA1 format) or Identity provider certificate (PEM format)
* Single logout request URL (option)

2. Access FabManager Configuration:
Log in to your FabManager instance with administrative privileges.

3. Navigate to Users Settings -> Authentication:
Add a new authentication provider, enter your name of new authentification

4. Select SAML:
Locate the authentication type option to enable SAML.

5. Enter SAML Configuration Details:
Now, enter the SAML configuration details obtained from your identity provider into the corresponding fields in FabManager's SAML settings. These fields typically include:

SP Entity ID: Enter the Service Provider entity ID. (required)
IdP SSO Service URL: Provide the Identity Provider SSO service URL. (required)
IdP Certificate Fingerprint: Enter the fingerprint of the Identity Provider certificate.(SHA1 format)
IdP Certificate: Enter the Identity Provider certificate.(PEM format)
Profile URL: Enter the Profile edition URL.(required)
IdP SLO Service URL: Provide the Single Logout Request URL. (option)

6. Configuring User Profile Attributes Mapping in FabManager
FabManager allows you to map user profile attributes to ensure that essential information, such as user UID, email, first name, and last name, is accurately synchronized between the identity provider (IdP) and FabManager.
Before proceeding with mapping, ensure you understand the user profile attributes you want to synchronize. Based on your requirements, identify the following attributes:

user.uid: Unique identifier for the user.
user.email: User's email address.
profile.first_name: User's first name.
profile.last_name: User's last name.

7. Save Configuration:
After entering all the required information, save the SAML configuration settings.

## After configuring SAML integration in FabManager, you need to follow these steps to activate SAML authentication within the application:

1. Access FabManager Docker Container:
Use the following command to enter the FabManager Docker container:
```bash
docker exec -it CONTAINER_NAME_APP bash
```
Replace `CONTAINER_NAME_APP` with the actual name of your FabManager Docker container.

2. Switch to SAML Authentication:
Once inside the Docker container, switch to SAML authentication mode using the following command:
```bash
rails fablab:auth:switch_provider[NAME_OF_SAML]
```
Replace NAME_OF_SAML with the name you assigned to your SAML provider during the configuration.

3. Exit FabManager docker container and Restart the Application:
```bash
docker rm -f CONTAINER_NAME_APP
docker-compose up -d
```

4. Notify Current Users to login with SAML:
It's essential to inform current users about the authentication method change. Use the following command to notify them:
```bash
docker exec -it CONTAINER_NAME_APP bash
rails fablab:auth:notify_changed
```
To ensure a seamless transition for existing users to the new SAML authentication method, you can send them an email containing a link that will enable them to connect their existing FabManager accounts with their SAML identities.
This link include a token to authenticate the user and link their accounts. Upon successful connection, provide users with confirmation that their accounts have been linked to their SAML identities with authentification code.
By following these steps, existing users can seamlessly transition to SAML authentication without needing to re-enter their profile information.

## After user login via SAML
FabManager requires certain user attributes such as username, email, first name, last name, gender, and birthday to be mandatory.
Users provide all necessary information required by FabManager, even if certain attributes are not directly mapped through the SAML authentication process.
