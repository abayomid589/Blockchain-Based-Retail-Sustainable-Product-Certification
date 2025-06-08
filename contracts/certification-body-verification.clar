;; Certification Body Verification Contract
;; This contract validates sustainability certifiers

(define-data-var admin principal tx-sender)

;; Map to store verified certification bodies
(define-map certification-bodies principal
  {
    name: (string-ascii 100),
    website: (string-ascii 100),
    verified: bool,
    verification-date: uint,
    reputation-score: uint
  }
)

;; Public function to register a new certification body
(define-public (register-certification-body (name (string-ascii 100)) (website (string-ascii 100)))
  (let ((caller tx-sender))
    (begin
      (asserts! (not (is-some (map-get? certification-bodies caller))) (err u1)) ;; Already registered
      (ok (map-set certification-bodies caller
        {
          name: name,
          website: website,
          verified: false,
          verification-date: u0,
          reputation-score: u0
        }
      ))
    )
  )
)

;; Admin function to verify a certification body
(define-public (verify-certification-body (certifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (asserts! (is-some (map-get? certification-bodies certifier)) (err u3)) ;; Not registered
    (ok (map-set certification-bodies certifier
      (merge (unwrap-panic (map-get? certification-bodies certifier))
        {
          verified: true,
          verification-date: block-height
        }
      )
    ))
  )
)

;; Public function to update reputation score
(define-public (update-reputation (certifier principal) (score uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (asserts! (<= score u100) (err u4)) ;; Score must be between 0-100
    (asserts! (is-some (map-get? certification-bodies certifier)) (err u3)) ;; Not registered
    (ok (map-set certification-bodies certifier
      (merge (unwrap-panic (map-get? certification-bodies certifier))
        {
          reputation-score: score
        }
      )
    ))
  )
)

;; Read-only function to check if a certifier is verified
(define-read-only (is-verified-certifier (certifier principal))
  (default-to false (get verified (map-get? certification-bodies certifier)))
)

;; Read-only function to get certifier details
(define-read-only (get-certifier-details (certifier principal))
  (map-get? certification-bodies certifier)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (ok (var-set admin new-admin))
  )
)
