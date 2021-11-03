const WRAP_CLASS = "discourse-topic-query";

const VALID_ATTRIBUTES = [
  "tags",
  "status",
  "order",
  "topicIds",
  "exceptTopicIds",
  "ascending",
  "assigned",
  "category",
];

const blockRule = {
  tag: "topics",

  before(state, info) {
    let token = state.push("wrap_open", "div", 1);
    token.attrs = [["class", WRAP_CLASS]];

    VALID_ATTRIBUTES.forEach((attribute) => {
      if (info.attrs[attribute]) {
        token.attrs.push([
          `data-${attribute.toLowerCase()}`,
          info.attrs[attribute],
        ]);
      }
    });
  },

  after(state) {
    state.push("wrap_close", "div", -1);
  },
};

export function setup(helper) {
  helper.registerPlugin((md) => {
    md.block.bbcode.ruler.push("block-wrap", blockRule);
  });

  helper.allowList(
    [`div.${WRAP_CLASS}`].concat(
      VALID_ATTRIBUTES.map(
        (attribute) => `div[data-${attribute.toLowerCase()}]`
      )
    )
  );
}
