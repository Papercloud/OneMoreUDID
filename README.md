OneMoreUDID
===========

Conveniently add a UDID to the iOS Developer Portal, refresh a provisioning profile and download it.

Uploading a new provisioning profile to TestFlight is also supported.

[![Build Status](https://travis-ci.org/Papercloud/OneMoreUDID.png)](https://travis-ci.org/Papercloud/OneMoreUDID)

Installation
-
```
$ gem install omudid
```

Usage
-
```
$ omudid add
$ omudid testflight upload
```

Example Output
-
```
$ omudid add
Apple Username:
appleuser@example.com
Apple Password:
************
Profile name (leave blank to select from available profiles):

Device name:
DeviceTen
UDID:
B123456789012345678901234567890123456789

Loading page... done
Loading page... done

Note: you can specify the team with a command-line argument

Please select one of the following teams:
1. Y2ZAFJ6Z9R: Team 1 - iOS Developer Program
2. LDF73KN5AM: Team 2 - iOS Developer Program
?  1

Loading page... done
Device DeviceTen (B123456789012345678901234567890123456789) added

Loading page... done
Loading page... done

Select a profile:
1. profile2
2. demo1
3. demo3
?  2

Note: you can repeat this process by running:
  omudid add appleuser@example.com [password] demo1 DeviceTen B123456789012345678901234567890123456789 Y2ZAFJ6Z9R

Loading page... done
Loading page... done
Loading page... done
Loading page... done
Loading page... done
Loading page... done
Loading page... done
Loading page... done
Loading page... done
Loading page... done
Downloaded new profile (./demo1.mobileprovision)
Old profile deleted (~/Library/MobileDevice/Provisioning Profiles/demo1.mobileprovision)
New profile installed (~/Library/MobileDevice/Provisioning Profiles/demo1.mobileprovision)

$ omudid testflight upload
TestFlight Username:
testflightuser@example.com
TestFlight Password:
********
Build ID (leave blank to select from available IDs):

Profile name (leave blank to select from available local profiles):

Enter an App ID to list builds (or leave blank to list App IDs):


Loading page... done
Loading page... done
Select an app ID:
1. 151463 (com.example.identifier)
?  1


Loading page... done
Select a build ID:
1. 1857636 (1.0 (1.0))
?  1

Select a profile:
1. profile2
2. demo1
3. demo3
?  2

Note: you can repeat this process by running:
  omudid testflight list-builds testflightuser@example.com [password] 1857636 demo1

Loading page... done
Submitted ~/Library/MobileDevice/Provisioning Profiles/demo1.mobileprovision
Share link: http://testflightapp.com/install/XYZ/
```
