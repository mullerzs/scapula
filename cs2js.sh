#! /bin/bash

rm -rvf js/*.js js/collections js/models js/nls js/views
[[ -n "$NT_UPDATE" ]] && exec coffee -o js/ -c src/
coffee -o js/ -cw src/
