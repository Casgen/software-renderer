if [[ $1 == 'release' ]]; then
    echo "Building release..."
    odin build ./src/ -out:build/software-renderer -vet -strict-style -disallow-do -warnings-as-errors && \
    odin build ./src/tests/ -build-mode:test -out:build/software-renderer-tests -vet -strict-style -disallow-do -warnings-as-errors&& \
    echo "Done!"
else
    echo "Building debug..."
    odin build ./src/ -debug -out:build/software-renderer -vet -strict-style -disallow-do -warnings-as-errors && \
    odin build ./src/tests/ -debug -build-mode:test -out:build/software-renderer-tests -vet -strict-style -disallow-do -warnings-as-errors&& \
    echo "Done!"
fi
