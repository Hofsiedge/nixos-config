;; extends

((if_statement !initializer
    condition: (_) @local.__c (#contains? @local.__c " != nil")) @comment.boring
 (#set! "priority" 300))

; TODO: if_statement with an initializer using lua
