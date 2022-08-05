# Cutting a new release

1. Submit all the code you want to be in the release.
2. Create a new tag for the release with `git tag vX.Y.Z`
  - You can get the current latest tag with `git describe --tags --abbrev=0`
3. Push the tag with `git push origin vX.Y.Z`
4. Create an archive with `git archive --output=rules_gqlgen-vX.Y.Z.zip vX.Y.Z`
5. Create the release with `gh release create vX.Y.Z rules_gqlgen-vX.Y.Z.zip --generate-notes`
6. Get a SHA256 digest of the archive with `sha256sum rules_gqlgen-vX.Y.Z.zip`
7. Update the description of the release, prepending the usage instructions.
  - They should look something like:
  ```markdown
  # `WORKSPACE` code

  ```` ``` ```` bazel
  load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

  http_archive(
      name = "com_siliconally_rules_gqlgen",
      sha256 = "<sha256sum output>",
      urls = [
          "https://github.com/Silicon-Ally/rules_gqlgen/releases/download/vX.Y.Z/rules_gqlgen-vX.Y.Z.zip",
      ],
  )
  ```` ``` ````
  ```

You're done! Congrats on the successful release.
