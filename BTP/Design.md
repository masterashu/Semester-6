# Block

## Transactions

1. Message {Timestamp, Candidate, Nonce}
2. Hash (Pvx, Rvx1)

1. Message {Timestamp, Candidate, Nonce}
2. Hash (Pvx, Rvx2)

List: [Pvx, Pvy, Pv ..... ]

# Creation of a Block

We receive Tx {_Message {Timestamp, Candidate, Nonce}_, Pvx, H(Pvx, Rvx), Signature (M, Pvx, H(Pvx, Rvx))} 

Local Node  List of Pv : remove Pvx

