# Tilde-is-not-a-fence fixture

Per the pinned predicate, only a line whose first non-whitespace run is >=3
backticks toggles fenced state. A `~~~` line does NOT open a fence, so the
marker pair inside the tilde block below is REAL, not inert. Expected real
tokens: 2. (This is exactly why authors must never wrap marker examples in
`~~~`.)

## Project addenda

~~~
<!-- BEGIN project-owned -->
this pair is inside ~~~ which is NOT a fence, so it counts as real
<!-- END project-owned -->
~~~
