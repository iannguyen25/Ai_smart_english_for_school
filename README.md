
How to run project in Visual studio code?

0. Install environment flutter https://flutter.dev/docs/get-started/install
1. Install extension flutter and dart in Extensions
2. Install fvm dart pub global activate fvm
3. Run: export PATH="$HOME/.pub-cache/bin:$PATH" and restart your VSC
4. To use flutter 3.16.2 => Run terminal: fvm install 3.16.2 and fvm use 3.16.2
5. Run: fvm flutter clean
6. Delete pubspec.lock by yourself or run: rm pubspec.lock
7. Then run: fvm flutter pub get
8. Plug your devive in your laptop and run project
