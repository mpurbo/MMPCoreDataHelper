# MMPCoreDataHelper CHANGELOG

## 0.7.5

* Add OSX support.

## 0.7.4

* bugfix: not trying to convert to NSDate when field value from CSV is empty.

## 0.7.3

* `map` for record transformation, `map:using:` for field transformation.

## 0.7.2

* `clear` for deleting all records of an entity.

## 0.7.1

* map (previously `convert`) & filter for CSV import

## 0.7.0

* Add import from CSV

## 0.6.2

* To simplify invocation, most utility functions are now static (breaks backward-compatibility).

## 0.6.1

* Add objectWithID: to MMPCoreDataHelper

## 0.6.0

* Simplified base query functions (breaks compatibility with previous versions).
* NSManagedObject category for Functional, Active Record and LINQ-inspired database access pattern.

## 0.5.2

* Bug fix: model file is not loaded when the compiler produces a .mom file instead of .momd

## 0.5.1

* Critical bug fixed: updating in background thread did not work, all MOC access creates a new instance even within the same thread.
* Auto-cache removed (not really useful).
* Some documentation.

## 0.5.0

Initial public release.
