<p align="center">
  <a href="https://github.com/ahmtydn/isar">
    <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/isar.svg?sanitize=true" height="128">
  </a>
  <h1 align="center">Isar Plus Database</h1>
</p>

<p align="center">
  <a href="https://pub.dev/packages/isar_plus"><img src="https://img.shields.io/pub/v/isar_plus?label=pub.dev&labelColor=333940&logo=dart"></a>
  <a href="https://pub.dev/packages/isar_plus/score"><img src="https://img.shields.io/pub/points/isar_plus?label=score&labelColor=333940&logo=dart"></a>
  <a href="https://github.com/ahmtydn/isar_plus"><img src="https://img.shields.io/github/stars/ahmtydn/isar_plus?style=social"></a>
</p>

<p align="center">
  <a href="https://buymeacoffee.com/ahmtydn">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee">
  </a>
</p>

---

## Production-Ready for Flutter Apps

Isar Plus v4 is now stable and ready for production use! Deploy with confidence on iOS, Android, macOS, Windows, and Linux. Web support is functional for basic use cases and actively improving.

- **Native Platforms:** Fully production-ready with comprehensive testing  
- **Core Features:** CRUD, queries, indexes, transactions, encryption, watchers  
- **Web Platform:** Functional for basic operations, OPFS optimization ongoing  
---

## About Isar Plus

Isar Plus is an enhanced fork of the original [Isar database](https://github.com/isar/isar) created by Simon Choi. This project builds upon the solid foundation of the original Isar, adding new features, improvements, and ongoing maintenance.

### What's Different?

- ✨ **Enhanced Features**: Additional capabilities beyond the original Isar
- 🌐 **Improved Web Support**: Better SQLite/WASM integration for Flutter Web
- 🔧 **Active Maintenance**: Regular updates and bug fixes
- 🌍 **Multilingual Documentation**: Including Turkish language support
- 🚀 **Performance Optimizations**: Continuous improvements to speed and efficiency

## Features

- 💙 **Made for Flutter**. Easy to use, no config, no boilerplate
- 🚀 **Highly scalable** The sky is the limit (pun intended)
- 🍭 **Feature rich**. Composite & multi-entry indexes, query modifiers, JSON support etc.
- ⏱ **Asynchronous**. Parallel query operations & multi-isolate support by default
- 🦄 **Open source**. Everything is open source and free forever!
- ✨ **Enhanced**. Additional features and improvements over the original Isar
- 🌐 **Persistent web storage**. Automatic OPFS + IndexedDB fallback for Flutter Web.

## Documentation

📚 **Comprehensive documentation is available at [isarplus.ahmetaydin.dev](https://isarplus.ahmetaydin.dev)**

<p align="center">
  <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/isar_docs.png?sanitize=true" alt="Isar Plus Documentation">
</p>

Join the [Telegram group](https://t.me/isarplus) for discussion and sneak peeks of new versions of the DB.

If you want to say thank you, star us on GitHub and like us on pub.dev 🙌💙

## Isar Database Inspector

The Isar Inspector allows you to inspect the Isar instances & collections of your app in real-time. You can execute queries, edit properties, switch between instances and sort the data.

<img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/inspector.gif">

To launch the inspector, just run your Isar app in debug mode and open the Inspector link in the logs.


## Benchmarks

Benchmarks only give a rough idea of the performance of a database but as you can see, Isar NoSQL database is quite fast 😇

| <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/insert.png" width="100%" /> | <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/query.png" width="100%" /> |
| ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/update.png" width="100%" /> | <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/size.png" width="100%" />  |

If you are interested in more benchmarks or want to check how Isar performs on your device you can run the [benchmarks](https://github.com/isar/isar_benchmark) yourself.

## Unit tests

If you want to use Isar database in unit tests or Dart code, call `await Isar.initializeIsarCore(download: true)` before using Isar in your tests.

Isar NoSQL database will automatically download the correct binary for your platform. You can also pass a `libraries` map to adjust the download location for each platform.

Make sure to use `flutter test -j 1` to avoid tests running in parallel. This would break the automatic download.

## Contributors ✨

### Isar Plus Contributors

Thanks to everyone contributing to Isar Plus:

- [Ahmet Aydın](https://github.com/ahmtydn) - Project maintainer and lead developer


<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

For a complete list of original Isar contributors, please visit the [original repository](https://github.com/isar/isar/graphs/contributors).
