#!/usr/bin/env just --justfile

test:
    fvm dart test

pubget:
    fvm dart run packo pubget -r

prepare:
    fvm dart format -l 80 .
    reuse annotate -c "Karim \"nogipx\" Mamatkazin <nogipx@gmail.com>" -l "LGPL-3.0-or-later" --skip-unrecognised -r lib
    fvm dart test --coverage=coverage
    fvm dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    genhtml coverage/lcov.info -o coverage/html
    open coverage/html/index.html

activate:
    fvm dart pub global activate --source path .
deactivate:
    fvm dart pub global deactivate licensify
reactivate:
    rm pubspec.lock
    fvm dart pub get
    fvm dart pub global deactivate licensify
    fvm dart pub global activate --source path .
    fvm dart pub global run licensify
