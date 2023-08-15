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



; TODO: also where pkgs is not in "with" in the outer scope
; (i.e. where it is `pkgs.mkShell`)
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


;; writeShellScriptBin - bash
(apply_expression
  function: ((apply_expression
               function: ((_) @_f1 (#contains? @_f1 "mapAttrs"))
               argument: ((_) @_f2 (#contains? @_f2 "writeShellScriptBin"))))
  argument: (_ (_
                 (binding
                   expression: ((_ (string_fragment) @bash))))))

((apply_expression
  (apply_expression
    (variable_expression) @_functionName)
  (indented_string_expression
    (string_fragment) @bash))
 (#eq? @_functionName "writeShellScriptBin"))
