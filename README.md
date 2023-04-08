## ChitChat

ChitChat is a simple chat application that utilizes the GPT-3.5/GPT-4 model to provide an interactive
chat experience.

ChitChat a feature-rich and user-friendly chat application built on Flutter, designed to elevate your chatting experience. Our app is packed with an array of handy features, ensuring seamless communication with state-of-the-art AI technologies. Explore the key highlights of ChatChit App below:

- :arrows_counterclockwise: **Multi-Engine Support**: Seamlessly switch between GPT-3.5 and GPT-4, tailoring your chat experience based on your preferences.
- :globe_with_meridians: **i18n Support**: Enjoy a truly international experience with our built-in support for multiple languages.
- :speech_balloon: **Text-to-Speech & Speech-to-Text**: Effortlessly communicate using voice inputs and outputs with our integrated TTS and STT technologies.
- :page_with_curl: **Markdown Support**: Enhance your chat messages with clean and elegant formatting using the power of Markdown.
- :clipboard: **Multiline Input**: Copy and paste multiline content with ease, simplifying your communications.
- :black_nib: **Chat Channels & Prompts**: Engage in simultaneous conversations by participating in multiple channels and utilizing customized prompts.
- :unlock: **Proxy & BaseURL Settings**: Easily configure proxy settings and baseURL settings to suit your unique requirements.
- :zap: **Stream API Calls**: Benefit from real-time interactions with our support for `stream=true` API calls.
- :wastebasket: **Message Management**: Delete messages effortlessly, keeping your chats tidy and organized.
- :repeat: **Retry Logic**: Stay connected with our intelligent retry system, which ensures your messages are delivered even during connectivity hiccups.
- :bookmark_tabs: **Chat History & Continuous Mode**: Retrieve previous chats and engage in fluid, natural conversations with our conversation persistence and continuous mode feature.
- :incoming_envelope: **Copy, Share & Translate**: Boost your productivity with built-in actions for copying, sharing, translating, and rephrasing messages.

Upgrade your chat experience today with **ChitChat App** — where AI-powered communication meets elegance, functionality, and accessibility.

It is built with Flutter and supports platforms
- Android
- iOS
- Web
- Mac OS X
- Linux
- Windows

### Downloads
For Mac/Android, You can download in from the release builds
- https://github.com/pjq/ChitChat/releases/

For Android, you can also download from Google Play
- Android https://play.google.com/store/apps/details?id=me.pjq.chitchat













### Getting Started

To get started with ChitChat, clone this repository to your local machine and open it in your
preferred IDE. Then, run the following command in the terminal to download the required
dependencies:

```bash
flutter pub get
```

To run the application, connect your device or emulator and run the following command:

```bash
flutter run
```

To run on iPhone, need add `--release`
```shell
 flutter run --release
```

### Usage

When you launch the application, you will be taken to the chat screen where you can enter text to
send to the GPT-3.5 Turbo model. The model will then generate a response that will be displayed in
the chat window.

You can also access the settings screen by tapping on the settings icon in the app bar. Here, you
can set the OpenAI API key, prompt string, and temperature value.

To copy or share a chat message, simply long-press on the message and select the appropriate action
from the context menu.

To translate a chat message, long-press on the message and select the "Translate" option. This will
open the Google Translate app, where you can choose the language to translate to.

### Contributing

Contributions are welcome and appreciated. To contribute to ChatGPT, follow these steps:

1. Fork this repository.
2. Create a new branch for your changes.
3. Make your changes and commit them, with clear commit messages.
4. Push your changes to your fork.
5. Open a pull request.

### License

ChatGPT is licensed under the MIT license. See LICENSE for more information.

### Release command

```shell
git tag 1.0.0-mac && git push origin 1.0.0-mac
git tag 1.0.0-android && git push origin 1.0.0-android
```

Or delete tag and push again
```shell
git tag -d 1.1.1-mac &&  git push origin --delete 1.1.1-mac &&  git tag 1.1.1-mac && git push origin 1.1.1-mac
echo " git tag -d 1.1.1-mac &&  git push origin --delete 1.1.1-mac &&  git tag 1.1.1-mac && git push origin 1.1.1-mac" | sed "s/mac/android/g" | sed "s/1.1.1/1.1.2/g"
```

Or with one command line
```shell
CURRENT_VERSION=1.0.0 && PLATFORM=mac && git tag $CURRENT_VERSION-$PLATFORM && git push origin $CURRENT_VERSION-$PLATFORM && PLATFORM=android && git tag $CURRENT_VERSION-$PLATFORM && git push origin $CURRENT_VERSION-$PLATFORM
```

### Generate l10n by Call GPT 3.5 Turbo API

```shell
cd lib/l10n
python3 ../../tools/l10n.py --file app_en.arb;
```


### Screenshots

![Screenshot of Chat Screen](screenshots/chat.png)
![Screenshot of Settings Screen](screenshots/settings.png)
![Screenshot of Actions Menu](screenshots/actions.png)

## Getting Started for Flutter
This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
