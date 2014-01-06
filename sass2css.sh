#! /bin/bash

rm -rvf css/*.css
[[ -n "$NT_UPDATE" ]] && exec compass compile --sass-dir sass --css-dir css
compass watch --sass-dir sass --css-dir css
