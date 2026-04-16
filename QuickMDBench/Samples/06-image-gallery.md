# Image gallery

Four solid-color test images plus one with an ampersand in its filename
(regression test for the HTML-entity decode fix in the image resolver).

## Inline

Red swatch: ![red swatch](images/red.png)

Blue swatch with a title: ![blue swatch](images/blue.png "A blue block")

## Block-style

![A green rectangle](images/green.png)

![A yellow square](images/yellow.png)

## Ampersand in path

![ampersand path](images/a&b.png)

## Missing image (should still render cleanly)

![not here](images/does-not-exist.png)

## Decorative image (empty alt)

![](images/red.png)

## Remote URL (should not be fetched)

![remote placeholder](https://example.invalid/image.png)
