;; shellHook - bash
(binding
  attrpath: (_) @_attr_name
  expression: (_ 
    (string_fragment) @injection.content)
  (#eq? @_attr_name "shellHook")
  (#set! injection.language "bash"))

;; pkgs.writeShellScriptBin - bash
(apply_expression
  function: (apply_expression
    function: [
      (select_expression
        attrpath: (attrpath
          attr: (_) @_function_name))
      (variable_expression
        name: (_) @_function_name)
    ])
  argument: (indented_string_expression
    (string_fragment) @injection.content)
  (#eq? @_function_name "writeShellScriptBin")
  (#set! injection.language "bash"))


; ((apply_expression
;   (apply_expression
;     (variable_expression) @_functionName)
;   (indented_string_expression
;     (string_fragment) @injection.content))
;  (#eq? @_functionName "writeShellScriptBin")
;  (#set! injection.language "bash"))

;; writeShellScriptBin - bash
;; FIXME
; (apply_expression
;   function: ((apply_expression
;                function: ((_) @_f1 (#contains? @_f1 "mapAttrs"))
;                argument: ((_) @_f2 (#contains? @_f2 "writeShellScriptBin"))))
;   argument: (_ (_
;                  (binding
;                    expression: ((_ (string_fragment) @injection.content)))))
;   (#set! injection.language "bash"))

; ((apply_expression
;   (apply_expression
;     (variable_expression) @_functionName)
;   (indented_string_expression
;     (string_fragment) @injection.content))
;  (#eq? @_functionName "writeShellScriptBin")
;  (#set! injection.language "bash"))
