_This package brought to you by [Adventure
Scientists](https://adventurescientists.org). Read more about [our open source
policy here](https://siliconally.org/policies/open-source/)._

| :warning: WARNING                                 |
|:--------------------------------------------------|
| `rules_gqlgen` is experimental, use with caution. |

# rules_gqlgen

`rules_gqlgen` provides Bazel rules for working with the
[gqlgen](https://github.com/99designs/gqlgen) GraphQL server + codegen library.

## Usage

```bazel
# In a BUILD.bazel

load("@com_siliconally_rules_gqlgen//gqlgen:def.bzl", "gqlgen")

# The below rule generated two library targets, :gql_generated and :gql_model,
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

The server will run on port 8080, you can access the playground at
`http://localhost:8080/api/playground`, and try requests like:

```graphql
# Query greetings
{
  greetings {
    message
    lang
  }
}

# Set a name
mutation {
  updateName(req:{name:"Moxie"})
}
```
