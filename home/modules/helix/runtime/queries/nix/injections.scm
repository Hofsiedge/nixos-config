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
