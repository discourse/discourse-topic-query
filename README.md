# Discourse-topic-query

Allows to display the results of a search query in a post.

## Usage

```
[query="foo tags:bar,baz"]
```

### Options

- hideTags: true/false (default: false). Hides tags.
- hideCategory: true/false (default: false). Hides category.
- excerptLength: an integer between 0 and 300. Limits the length of the post excerpt. Note that a value of 0 will hide it and force a list mode for the results.
