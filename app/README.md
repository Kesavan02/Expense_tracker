# expense_tracker

## How to create a module?

1. Create directory
   ---> mkdir core

2. --> cd core

3. --> flutter create --template=package enter_module_name_here
4. --> flutter create --template=package data

================================================================================

1. --> flutter create --template=package core/data

## melos

1. dart pub add melos
2. dart pub global activate melos
3. melos check with "melos" command
4. dart pub outdated
5. # dart pub upgrade --major-versions

To generate injection.config.dart file:

1. dart run build_runner watch --delete-conflicting-outputs
2. build apk (optional if the file is not auto-generated after running the above command)
