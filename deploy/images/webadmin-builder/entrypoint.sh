#!/usr/bin/env sh

# Should be avoided because it overwrites package.json containing fixed versions
# npm init --yes
npm install -f --save-dev gulp gulp-clean gulp-size gulp-concat gulp-clean-css gulp-terser
mkdir -p dist/
gulp
