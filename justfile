#!/usr/bin/env just --justfile

pubget:
    fvm dart run packo pubget -r

runner:
    fvm dart run packo runner -r

license:
    reuse annotate -c "Karim \"nogipx\" Mamatkazin <nogipx@gmail.com>" -l "LGPL-3.0-or-later" --skip-unrecognised -r lib
