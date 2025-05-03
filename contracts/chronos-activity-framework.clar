;; Chronos Activity Framework 
;; A blockchain-based system for recording, tracking and managing temporal activities with priority classification and deadline monitoring.
;; Enables delegation of activities between blockchain identities.

;; ============================================================
;; RESPONSE CODE DEFINITIONS
;; ============================================================
;; These standardized response codes are returned for various
;; operational scenarios to provide deterministic feedback
(define-constant NOT-FOUND-ERROR (err u404))
(define-constant DUPLICATE-ERROR (err u409))
(define-constant INVALID-INPUT-ERROR (err u400))

;; ============================================================
;; DATA PERSISTENCE STRUCTURES
;; ============================================================

;; Core activity data storage - maintains the primary record
;; of activities and their completion status
(define-map activity-records
    principal
    {
        activity-description: (string-ascii 100),
        completion-status: bool
    }
)
