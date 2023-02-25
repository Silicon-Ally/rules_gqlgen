#!/bin/bash
set -euo pipefail

# This does not handle the case where $1 is a symlink itself.
unroll_path() {
  echo "$( cd -- "$(dirname -- "$1")" ; pwd -P )/$( basename -- "$1")"
}

# Give our input arguments more semantic names, see def.bzl for more info.
CONFIG="$1"
OUT_GEN_FILE="$(unroll_path "$2")"
OUT_MODELS_FILE="$(unroll_path "$3")"
GQL_ZIP="$(unroll_path "$4")"
CONFIG_DIR="$5"
GO_MOD="$6"
GO_SUM="$7"
MODCACHER_PATH="$8"

TMP_ROOT="$(mktemp -d)"
export GOROOT="$(unroll_path "$GOROOT")"
export GOPATH="$TMP_ROOT/gopath"
mkdir "$GOPATH"
unzip -qq -d "$GOPATH" "$GQL_ZIP"
export GOCACHE="$TMP_ROOT/go-build"
export GOCACHE="$TMP_ROOT/go-build"
# Use our version of the go toolchain, not any local system one.
export PATH="$GOROOT/bin:$PATH"

# TODO(brandon): Look into setting GOPROXY to file://$GQL_ROOT/pkg/mod, and
# packaging the $GQL_ROOT/src packages ourselves using
# https://pkg.go.dev/golang.org/x/mod/zip#CreateFromDir
# This will give us faster and hermetic builds because Go won't download the
# dependencies over the network.

# Bazel inputs aren't writable, but `go run` will attempt to edit them, so we
# copy them to the correct locations
cp "$GO_MOD" go.mod
cp "$GO_SUM" go.sum
chmod 777 go.mod go.sum

# Update the go.mod file to only include dependencies needed for gqlgen.
$MODCACHER_PATH go.mod "$GOPATH/src"

# Without this, the build will fail with the error:
#   ../external/go_sdk/src/crypto/internal/nistec/p256_asm.go:323:12: pattern
#   p256_asm_table.bin: cannot embed irregular file p256_asm_table.bin
#
# Embedding fails because it doesn't work on symlinks, so we copy the symlink
# into a hard file. The file is a symlink here because of how the go_path rule
# generates the directory in 'copy' mode.
ASM="external/go_sdk/src/crypto/internal/nistec/p256_asm_table.bin"
cp -L "$ASM" "${ASM}.tmp"
unlink "$ASM"
mv "${ASM}.tmp" "$ASM"

# See https://github.com/99designs/gqlgen/issues/2081#issuecomment-1126099404
cat >tools.go <<EOL
//go:build tools
// +build tools

package tools

import (
	_ "github.com/99designs/gqlgen"
	_ "github.com/99designs/gqlgen/graphql/introspection"
)
EOL

cp "$CONFIG" "$CONFIG_DIR"
cd "$CONFIG_DIR"

go mod tidy > /dev/null 2>&1
go mod vendor
go run -mod=readonly github.com/99designs/gqlgen generate \
  --config="$(basename $CONFIG)" \
  --verbose

# Copy the newly generated files to the correct output locations.
cp "generated/generated.go" "$OUT_GEN_FILE"
cp "model/models_gen.go" "$OUT_MODELS_FILE"
