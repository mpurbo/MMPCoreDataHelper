# MMPCoreDataHelper CHANGELOG

## 0.5.0

Initial public release.

## 0.5.1

* Critical bug fixed: updating in background thread did not work, all MOC access creates a new instance even within the same thread.
* Auto-cache removed (not really useful).
* Some documentation.

## 0.5.2

* Bug fix: model file is not loaded when the compiler produces a .mom file instead of .momd
