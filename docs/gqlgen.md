<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="GQLInfo"></a>

## GQLInfo

<pre>
GQLInfo(<a href="#GQLInfo-models_gen">models_gen</a>, <a href="#GQLInfo-generated">generated</a>)
</pre>


Info needed to build Go libraries from auto-generated GQL code.

Provides the paths of the generated Go files for both the model (schema
definition) and generated (GraphQL 'glue' code) packages.


**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="GQLInfo-models_gen"></a>models_gen |  depset of generated Go files that the GraphQL domain types.    |
| <a id="GQLInfo-generated"></a>generated |  depset of generated Go files that provide GraphQL functionality.    |


<a id="gqlgen"></a>

## gqlgen

<pre>
gqlgen(<a href="#gqlgen-name">name</a>, <a href="#gqlgen-schemas">schemas</a>, <a href="#gqlgen-base_importpath">base_importpath</a>, <a href="#gqlgen-visibility">visibility</a>, <a href="#gqlgen-kwargs">kwargs</a>)
</pre>

Generates GraphQL Go bindings.

This rule runs [gqlgen](https://github.com/99designs/gqlgen) to produce
generated Go libraries based on a given GraphQL schema.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="gqlgen-name"></a>name |  A unique name for this rule.   |  none |
| <a id="gqlgen-schemas"></a>schemas |  A list of *.graphqls targets to generate code for.<br><br>Note that only a single schema.graphqls output has been tested, generated code for multiple schemas may not work.   |  none |
| <a id="gqlgen-base_importpath"></a>base_importpath |  The importpath of the directory the rule is defined in, like 'github.com/Org-Name/project_name/path/to/dir'   |  none |
| <a id="gqlgen-visibility"></a>visibility |  The visibility of the generated go_library targets.   |  none |
| <a id="gqlgen-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


