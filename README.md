# AstaViewer QuickLook plugin

This QuickLook plugin lets you preview the UML diagrams created with the [astah* community](http://astah.net/editions/community) tool.

## Installation

The plugin is actually a thin wrapper around the astah* java package that does the heavy lifting. To build the plugin, you'll need to fetch that dependency first:

```
$ scripts/setup.sh
```

Now you can open the project in Xcode and build it. Once the build succeeds, the plugin is automatically copied to `~/Library/QuickLook/AstaViewer.qlgenerator`. To uninstall it, just delete that bundle.

## Known issues

The plugin is still in the early stages of development and has probably more limitations than features, including:

- no thumbnail generation
- can show only one diagram randomly
- even so, it renders all diagrams which makes it quite slow
