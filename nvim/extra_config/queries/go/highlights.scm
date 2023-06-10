;; extends

; ((if_statement !initializer
;     condition: (_) @__c (#contains? @__c " != nil")) @comment
;  (#set! "priority" 200))

; ((if_statement
;   initializer: (_)
;   condition: ((_) @_c (#contains? @_c "!= nil"))
;   consequence: ((_) @comment (#set! "priority" 300))))


; ((if_statement
;    (short_var_declaration) ; init
;    ((binary_expression) @_c (#contains? @_c "!= nil")) ; cond
;    ((block) @comment)) ; cons
;  (#set! "priority" 200)) 
