load("@io_bazel_rules_go//go:def.bzl", "go_context", "go_library")

# See https://gqlgen.com/config/ for more info on this format.
_GQLGEN_YML_TEMPLATE = """
schema:
{schemas}

exec:
  filename: generated/generated.go
  package: generated

model:
  filename: model/models_gen.go
  package: model

resolver:
  layout: follow-schema
  dir: graph
  package: graph

models:
  ID:
    model:
      - github.com/99designs/gqlgen/graphql.ID
      - github.com/99designs/gqlgen/graphql.Int
      - github.com/99designs/gqlgen/graphql.Int64
      - github.com/99designs/gqlgen/graphql.Int32
  Int:
    model:
      - github.com/99designs/gqlgen/graphql.Int
      - github.com/99designs/gqlgen/graphql.Int64
      - github.com/99designs/gqlgen/graphql.Int32
"""

GQLInfo = provider(
    doc = """
Info needed to build Go libraries from auto-generated GQL code.

Provides the paths of the generated Go files for both the model (schema
definition) and generated (GraphQL 'glue' code) packages.
""",
    fields = {
        "models_gen": "depset of generated Go files that the GraphQL domain types.",
        "generated": "depset of generated Go files that provide GraphQL functionality.",
    },
)

def gqlgen(name, schemas, base_importpath, visibility, **kwargs):
    """Generates GraphQL Go bindings.

    This rule runs [gqlgen](https://github.com/99designs/gqlgen) to produce
    generated Go libraries based on a given GraphQL schema.

    Args:
      name: A unique name for this rule.
      schemas: A list of *.graphqls targets to generate code for.

        Note that only a single schema.graphqls output has been tested, generated
        code for multiple schemas may not work.
      base_importpath: The importpath of the directory the rule is defined in,
        like 'github.com/Org-Name/project_name/path/to/dir'
      visibility: The visibility of the generated go_library targets.
    """
    gqlgen_args = {
        "name": name,
        "schemas": schemas,
        "base_importpath": base_importpath,
    }
    gqlgen_args.update(kwargs)
    _gqlgen(**gqlgen_args)

    _filter_outs(
        name = name + "_model_src",
        srcs = ":" + name,
        filter_mode = "model",
    )

    _filter_outs(
        name = name + "_gen_src",
        srcs = ":" + name,
        filter_mode = "generated",
    )

    model_label = name + "_model"
    go_library(
        name = model_label,
        srcs = [":" + name + "_model_src"],
        importpath = base_importpath + "/model",
        visibility = visibility,
    )

    go_library(
        name = name + "_generated",
        srcs = [":" + name + "_gen_src"],
        importpath = base_importpath + "/generated",
        deps = [
            ":" + model_label,
            "@com_github_99designs_gqlgen//graphql",
            "@com_github_99designs_gqlgen//graphql/introspection",
            "@com_github_vektah_gqlparser_v2//:gqlparser",
            "@com_github_vektah_gqlparser_v2//ast",
        ],
        visibility = visibility,
    )

def _gqlgen_impl(ctx):
    go = go_context(ctx)

    config_file = ctx.actions.declare_file(ctx.label.name + ".gqlgen.yml")

    # We create these
    gomod_file = ctx.actions.declare_file("go.mod.tmp")
    gosum_file = ctx.actions.declare_file("go.sum.tmp")

    # Build up the list of GraphQL schema files to insert into the YAML
    # template.
    schemas = []
    path_prefix = ctx.label.package + "/"
    for f in ctx.files.schemas:
        if not f.path.startswith(path_prefix):
            fail(".graphqls files must be in a child directory of this one")
        schema_path = f.path[len(path_prefix):]
        schemas.append("  - " + schema_path)

    ctx.actions.write(
        content = _GQLGEN_YML_TEMPLATE.format(
            schemas = "\n".join(schemas),
        ),
        output = config_file,
    )

    ctx.actions.run_shell(
        inputs = [ctx.file.gomod],
        outputs = [gomod_file],
        progress_message = "Copying go.mod from %s to %s" % (ctx.file.gomod.short_path, gomod_file.short_path),
        command = "cp %s %s" % (ctx.file.gomod.path, gomod_file.path),
    )

    ctx.actions.run_shell(
        inputs = [ctx.file.gosum],
        outputs = [gosum_file],
        progress_message = "Copying go.sum from %s to %s" % (ctx.file.gosum.short_path, gosum_file.short_path),
        command = "cp %s %s" % (ctx.file.gosum.path, gosum_file.path),
    )

    out_generated_file = ctx.actions.declare_file("graph/generated/generated.go")
    out_models_file = ctx.actions.declare_file("graph/model/models_gen.go")

    ctx.actions.run(
        inputs = ctx.files.schemas + [
            config_file,
            gomod_file,
            gosum_file,
            ctx.file._gqlgen,
        ] + go.sdk.srcs + go.sdk.tools + go.sdk.headers,
        outputs = [
            out_generated_file,
            out_models_file,
        ],
        arguments = [
            config_file.path,
            out_generated_file.path,
            out_models_file.path,
            ctx.file._gqlgen.path,
            ctx.label.package,
            gomod_file.path,
            gosum_file.path,
            ctx.executable._modcacher.path,
        ],
        progress_message = "Generating GraphQL models and runtime",
        tools = [
            go.go,
            ctx.executable._modcacher,
        ],
        env = go.env,
        executable = ctx.executable._generator_script,
    )

    return [
        GQLInfo(
            models_gen = depset([out_models_file]),
            generated = depset([out_generated_file]),
        ),
        DefaultInfo(files = depset([
            out_generated_file,
            out_models_file,
        ])),
    ]

_gqlgen = rule(
    implementation = _gqlgen_impl,
    doc = """
Example rule documentation.

Example:
  Here is an example of how to use this rule.
""",
    attrs = {
        "gomod": attr.label(
            default = Label("//:go.mod"),
            doc = "The go.mod file at the root of the repo",
            allow_single_file = [".mod"],
        ),
        "gosum": attr.label(
            default = Label("//:go.sum"),
            doc = "The go.sum file at the root of the repo",
            allow_single_file = [".sum"],
        ),
        "schemas": attr.label_list(
            allow_empty = False,
            allow_files = [".graphqls"],
            doc = "The schema file location",
        ),
        "base_importpath": attr.string(
            doc = "The import path that generated subpackages should be rooted at.",
        ),
        "_generator_script": attr.label(
            executable = True,
            cfg = "exec",
            allow_files = True,
            default = Label("//gqlgen:generate"),
        ),
        "_modcacher": attr.label(
            executable = True,
            cfg = "exec",
            allow_files = True,
            default = Label("//gqlgen/modcacher:modcacher"),
        ),
        "_go_context_data": attr.label(
            default = "@io_bazel_rules_go//:go_context_data",
        ),
        "_gqlgen": attr.label(
            allow_single_file = True,
            default = "//gqlgen:gqlgen_path",
            cfg = "host",
        ),
    },
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
    provides = [GQLInfo],
)

def _filter_outs_impl(ctx):
    gqlinfo = ctx.attr.srcs[GQLInfo]

    if ctx.attr.filter_mode == "model":
        out = gqlinfo.models_gen
    elif ctx.attr.filter_mode == "generated":
        out = gqlinfo.generated

    return DefaultInfo(files = out)

_filter_outs = rule(
    implementation = _filter_outs_impl,
    attrs = {
        "srcs": attr.label(mandatory = True, providers = [GQLInfo]),
        "filter_mode": attr.string(mandatory = True, values = ["model", "generated"]),
    },
)
