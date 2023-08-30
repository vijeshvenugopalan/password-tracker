## Password Tracker: Privacy policy

Welcome to the Password Tracker app for Android!

This is an open source Android app developed by Vijesh Venugopalan. The source code is available on GitHub under the MIT license; the app is also available on Google Play.

As an avid Android user myself, I take privacy very seriously.
I know how irritating it is when apps collect your data without your knowledge.

I hereby state, to the best of my knowledge and belief, that I have not programmed this app to collect any personally identifiable information. All data (app preferences (like theme, etc.) and alarms) created by the you (the user) is stored on your device only, and can be simply erased by clearing the app's data or uninstalling it.

### Explanation of permissions requested in the app

The list of permissions required by the app can be found in the `AndroidManifest.xml` file:

https://github.com/vijeshvenugopalan/password-tracker/blob/master/android/app/src/main/AndroidManifest.xml

<br/>

| Permission | Why it is required |
| :---: | --- |
| `android.permission.USE_BIOMETRIC` | This permission is required to enable biometric login. |
| `android.permission.USE_FINGERPRINT` | This permission is required to enable fingerprint for login. |

 <hr style="border:1px solid gray">

If you find any security vulnerability that has been inadvertently caused by me, or have any question regarding how the app protectes your privacy, please send me an email or post a discussion on GitHub, and I will surely try to fix it/help you.

Yours sincerely,  
Vijesh Venugopalan
vijesh568@gmail.com