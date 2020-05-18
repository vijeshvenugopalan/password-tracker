<img src="icons/icon.png" width="80" alt="">

# Password Tracker 

## Getting Started

This project is a flutter application. Should follow the flutter instructions to run it on Android or iOS. https://flutter.dev/docs/get-started/install

Fingerprint authentication is implemented in Android native layer. No implementation of the same in iOS.

Application stores all password offline in a local database. Encrypted passwords can be exported using application functionality.

Functionalities provided by application:
- Fingerprint authentication for login.
- Can copy passwords by click of a button, with out even viewing it.
- Search for non encrypted items (username, url, folder name, item name)
- Organise credentials with move and rename.
- Import encrypted file across devices.
- Export encypted file and can be stored in your prefered storage like (Eg: Dropbox, google drive etc)
- Import all passwords from chrome csv. That will get encrypted and stored in the application.
- Have three secret storing fields under an item (password, secret and comments)

## Security
Passwords are stored after hashing.
For fingerprint authentication followed the guideines mentioned in https://labs.f-secure.com/blog/how-secure-is-your-android-keystore-authentication/

## Testing
Only tested in Android platform.
Application is available at link : https://play.google.com/store/apps/details?id=com.vijesh.password_tracker
