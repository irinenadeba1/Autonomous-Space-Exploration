;; Resource Allocation Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_RESOURCES (err u400))

;; Data Maps
(define-map resources
  { resource-id: uint }
  {
    name: (string-ascii 100),
    total-quantity: uint,
    available-quantity: uint
  }
)

(define-map resource-allocations
  { allocation-id: uint }
  {
    resource-id: uint,
    allocated-to: principal,
    allocated-quantity: uint
  }
)

(define-data-var resource-nonce uint u0)
(define-data-var allocation-nonce uint u0)

;; Functions
(define-public (add-resource (name (string-ascii 100)) (quantity uint))
  (let
    ((new-resource-id (+ (var-get resource-nonce) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set resources
      { resource-id: new-resource-id }
      {
        name: name,
        total-quantity: quantity,
        available-quantity: quantity
      }
    )
    (var-set resource-nonce new-resource-id)
    (ok new-resource-id)
  )
)

(define-public (allocate-resource (resource-id uint) (quantity uint))
  (let
    ((resource (unwrap! (map-get? resources { resource-id: resource-id }) ERR_NOT_FOUND))
     (new-allocation-id (+ (var-get allocation-nonce) u1)))
    (asserts! (>= (get available-quantity resource) quantity) ERR_INSUFFICIENT_RESOURCES)
    (map-set resources
      { resource-id: resource-id }
      (merge resource { available-quantity: (- (get available-quantity resource) quantity) })
    )
    (map-set resource-allocations
      { allocation-id: new-allocation-id }
      {
        resource-id: resource-id,
        allocated-to: tx-sender,
        allocated-quantity: quantity
      }
    )
    (var-set allocation-nonce new-allocation-id)
    (ok new-allocation-id)
  )
)

(define-read-only (get-resource (resource-id uint))
  (map-get? resources { resource-id: resource-id })
)

(define-read-only (get-resource-allocation (allocation-id uint))
  (map-get? resource-allocations { allocation-id: allocation-id })
)

