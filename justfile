#!/usr/bin/env just --justfile

test:
    fvm dart test

pubget:
    fvm dart pub get

prepare:
    fvm dart format -l 80 .
    reuse annotate -c "Karim \"nogipx\" Mamatkazin <nogipx@gmail.com>" -l "LGPL-3.0-or-later" --skip-unrecognised -r lib
    fvm dart test --coverage=coverage
    fvm dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    genhtml coverage/lcov.info -o coverage/html
    open coverage/html/index.html

compile:
    rm pubspec.lock
    fvm dart pub get
    fvm dart compile exe bin/licensify.dart -o bin/licensify
    chmod +x bin/licensify

dry:
    fvm dart pub publish --dry-run

publish:
    fvm dart pub publish

test_cli:
    sh test_cli/test_all_commands.sh
