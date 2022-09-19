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

(comment) @comment
