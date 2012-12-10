#! /bin/bash

rm -rvf js/*.js js/collections js/models js/nls js/views
coffee -o js/ -cw src/
