rm -rvf js/*.js js/specs
[[ -n "$NT_UPDATE" ]] && exec coffee -o js/ -c src/
coffee -o js/ -cw src/
