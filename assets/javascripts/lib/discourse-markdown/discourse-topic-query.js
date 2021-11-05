import { parseBBCodeTag } from "pretty-text/engines/discourse-markdown/bbcode-block";
const WRAP_CLASS = "discourse-topic-query";

function queryRule(buffer, matches, state) {
  let config = {
    query: null,
    hideTags: null,
    hideCategory: null,
    excerptLength: null,
  };

  const matchString = matches[1].replace(/‘|’|„|“|«|»|”/g, '"');

  let parsed = parseBBCodeTag(
    "[search-query query" + matchString + "]",
    0,
    matchString.length + 20
  );

  config.query = parsed.attrs.query;
  config.hideTags = parsed.attrs.hideTags;
  config.hideCategory = parsed.attrs.hideCategory;
  config.excerptLength = parsed.attrs.excerptLength;

  if (!config.query) {
    return;
  }

  let token = new state.Token("div_open", "div", 1);
  token.attrs = [["data-query", state.md.utils.escapeHtml(config.query)]];

  if (config.hideCategory) {
    token.attrs.push([
      "data-hide-category",
      state.md.utils.escapeHtml(config.hideCategory),
    ]);
  }

  if (config.hideTags) {
    token.attrs.push([
      "data-hide-tags",
      state.md.utils.escapeHtml(config.hideTags),
    ]);
  }

  if (config.excerptLength) {
    token.attrs.push([
      "data-excerpt-length",
      state.md.utils.escapeHtml(config.excerptLength),
    ]);
  }

  token.attrs.push(["class", WRAP_CLASS]);
  buffer.push(token);

  token = new state.Token("div_close", "div", -1);
  buffer.push(token);
}

export function setup(helper) {
  helper.registerOptions((opts, siteSettings) => {
    opts.features[
      "discourse-topic-query"
    ] = !!siteSettings.discourse_topic_query_enabled;
  });

  helper.registerPlugin((md) => {
    const rule = {
      matcher: /\[search-query(=.+?)\]/,
      onMatch: queryRule,
    };

    md.core.textPostProcess.ruler.push("discourse-topic-query", rule);
  });

  helper.allowList([
    `div.${WRAP_CLASS}`,
    "div[data-query]",
    "div[data-excerpt-length]",
    "div[data-hide-category]",
    "div[data-hide-tags]",
  ]);
}
