((comment) @injection.content
 (#set! injection.language "comment"))

((script_element
  (raw_text) @injection.content)
 (#set! injection.language "javascript"))

((style_element
  (raw_text) @injection.content)
 (#set! injection.language "css"))

;; Alpine.js attributes
(attribute
  (attribute_name) @_name
  (quoted_attribute_value
    ((attribute_value) @injection.content))
  (#match? @_name "^:[a-zA-Z]$|^(@|x-)[a-zA-Z\.:]+$") ; TODO: fix :attr="" pattern
  (#set! injection.language "javascript"))

