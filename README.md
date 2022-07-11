_This package was developed by [Silicon Ally](https://siliconally.org) while
working on a project for  [Adventure Scientists](https://adventurescientists.org).
Many thanks to Adventure Scientists for supporting [our open source
mission](https://siliconally.org/policies/open-source/)!_

NOTE: this package currently fetches dependencies over the internet, rather than
using the local ones already present in your Bazel WORKSPACE. This is suboptimal,
and may cause discrepancies if not carefully managed. We're hoping to fix it long
term.

# rules_gqlgen

`rules_gqlgen` provides **[bazel](https://bazel.build/) rules** that allow you to
build [GraphQL Servers](https://graphql.org/) in [Go](https://go.dev/).

Under the hood, it generates a Go runtime + model using the
[gqlgen](https://github.com/99designs/gqlgen) GraphQL server + codegen library.

## Usage

```bazel
# In a BUILD.bazel file

load("@com_siliconally_rules_gqlgen//gqlgen:def.bzl", "gqlgen")

# The rule below generates two library targets, :gql_generated and :gql_model,
# which correspond to the auto-generated GraphQL glue code and model schema
# types respectively.
# The two generated rules would have import paths of
#   - github.com/Silicon-Ally/testproject/graph/generated, and
#   - github.com/Silicon-Ally/testproject/graph/model
gqlgen(
    name = "gql",
    base_importpath = "github.com/Silicon-Ally/testproject/graph",
    schemas = ["//path/to:schema.graphqls"],
    visibility = ["//visibility:public"],
)
```

## Example

The `example` directory provides a basic GraphQL schema and server backed by
`gqlgen`, you can run it with:

```bash
bazel run //example
```

See the the example's README.md for a thorough explanation of what is happening. 