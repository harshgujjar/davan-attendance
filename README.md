# build-tools (not part of the apps)

`android.jar` = the Android API 34 compile library the widgets need (`$HOME/tc/android.jar`), kept here because
Google's download server (dl.google.com) is blocked in cloud sessions. Made on 07-Oct-2026 from Robolectric
android-all 14-robolectric-10818077 (Maven Central) + OpenJDK 8 rt.jar, with desktop Java, Android internals and
built-in pictures removed (77 MB). Checked: w182 student and w241 staff widget rebuilt with it are identical in
size, code and signing key to the released APKs.

Main branch: `bash tools/widget-toolchain.sh` installs the build tools and puts this file in place.
Kept on its own branch so the website (main) and normal clones stay small.
