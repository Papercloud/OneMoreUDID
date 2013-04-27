OneMoreUDID
===========

Conveniently add a UDID to the iOS Developer Portal, refresh a provisioning profile and download it.

Usage
-
`omudid [username] [password] [team name] [profile name] [device name] [UDID]`

Method
-
1. Logs in to the iOS Developer Portal with given username, password and team name
2. Adds device to the portal
3. Enables all devices (including the new one) in the given provisioning profile name
4. Downloads the new provisioning profile
5. Deletes locally installed provisioning files with given profile name
6. Installs new provisioning profile