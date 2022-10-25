((apply_expression
  (variable_expression (_) @_functionName)
  [(indented_string_expression (_) @lua)
   (parenthesized_expression ([
      (indented_string_expression (_) @lua)
      (_ (indented_string_expression (_) @lua) _)
      (_ _ (indented_string_expression (_) @lua))
      (_ (_ (indented_string_expression (_) @lua)) _)
      (_ (_ _ (indented_string_expression (_) @lua)))
    ]))
  ])
 (#eq? @_functionName "luaCfg"))

((apply_expression
  (apply_expression
    (variable_expression) @_functionName)
  (indented_string_expression
    (string_fragment) @bash))
 (#eq? @_functionName "writeShellScriptBin"))


((apply_expression
  (variable_expression) @_functionName
  (attrset_expression
    (binding_set (binding
                   (attrpath) @_attrName
                   (indented_string_expression
                     (string_fragment) @bash)))))
 (#eq? @_functionName "mkShell")
 (#eq? @_attrName "shellHook"))

(comment) @comment
