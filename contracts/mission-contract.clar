;; Mission Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_STATUS (err u400))

;; Define mission statuses
(define-constant MISSION_STATUS_PLANNED u1)
(define-constant MISSION_STATUS_IN_PROGRESS u2)
(define-constant MISSION_STATUS_COMPLETED u3)
(define-constant MISSION_STATUS_ABORTED u4)

;; Data Maps
(define-map missions
  { mission-id: uint }
  {
    name: (string-ascii 100),
    objective: (string-utf8 500),
    start-date: uint,
    end-date: uint,
    status: uint,
    lead-scientist: principal
  }
)

(define-data-var mission-nonce uint u0)

;; Functions
(define-public (create-mission (name (string-ascii 100)) (objective (string-utf8 500)) (start-date uint) (end-date uint) (lead-scientist principal))
  (let
    ((new-mission-id (+ (var-get mission-nonce) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set missions
      { mission-id: new-mission-id }
      {
        name: name,
        objective: objective,
        start-date: start-date,
        end-date: end-date,
        status: MISSION_STATUS_PLANNED,
        lead-scientist: lead-scientist
      }
    )
    (var-set mission-nonce new-mission-id)
    (ok new-mission-id)
  )
)

(define-public (update-mission-status (mission-id uint) (new-status uint))
  (let
    ((mission (unwrap! (map-get? missions { mission-id: mission-id }) ERR_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get lead-scientist mission))) ERR_NOT_AUTHORIZED)
    (asserts! (or (is-eq new-status MISSION_STATUS_IN_PROGRESS)
                  (is-eq new-status MISSION_STATUS_COMPLETED)
                  (is-eq new-status MISSION_STATUS_ABORTED))
              ERR_INVALID_STATUS)
    (ok (map-set missions
      { mission-id: mission-id }
      (merge mission { status: new-status })
    ))
  )
)

(define-read-only (get-mission (mission-id uint))
  (map-get? missions { mission-id: mission-id })
)

(define-read-only (get-mission-status (mission-id uint))
  (match (map-get? missions { mission-id: mission-id })
    mission (ok (get status mission))
    ERR_NOT_FOUND
  )
)

