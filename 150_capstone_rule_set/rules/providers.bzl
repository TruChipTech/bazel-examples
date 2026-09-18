"""Providers for the `recipe` mini rule set."""

RecipeInfo = provider(
    doc = "A recipe library and its transitive closure.",
    fields = {
        "transitive_sources": "depset of File - all .recipe sources",
        "transitive_names": "depset of string - all library names",
        "compiled": "File - this target's compiled output",
    },
)

RecipeLintInfo = provider(
    doc = "Lint reports produced by the recipe lint aspect.",
    fields = {"reports": "depset of File"},
)
