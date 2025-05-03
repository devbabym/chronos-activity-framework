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

;; Priority classification storage - enables filtering
;; and organization based on relative importance
(define-map priority-classifications
    principal
    {
        priority-level: uint
    }
)

;; Temporal constraints storage - tracks deadlines and
;; notification states for time-sensitive activities
(define-map deadline-registry
    principal
    {
        deadline-block: uint,
        alert-triggered: bool
    }
)

;; ============================================================
;; VALIDATION AND VERIFICATION OPERATIONS
;; ============================================================

;; Public function for validating activity existence
;; Non-mutating operation to check record status
(define-public (validate-activity-record)
    (let
        (
            (caller tx-sender)
            (existing-record (map-get? activity-records caller))
        )
        (if (is-some existing-record)
            (let
                (
                    (current-record (unwrap! existing-record NOT-FOUND-ERROR))
                    (description-text (get activity-description current-record))
                    (status-flag (get completion-status current-record))
                )
                (ok {
                    exists: true,
                    description-length: (len description-text),
                    completed: status-flag
                })
            )
            (ok {
                exists: false,
                description-length: u0,
                completed: false
            })
        )
    )
)

;; ============================================================
;; EXTENDED ATTRIBUTES MANAGEMENT
;; ============================================================

;; Public function to establish activity priority level
;; Implements a three-tier classification system (1=low, 2=medium, 3=high)
(define-public (configure-activity-priority (priority-value uint))
    (let
        (
            (caller tx-sender)
            (existing-record (map-get? activity-records caller))
        )
        (if (is-some existing-record)
            (if (and (>= priority-value u1) (<= priority-value u3))
                (begin
                    (map-set priority-classifications caller
                        {
                            priority-level: priority-value
                        }
                    )
                    (ok "Activity priority classification successfully configured.")
                )
                (err INVALID-INPUT-ERROR)
            )
            (err NOT-FOUND-ERROR)
        )
    )
)

;; Public function to establish temporal constraints
;; Sets blockchain height target for activity completion
(define-public (configure-activity-deadline (block-duration uint))
    (let
        (
            (caller tx-sender)
            (existing-record (map-get? activity-records caller))
            (target-height (+ block-height block-duration))
        )
        (if (is-some existing-record)
            (if (> block-duration u0)
                (begin
                    (map-set deadline-registry caller
                        {
                            deadline-block: target-height,
                            alert-triggered: false
                        }
                    )
                    (ok "Activity deadline successfully configured.")
                )
                (err INVALID-INPUT-ERROR)
            )
            (err NOT-FOUND-ERROR)
        )
    )
)

;; ============================================================
;; READ-ONLY QUERY OPERATIONS
;; ============================================================

;; Query function to retrieve comprehensive activity details
;; Returns all stored information about the requested activity
(define-read-only (retrieve-activity-details (entity principal))
    (match (map-get? activity-records entity)
        record (ok {
            activity-description: (get activity-description record),
            completion-status: (get completion-status record)
        })
        NOT-FOUND-ERROR
    )
)

;; Specialized query for completion status assessment
;; Provides a focused view on just the completion state
(define-read-only (query-completion-status (entity principal))
    (match (map-get? activity-records entity)
        record (ok (get completion-status record))
        NOT-FOUND-ERROR
    )
)

;; ============================================================
;; ACTIVITY CREATION OPERATIONS
;; ============================================================

;; Public endpoint for users to register a new activity
;; Creates the initial record with completion status of false
(define-public (register-activity 
    (activity-description (string-ascii 100)))
    (let
        (
            (caller tx-sender)
            (existing-record (map-get? activity-records caller))
        )
        (if (is-none existing-record)
            (begin
                (if (is-eq activity-description "")
                    (err INVALID-INPUT-ERROR)
                    (begin
                        (map-set activity-records caller
                            {
                                activity-description: activity-description,
                                completion-status: false
                            }
                        )
                        (ok "Activity successfully registered in system.")
                    )
                )
            )
            (err DUPLICATE-ERROR)
        )
    )
)

;; Public function enabling delegation of activities
;; Allows privileged users to create activities for others
(define-public (assign-activity
    (recipient principal)
    (activity-description (string-ascii 100)))
    (let
        (
            (existing-record (map-get? activity-records recipient))
        )
        (if (is-none existing-record)
            (begin
                (if (is-eq activity-description "")
                    (err INVALID-INPUT-ERROR)
                    (begin
                        (map-set activity-records recipient
                            {
                                activity-description: activity-description,
                                completion-status: false
                            }
                        )
                        (ok "Activity successfully assigned to designated recipient.")
                    )
                )
            )
            (err DUPLICATE-ERROR)
        )
    )
)

;; ============================================================
;; ACTIVITY MANAGEMENT OPERATIONS
;; ============================================================

;; Public endpoint for updating existing activity details
;; Allows modification of both description and completion state
(define-public (modify-activity
    (activity-description (string-ascii 100))
    (completion-status bool))
    (let
        (
            (caller tx-sender)
            (existing-record (map-get? activity-records caller))
        )
        (if (is-some existing-record)
            (begin
                (if (is-eq activity-description "")
                    (err INVALID-INPUT-ERROR)
                    (begin
                        (if (or (is-eq completion-status true) (is-eq completion-status false))
                            (begin
                                (map-set activity-records caller
                                    {
                                        activity-description: activity-description,
                                        completion-status: completion-status
                                    }
                                )
                                (ok "Activity successfully modified in system.")
                            )
                            (err INVALID-INPUT-ERROR)
                        )
                    )
                )
            )
            (err NOT-FOUND-ERROR)
        )
    )
)

;; Public endpoint for removing an activity
;; Completely eliminates the activity from storage
(define-public (remove-activity)
    (let
        (
            (caller tx-sender)
            (existing-record (map-get? activity-records caller))
        )
        (if (is-some existing-record)
            (begin
                (map-delete activity-records caller)
                (ok "Activity successfully purged from system.")
            )
            (err NOT-FOUND-ERROR)
        )
    )
)


