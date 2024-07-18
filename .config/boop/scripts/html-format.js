/**
  {
    "api":1,
    "name":"Format HTML",
    "description":"Ultra-basic HTML pretty",
    "author":"StackOverflow",
    "icon":"broom",
    "tags":"pretty,format,html"
  }
**/
function main(state) {
  state.text = dom_format(state.text);
}
function html_to_dom(html) {
  html = html.trim();
  if (!html) return null;
  //const template = document.createElement('template');
  const template = document;
  template.innerHTML = html;
  // const result = template.content.children;
  console.dir(template);
  const result = template.children[0];
  return result;
}

function dom_format(html) {
  var dom = html_to_dom(html);
  dom.children = recursive_format(dom.children);
  // return dom;
  return dom.documentElement.innerHTML; 
}

function recursive_format(dom, spacing = "") {
  for (let e of dom) {
    if (e.nodeName == "#text") {
    } else {
    e.children = recursive_format(e.children, spacing + "  ");
    const spacer = e.ownerDocument.createTextNode(spacing);
    e.parentNode.insertBefore(spacer, e);
    }
  }
  return dom;
}
