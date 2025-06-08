;; Certification Issuance Contract
;; This contract issues sustainability certifications

(define-data-var admin principal tx-sender)
(define-data-var certification-counter uint u0)

;; NFT for certifications
(define-non-fungible-token sustainability-cert uint)

;; Map to store certification details
(define-map certifications uint
  {
    product-id: (string-ascii 100),
    certifier: principal,
    manufacturer: principal,
    certification-type: (string-ascii 50),
    issue-date: uint,
    expiry-date: uint,
    sustainability-score: uint,
    revoked: bool
  }
)

;; Public function to issue a certification
(define-public (issue-certification
    (product-id (string-ascii 100))
    (manufacturer principal)
    (certification-type (string-ascii 50))
    (validity-period uint)
    (sustainability-score uint))
  (let (
    (caller tx-sender)
    (cert-id (var-get certification-counter))
  )
    (begin
      ;; Check if certifier is verified (would call the certification-body-verification contract)
      ;; For simplicity, we're not implementing the contract-call? here

      ;; Validate score
      (asserts! (<= sustainability-score u100) (err u1))

      ;; Mint NFT
      (try! (nft-mint? sustainability-cert cert-id caller))

      ;; Store certification details
      (map-set certifications cert-id
        {
          product-id: product-id,
          certifier: caller,
          manufacturer: manufacturer,
          certification-type: certification-type,
          issue-date: block-height,
          expiry-date: (+ block-height validity-period),
          sustainability-score: sustainability-score,
          revoked: false
        }
      )

      ;; Increment counter
      (var-set certification-counter (+ cert-id u1))

      (ok cert-id)
    )
  )
)

;; Public function to revoke a certification
(define-public (revoke-certification (cert-id uint))
  (let ((cert-details (map-get? certifications cert-id)))
    (begin
      (asserts! (is-some cert-details) (err u2)) ;; Certification doesn't exist
      (asserts! (is-eq tx-sender (get certifier (unwrap-panic cert-details))) (err u3)) ;; Not the certifier
      (asserts! (not (get revoked (unwrap-panic cert-details))) (err u4)) ;; Already revoked

      (ok (map-set certifications cert-id
        (merge (unwrap-panic cert-details) { revoked: true })
      ))
    )
  )
)

;; Public function to transfer a certification
(define-public (transfer-certification (cert-id uint) (recipient principal))
  (let ((owner (unwrap! (nft-get-owner? sustainability-cert cert-id) (err u5))))
    (begin
      (asserts! (is-eq tx-sender owner) (err u6)) ;; Not the owner
      (try! (nft-transfer? sustainability-cert cert-id tx-sender recipient))
      (ok true)
    )
  )
)

;; Read-only function to get certification details
(define-read-only (get-certification-details (cert-id uint))
  (map-get? certifications cert-id)
)

;; Read-only function to check if certification is valid (not expired and not revoked)
(define-read-only (is-certification-valid (cert-id uint))
  (let ((cert-details (map-get? certifications cert-id)))
    (if (is-some cert-details)
      (and
        (not (get revoked (unwrap-panic cert-details)))
        (> (get expiry-date (unwrap-panic cert-details)) block-height)
      )
      false
    )
  )
)
