;; extends

(((if_statement !initializer
    condition: ((_) @__c (#contains? @__c " != nil"))) @comment)
 (#set! "priority" 110))


; (((if_statement !initializer
;     ((binary_expression) @__c (#contains? @__c " != nil"))) @comment)
;  (#set! "priority" 110))
