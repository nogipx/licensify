#!/usr/bin/env just --justfile

test:
    fvm dart test

coverage:
    fvm dart test --coverage=coverage
    fvm dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    genhtml coverage/lcov.info -o coverage/html
    open coverage/html/index.html

pubget:
    fvm dart run packo pubget -r

license:
    reuse annotate -c "Karim \"nogipx\" Mamatkazin <nogipx@gmail.com>" -l "LGPL-3.0-or-later" --skip-unrecognised -r lib

format:
    fvm dart format -l 80 .
