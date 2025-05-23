;; Service Provider Verification Contract
;; This contract validates transportation operators in the urban mobility network

;; Define data maps
(define-map providers
  { provider-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    license-number: (string-ascii 32),
    service-type: (string-ascii 16),
    is-verified: bool,
    verification-date: uint
  }
)

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

;; Register a new service provider
(define-public (register-provider
    (provider-id (string-ascii 32))
    (name (string-ascii 64))
    (license-number (string-ascii 32))
    (service-type (string-ascii 16))
  )
  (begin
    ;; Check if provider already exists
    (asserts! (is-none (map-get? providers { provider-id: provider-id })) err-already-registered)

    ;; Add provider to map (initially unverified)
    (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        license-number: license-number,
        service-type: service-type,
        is-verified: false,
        verification-date: u0
      }
    )

    (ok true)
  )
)

;; Verify a service provider
(define-public (verify-provider (provider-id (string-ascii 32)))
  (begin
    ;; Only contract owner can verify providers
    (asserts! (is-contract-owner) err-unauthorized)

    ;; Check if provider exists
    (match (map-get? providers { provider-id: provider-id })
      provider-data (begin
        ;; Update provider verification status
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data {
            is-verified: true,
            verification-date: block-height
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Get provider information
(define-read-only (get-provider (provider-id (string-ascii 32)))
  (map-get? providers { provider-id: provider-id })
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider-id (string-ascii 32)))
  (match (map-get? providers { provider-id: provider-id })
    provider-data (ok (get is-verified provider-data))
    err-not-found
  )
)
