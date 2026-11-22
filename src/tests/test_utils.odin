package tests

import "core:os"
import "core:io"

open_file_and_create_reader :: proc(path: string) -> (io.Reader, os.Error) {
    file, err := os.open(path)

    if err != nil {
        return io.Reader{}, err
    }

    return os.to_reader(file), err
}
