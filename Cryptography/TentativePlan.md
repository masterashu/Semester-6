# Term Project Final Report

### Title of the project

Light-Weight and Privacy-Preserving Authentication Protocol for Mobile Payments in the
Context of IoT.

### Group Code: G7 (Group No. 7)

### Group Members: Names and Roll Numbers

| Name             | Roll Number  | Email                 |
| ---------------- | ------------ | --------------------- |
| Ashutosh Chauhan | S20180010017 | ashutosh.c18@iiits.in |
| Saumya Doogar    | S20180010156 | saumya.d18@iiits.in   |

### Abstract

In the current world IoT is getting widespread over a wide range of scenarios. From
Smart Home to smart cards etc, IoT is becoming the new norm. One of the major
characteristics IoT is being lightweight in terms of size, power consumption,
performance, storage, etc. The protocol mentioned here provides security while still
making sure that the performance and storage are within the capabilities of a IoT system.
The protocol provides privacy and authentication for mobile payments in context of IoT.
There are a various number of use cases from payments from smart devices like smart
electric meters, smart cars, smart watches, monitoring systems, etc. The protocol uses at
unidirectional certificateless proxy re-signature scheme, which is of independent interest.
Based on this signature scheme, the protocol achieves anonymity, unforgeability and low
performance overhead. In this protocol the computational overhead is placed on the Pay
Platform. To increase the efficiency of the protocol, a batch-verification mechanism is
provided for the Pay Platform and Merchant Server. The security of the protocol is based
on the CDH (Computational Diffie-Hellman) Problem.

Protocol Summary

When a payment protocol in any IOT enabled smart device is implemented, the
involved computation and storage space should be low for the limited resourced
devices. However, in traditional transaction protocols, a public key infrastructure is
introduced to issue certificates for public key of the user. This validity of the public
key can be verified based on the certificates issued by a certificate authority. It is
easy to see that PKI caused a lot of communication and storage costs when the
revocation, storage, and distribution of certificates are done.


To solve the above challenge, we propose a new mobile payment scheme that
achieves anonymity, unforgeability and low resource consumption simultaneously.
All In all, this protocol accomplishes 3 things :

1. We propose the first unidirectional certificate-less proxy re-signature scheme
    which is of independent interest.
2. A mobile payment protocol with user anonymity is presented based on our
    proposed scheme.
3. Using Batch-verification to accelerate the signature verification process such
    that multiple signatures from different users on distinct messages can be
    verified quickly. Moreover, the signatures from the same user can be further
    batched to achieve higher efficiency

### Plan of Implementation

#### SYSTEM MODEL OF OUR TRANSACTION PROTOCOL

The considered system consists of four types of entities: the trusted system
authority (TSA), the user app, the merchant server, and the Pay Platform [9].

1. Trusted System Authority: TSA is a trusted third party organization that
    provides registration services for User’s App and Pay Platform. TSA also
    distributes system params and partial private keys for registered users to
    ensure the whole scheme successfully works.
2. User’s App: Any software that requires a payment function is called User’s
    App, such as Apple pay, etc. This application needs to be registered with the
    TSA to obtain the corresponding system params and partial private key. It also
    generates its own user secret value and public key. Then User’s App
    completes the signature using its full private key, which consists of partial
    private key.
3. Pay Platform: Pay Platform is an application offered by a trusted party, of
    course, it also needs to register with the TSA to obtain system params and
    private key. Simultaneously, in order to protect the user’s information of the
    transaction, Pay Platform will provide re-sign service, that is, the Pay Platform
    transforms signature of User’s App into signature of Pay Platform.
4. Merchant Server: Merchant Server is utilized by a merchant, it verifies the
    correctness of the transaction information to check the product is given to the
    right user.

![image-20210321160938799](C:\Users\Ashutosh\AppData\Roaming\Typora\typora-user-images\image-20210321160938799.png)

### Code and Experimental Results

We implemented the protocol in Java using the JPBC Library. We followed an
OOP approach with interfaces to keep the code modular and mocked Message
Passing between the various entities. We Initialized the Secret Parameters and
the ECC Pairing generation followed by the process of User Registration and Pay
Platform Registration. And finally making a payment.

We used Type A elliptical curve with G1 and G2 size 512 and 1024 bits
respectively.

Single Run Results:


![image-20210430104935425](C:\Users\Ashutosh\AppData\Roaming\Typora\typora-user-images\image-20210430104935425.png)

Results (Average Time (100)):

* System Setup: 4.1 seconds
* Registration: 10 ms
* Transaction: 1~2 ms


### Observations and Conclusion

#### Performance Analysis:

Our local machine on which we run code was more powerful than the one mentioned in
Paper but to due to lack of available hardware we ran the code and found really good
performance.

#### Scope of Improvement:

We used JBPC which relies on Java VM runtime and can cause an overhead, using a
native machine code implementation such as (PBC) for C++ will provide more
improvement in performance.

##### Configuration for User's App (Original)

- CPU: PXA270 processor 624MHz
- RAM: 1GB memory

##### Configuration for Payment Platform (Original)

- CPU: Intel i3-380M processor 2.53GHz
- RAM: 8GB memory

Hash Function: SHA-

$G_1$ , $Z_q$ -> 64 Byte

$G_2$ -> 128 Byte

ECC -> $y^2 = x^3 + x$

Paper's Usage

- VC++ 6.
- PBC library

Our Usage

- GNU G++
- PBC library

### Summary of the results

The Protocol is really secure and also works really fast and is also very low on
computation and storage resources and hence is a good pick for IOT mobile
payments. In our implementation we found that the User side computation took
very few time hence improving the user experience with IOT based payments as
well providing the same level of security as 2048 bit RSA.

### Source Code

![carbon (8)](D:\Ashutosh\Downloads\carbon (8).png)

![carbon (3)](D:\Ashutosh\Downloads\carbon (15).png)

![carbon (7)](D:\Ashutosh\Downloads\carbon (7).png)

![carbon (10)](D:\Ashutosh\Downloads\carbon (10).png)

![carbon (9)](D:\Ashutosh\Downloads\carbon (9).png)

![carbon (6)](D:\Ashutosh\Downloads\carbon (6).png)

![carbon (11)](D:\Ashutosh\Downloads\carbon (11).png)



## References

[1]: V. Sureshkumar, A. Ramalingam, N. Rajamanickam, and R. Amin, ‘‘A
lightweight two-gateway based payment protocol ensuring accountability and
unlinkable anonymity with dynamic identity,’’ Comput. Elect. Eng., vol. 57, pp.
223–240, Jan. 2017.

[2]: J-H. Yang and P.-Y. Lin, ‘‘A mobile payment mechanism with anonymity for
cloud computing,’’ J. Syst. Softw., vol. 116, pp. 69–74, Jun. 2016.


[3]: Z. Qin, J. Sun, A. Wahaballa, W. Zheng, H. Xiong, and H. Qin, ‘‘A secure and
privacy-preserving mobile wallet with outsourced verification in cloud computing,’’
Comput. Standards Interfaces, vol. 54, pp. 55–60, Nov. 2017.

[4]: K.-H. Yeh, ‘‘A secure transaction scheme with certificateless cryptographic
primitives for IoT-based mobile payments,’’ IEEE Syst. J., doi: 10.1109/
JSYST.2017.

[5] Y. Liao, Y. He, F. Li, and S. Zhou, ‘‘Analysis of a mobile payment protocol with
outsourced verification in cloud server and the improvement,’’ Comput. Standards
Interfaces, vol. 56, pp. 101–106, Feb. 2018, doi: 10.1016/j.csi.2017.09.008.