=================
DTLS Quick Guide
=================

        AUTHOR: DANIEL RAJ N
        
        CREATED ON  : Mon Jun 23 19:11:23 IST 2014 

	UPDATED ON  : Mon Jul 25 10:50:22 IST 2016

        VERSION     : 1.1


IPSec vs TLS vs DTLS
--------------------

    ::

         +---------------------+---------------------+----------------------+
         |  IPSec              |      TLS            |       DTLS           |
         +---------------------+---------------------+----------------------+
         |  NETWORK LAYER      |  TRANSPORT LAYER    | TRANSPORT LAYER      |
         +---------------------+---------------------+----------------------+
         |SUPPORTS ALL PROTOCOL| ONLY TCP SUPPORTED  | TCP/UDP/SCTP         |
         +---------------------+---------------------+----------------------+
         
         TODO- This section is incomplete, need to add positives, negatives
         
         
Architecture Diagram
--------------------

    Typically TLS/DTLS architecure would as below. Each of these blocks
    are described as per limited needs. For a detailed note about each refer RFC.

    ::

               
               
              +---------+ +--------+ +-------------+ +----------------+
              |Handshake| |Alert   | |Change Cipher| |Application Data|
              |Protocol | |Protocol| |Spec Protocol| |Protocol        |
              +---------+ +--------+ +-------------+ +----------------+
                                        |              
              +-------------------------------------------------------+
              |                  TLS Record Protocol                  |
              +-------------------------------------------------------+
                                        |              
              +-------------------------------------------------------+
              |                        TCP                            |
              +-------------------------------------------------------+


Record Protocol
---------------
        Sending Data
            1. takes messages to be transmitted, 
            2. fragments the data into manageable blocks, 
            3. optionally compresses the data,
            4. applies a MAC, 
            5. encrypts, 
            6. and transmits the result.  
        
        Received data is
            1. decrypted, 
            2. verified, 
            3. decompressed, 
            4. reassembled, 
            5. delivered to higher-level clients.


Handshake Protocol
------------------

        The Handshake Protocol is responsible for negotiating a session.
        The cryptographic parameters of the session state are produced by this
        layer. It has following items:

        1. session identifier 
            - to identify an active or resumable session state
        2. peer certificate  
        3. compression method
        4. cipher spec
            specifies
            - pseudorandom function (PRF) used to generate keying material
            - the bulk data encryption algorithm (such as null, AES,etc.)
            - and the MAC algorithm (such as HMAC-SHA1)
            - It also defines cryptographic attributes such as the mac_length.
        5. master secret 
            - 48-byte secret shared between the client and server
        6. is resumable
            - A flag indicating whether the session can be used to initiate new
              connections

Alert Protocol
---------------

        Alert messages convey the severity of the message (warning or fatal) 
        and a description of the alert.  Alert messages with a level of fatal
        result in the immediate termination of the connection. In this case, 
        other connections corresponding to the session may continue, but the 
        session identifier MUST be invalidated, preventing the failed session 
        from being used to establish new connections.  Like other messages, 
        alert messages are encrypted and compressed, as specified by the 
        current connection state. ::

            enum { warning(1), fatal(2), (255) } AlertLevel;

            enum {
                close_notify(0),
                unexpected_message(10),
                bad_record_mac(20),
                decryption_failed_RESERVED(21),
                record_overflow(22),
                decompression_failure(30),
                handshake_failure(40),
                no_certificate_RESERVED(41),
                bad_certificate(42),
                unsupported_certificate(43),
                certificate_revoked(44),
                certificate_expired(45),
                certificate_unknown(46),
                illegal_parameter(47),
                unknown_ca(48),
                access_denied(49),
                decode_error(50),
                decrypt_error(51),
                export_restriction_RESERVED(60),
                protocol_version(70),
                insufficient_security(71),
                internal_error(80),
                user_canceled(90),
                no_renegotiation(100),
                unsupported_extension(110),
                (255)
             } AlertDescription;

        
            struct {
                AlertLevel level;
                AlertDescription description;
            } Alert;


Closure Alerts
~~~~~~~~~~~~~~~ 

    The client and the server must share knowledge that the connection is
    ending in order to avoid a truncation attack. Either party may initiate 
    the exchange of closing messages.

    Either party may initiate a close by sending a close_notify alert.
    Any data received after a closure alert is ignored.


Error Alerts
~~~~~~~~~~~~


    When an error is detected, the detecting party sends a message to the 
    other party. Upon transmission or receipt of a fatal alert message, 
    both parties immediately close the connection.

Change Cipher Spec Protocol
---------------------------

        The protocol consists of a single message, which is encrypted and 
        compressed under the current (not the pending) connection state.

        The ChangeCipherSpec message is sent by both the client and the server 
        to notify the receiving party that subsequent records will be 
        protected under the newly negotiated CipherSpec and keys.
        
        The ChangeCipherSpec message is sent during the handshake after the 
        security parameters have been agreed upon, but before the verifying 
        Finished message is sent. 

        Note: If a rehandshake occurs while data is flowing on a connection,
        the communicating parties may continue to send data using the old
        CipherSpec.  However, once the ChangeCipherSpec has been sent,the
        new CipherSpec MUST be used.

Application Data Protocol
-------------------------

        Application data messages are carried by the record layer and are
        fragmented, compressed, and encrypted based on the current connection
        state. The messages are treated as transparent data to the record layer.

How it works
---------------

	Basic Message Flow	::
	
	   Client                                          Server
	   ------                                          ------

	   ClientHello             -------->                           Flight 1

		                       <-------    HelloVerifyRequest      Flight 2

	   ClientHello             -------->                           Flight 3

		                                          ServerHello    \
		                                         Certificate*     \
		                                   ServerKeyExchange*      Flight 4
		                                  CertificateRequest*     /
		                       <--------      ServerHelloDone    /

	   Certificate*                                              \
	   ClientKeyExchange                                          \
	   CertificateVerify*                                          Flight 5
	   [ChangeCipherSpec]                                         /
	   Finished                -------->                         /

		                                   [ChangeCipherSpec]    \ Flight 6
		                       <--------             Finished    /

		           Message Flights for Full Handshake 
	

    The ClientHello and ServerHello establish the following attributes: 
        Protocol Version,
        Session ID, 
        Cipher Suite,  
        Compression Method, and
        Cookie
        Additionally, two random values are generated and exchanged:
        - ClientHello.random and
        - ServerHello.random.

ClientHello
~~~~~~~~~~~~
        
    ClientHello is the first message sent from client towards server to start 
    or resume a secured connection.

        Protocol Version - version which client whishes to communicate during
        the session. This must be the highest value supported by client.

        SessionID - set to zero for new connections else non-zero (resume case)

        Cipher Suite - The cipher suite list, passed from the client to the
        server in the ClientHello message, contains the combinations of 
        cryptographic algorithms supported by the client in order of the 
        client's preference (favorite choice first). Each cipher suite defines
        - a key exchange algorithm, 
        - a bulk encryption algorithm (including secret key length), 
        - a MAC algorithm, and 
        - a PRF.  
          
        The server will select a cipher suite or, if no acceptable choices 
        are presented, return a handshake failure alert and close the 
        connection. If the list contains cipher suites the server does not 
        recognize, support, or wish to use, the server MUST ignore those 
        cipher suites, and process the remaining ones as usual.

        Compression Method - list of the compression methods supported
        by the client, sorted by client preference. It can be null as well.

        Cookie - The first client hello sets this to zero, once client recieves 
        HelloVerifyRequest this cookie is copied from HelloVerifyRequest.


HelloVerifyRequest
~~~~~~~~~~~~~~~~~~

        When the client sends its ClientHello message to the server, the server
        MAY respond with a HelloVerifyRequest message. This message contains
        a stateless cookie generated using the technique of [PHOTURIS]. The
        client MUST retransmit the ClientHello with the cookie added. The
        server then verifies the cookie and proceeds with the handshake only
        if it is valid.

        Cookie = HMAC(Secret, Client-IP, Client-Parameters)

        The dtls version mentioned here is just for backward compatability and
        will not be used for version negotation. It might be mostly 1.0(not 1.2)

ServerHello
~~~~~~~~~~~~

        The server will send this message in response to a ClientHello(with
        Cookie) message when it was able to find an acceptable set of 
        algorithms. If it cannot find such a match, it will respond with a
        handshake failure alert.

        Protocol Version - This field will contain the lower of that suggested
        by the client in the client hello and the highest supported by the server

        1. Client negotiate with older servers

        If a TLS server receives a ClientHello containing a version number
        greater than the highest version supported by the server, it MUST
        reply according to the highest version supported by the server.

        If the client agrees to use this version, the negotiation will proceed 
        as appropriate for the negotiated protocol.

        If the version chosen by the server is not supported by the client (or
        not acceptable), the client MUST send a "protocol_version" alert 
        message and close the connection.

        2. Client negotiate with newer servers

        A TLS server can also receive a ClientHello containing a version
        number smaller than the highest supported version.  If the server
        wishes to negotiate with old clients, it will proceed as appropriate
        for the highest version supported by the server that is not greater
        than ClientHello.client_version.  For example, if the server supports
        TLS 1.0, 1.1, and 1.2, and client_version is TLS 1.0, the server will
        proceed with a TLS 1.0 ServerHello.  If server supports (or is
        willing to use) only versions greater than client_version, it MUST
        send a "protocol_version" alert message and close the connection.

        Whenever a client already knows the highest protocol version known to
        a server (for example, when resuming a session), it SHOULD initiate
        the connection in that native protocol.

        Session ID - This is the identity of the session corresponding to this
        connection. If the ClientHello.session_id was non-empty, the server 
        will look in its session cache for a match.

        Cipher Suite - The single cipher suite selected by the server from the
        list in ClientHello. For resumed sessions, this field is the value from
        the state of the session being resumed.

        Compression Method - The single compression algorithm selected by the
        server from the list in ClientHello. For resumed sessions, this field is
        the value from the resumed session state.


ServerCertificate
~~~~~~~~~~~~~~~~~~

    The server MUST send a Certificate message whenever the agreed-upon key 
    exchange method uses certificates for authentication. This message will
    always immediately follow the ServerHello message. 

    The same message type and structure will be used for the client's response 
    to a certificate request message.  Note that a client MAY send no 
    certificates if it does not have an appropriate certificate to send in 
    response to the server's authentication request.

    The following rules apply to the certificates sent by the server

	 * The certificate type MUST be X.509v3, unless explicitly negotiated otherwise (e.g., [TLSPGP]).

	 * The end entity certificate's public key (and associated restrictions) MUST be compatible with the selected key exchange algorithm. 

      ::

        Key Exchange Alg.     Certificate Key Type

        RSA                   RSA public key; the certificate MUST allow the
        RSA_PSK               key to be used for encryption (the
                              keyEncipherment bit MUST be set if the key
                              usage extension is present).
                              Note: RSA_PSK is defined in [TLSPSK].


        DHE_RSA               RSA public key; the certificate MUST allow the
        ECDHE_RSA             key to be used for signing (the digitalSignature
                              bit MUST be set if the key usage extension is
                              present) with the signature scheme and hash
                              algorithm that will be employed in the server key
                              exchange message. Note: ECDHE_RSA is defined in
                              [TLSECC].

        DHE_DSS               DSA public key; the certificate MUST allow the
                              key to be used for signing with the hash algorithm
                              that will be employed in the server key exchange
                              message.

        DH_DSS                Diffie-Hellman public key; the keyAgreement bit
        DH_RSA                MUST be set if the key usage extension is present.

        ECDH_ECDSA            ECDH-capable public key; the public key MUST use a
        ECDH_RSA              curve and point format supported by the client, as
                              described in [TLSECC].

        ECDHE_ECDSA           ECDSA-capable public key; the certificate MUST
                              allow the key to be used for signing with the hash
                              algorithm that will be employed in the server key
                              exchange message.  The public key MUST use a curve
                              and point format supported by the client, as
                              described in  [TLSECC].

    -  The "server_name" and "trusted_ca_keys" extensions [TLSEXT] are
                used to guide certificate selection.



ServerKeyExchange
~~~~~~~~~~~~~~~~~

    This message will be sent immediately after the server Certificate
    message (or the ServerHello message, if this is an anonymous negotiation).

    The ServerKeyExchange message is sent by the server only when the
    server Certificate message (if sent) does not contain enough data
    to allow the client to exchange a premaster secret.  This is true
    for the following key exchange methods:

        DHE_DSS
        DHE_RSA
        DH_anon

    It is not legal to send the ServerKeyExchange message for the following key
    exchange methods:

        RSA
        DH_DSS
        DH_RSA

    Other key exchange algorithms, such as those defined in [TLSECC],MUST 
    specify whether the ServerKeyExchange message is sent or not; and if the 
    message is sent, its contents.

CertificateRequest
~~~~~~~~~~~~~~~~~~
	A non-anonymous server can optionally request a certificate from the client, if 
	appropriate for the selected cipher suite.  This message, if sent, will immediately 
	follow the ServerKeyExchange message.

ServerHelloDone
~~~~~~~~~~~~~~~

   When this message will be sent:

      The ServerHelloDone message is sent by the server to indicate the
      end of the ServerHello and associated messages.  After sending
      this message, the server will wait for a client response.

   Meaning of this message:

      This message means that the server is done sending messages to
      support the key exchange, and the client can proceed with its
      phase of the key exchange.

      Upon receipt of the ServerHelloDone message, the client SHOULD
      verify that the server provided a valid certificate, if required,
      and check that the server hello parameters are acceptable.

ClientCertificate
~~~~~~~~~~~~~~~~~

	 This message is only sent if the server requests a certificate.  If no 
	 suitable certificate is available, the client MUST send a certificate 
	 message containing no certificates.  That is, the certificate_list 
	 structure has a length of zero.  If the client does not send any 
	 certificates, the server MAY at its discretion either continue the 
	 handshake without client authentication, or respond with a fatal 
	 handshake_failure alert.  Also, if some aspect of the certificate chain was
	 unacceptable (e.g., it was not signed by a known, trusted CA), the server
	 MAY at its discretion either continue the handshake (considering the client 
	 unauthenticated) or send a fatal alert.

ClientKeyExchange
~~~~~~~~~~~~~~~~~

	 This message is always sent by the client.
	
	 With this message, the premaster secret is set, either by direct 
	 transmission of the RSA-encrypted secret or by the transmission of 
	 Diffie-Hellman parameters that will allow each side to agree upon the same 
	 premaster secret.
    
    If RSA is being used for key agreement and authentication, the client 
    generates a 48-byte premaster secret, encrypts it using the public key 
    from the server's certificate, and sends the result in an encrypted 
    premaster secret message.
	
	
	 Note: It's recommeneded to read this section completely from RFC5246

CertificateVerify
~~~~~~~~~~~~~~~~~

	 This message is used to provide explicit verification of a client
	 certificate.  This message is only sent following a client certificate 
	 that has signing capability (i.e., all certificates except those containing
	 fixed Diffie-Hellman parameters).  When sent, it MUST immediately follow 
	 the client key exchange message.
	
Finished
~~~~~~~~~

   When this message will be sent:

      A Finished message is always sent immediately after a ChangeCipherSpec
      message to verify that the key exchange and
      authentication processes were successful.  It is essential that a
      change cipher spec message be received between the other handshake
      messages and the Finished message.

   Meaning of this message:

      The Finished message is the first one protected with the just
      negotiated algorithms, keys, and secrets.  
      
      Recipients of Finished messages MUST verify that the contents are correct. 
      Once a side
      has sent its Finished message and received and validated the
      Finished message from its peer, it may begin to send and receive
      application data over the connection.	

TYPES OF CRYPTOGRAPHIC ALGORITHMS
---------------------------------

    1. Secret Key Cryptography (SKC): Uses a single key for both encryption and decryption 
    2. Public Key Cryptography (PKC): Uses one key for encryption and another for decryption 
    3. Hash Functions: Uses a mathematical transformation to irreversibly "encrypt" information 
	
	
Secret Key Cryptography (SKC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    The sender and receiver of a message share a single, common key that is 
    used to encrypt and decrypt the message    

    SKC are implemented as either block ciphers or stream ciphers. 
	
    BLOCK CIPHER enciphers input in blocks of plaintext.

        * Data Encryption Standard (DES) 
	     * Advanced Encryption Standard (AES)


	 STREAM CIPHERS create an arbitrarily long stream of key material, which is combined 
	 with the plaintext bit-by-bit or character-by-character. The output stream is created 
	 based on a hidden internal state which changes as the cipher operates. That internal 
	 state is initially set up using the secret key material. 
	
		  * RC4 is a widely used stream cipher; 


Public Key Cryptography (PKC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Public-key encryption, in which a message is encrypted with a recipient's public key. 
    The message cannot be decrypted by anyone who does not possess the matching private 
    key, who is thus presumed to be the owner of that key and the person associated with 
    the public key. This is used in an attempt to ensure confidentiality.

    Digital signatures, in which a message is signed with the sender's private key and can
    be verified by anyone who has access to the sender's public key. This verification 
    proves that the sender had access to the private key, and therefore is likely to be 
    the person associated with the public key. This also ensures that the message has not 
    been tampered, as any manipulation of the message will result in changes to the 
    encoded message digest, which otherwise remains unchanged between the 
    sender and receiver.
    
    

Cryptographic Hash Functions 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	 They take a message of any length as input, and output a short, fixed length hash 
	 which can be used in (for example) a digital signature. For good hash functions, an 
	 attacker cannot find two messages that produce the same hash. 
	
	 Message Digest (MD) algorithms: A series of byte-oriented algorithms that produce a 
	 128-bit hash value from an arbitrary-length message.

	     MD4, MD5
	
	 Secure Hash Algorithm series 

	     SHA-0, SHA-1, SHA-2, SHA-3

    Message authentication codes (MACs) are much like cryptographic hash 
    functions, except that a secret key can be used to authenticate the hash 
    value upon receipt.


    
CERTIFICATE FORMATS
-------------------

    * PKI - A public key infrastructure (PKI) is a system for the creation, 
      storage, and distribution of digital certificates which are used to 
      verify that a particular public key belongs to a certain entity. 

    * X.509 v.3  -- current standard supported by IPSec/TLS/DTLS to exchange certificates
    
		X.509 is an ITU-T standard for a public key infrastructure (PKI) and
		Privilege Management Infrastructure (PMI). X.509 specifies, amongst other
		things, standard formats for public key certificates, certificate revocation
		lists, attribute certificates, and a certification path validation
		algorithm.


		Common filename extensions for X.509 certificates are:

		.pem 			– (Privacy-enhanced Electronic Mail) Base64 encoded DER 
						  	certificate, enclosed between 
						  	"-----BEGIN CERTIFICATE-----" and "-----END CERTIFICATE-----"
						  	
		.cer, .crt,		– usually in binary DER form, but Base64-encoded certificates 
		 .der	   		  	are common too (see .pem above)
		 
		.p7b, .p7c 		– PKCS#7 SignedData structure without data, 
							just certificate(s) or CRL(s)
							
		.p12 			– PKCS#12, may contain certificate(s) (public) and 
							private keys (password protected)
							
		.pfx 			– PFX, predecessor of PKCS#12 (usually contains data in 
							PKCS#12 format, e.g., with PFX files generated in IIS)

		PKCS#7 is a standard for signing or encrypting (officially called "enveloping") 
		data. Since the certificate is needed to verify signed data, it is possible to 
		include them in the SignedData structure. A .P7C file is a degenerated SignedData 
		structure, without any data to sign.

		PKCS#12 evolved from the personal information exchange (PFX) standard and is used
		to exchange public and private objects in a single file.

		CRL  certificate revocation list

    * Alternatives

      1. PGP(Pretty Good Privacy) where anyone (not just special CAs) may 
         sign and thus attest to the validity of others key certificates.

      2. OpenPGP
      
      3. SPKI
	
	  4. GnuPG or GPG (GNU Privacy Guard)      


CERTIFICATE CREATION/MANAGEMENT TOOLS
-------------------------------------

TOOLS
~~~~~~
		These tools are used to create and maintian(import/export) the keys to/from
		keystores and truststores
		
		to generate a csr, you can use either openssl or keytool.

		if you have a Linux-based sserver like Apache, 
		use openssl to generate the csr/private key, the certificate is then installed 
		referencing the certificate (public key), the private key and the intermediates 
		in the configuration file.
		
		if you have a Java-based server like Tomcat, Glassfish, etc., use keytool to 
		generate the keystore and the csr/private key, then install the certificate 
		in the correct format.		

	
		* OpenSSL -- available on all platforms
		* Java keytool (usually bundled with the JRE) -- available on all platforms
		

		Alternatives
		
		* GnuTLS for linux/Solaris -- needs to be complied (Solairs 10 there are issues)		
		* makecert.exe binary from windows	
		* Wincert - Wincert is a linux shell script which converts an openssl certificate 
					into a zipfile with the entire certificate chain in a Windows friendly
					encoding, bundled with a user-friendly installer.
		* racoon  on RHEL



		
CREATE/LOAD CERTIFICATE
~~~~~~~~~~~~~~~~~~~~~~~
	
	OpenSSL is usually installed under "/usr/local/ssl/bin"    

	master configuration file can be found at
		/usr/local/ssl/lib/openssl.cnf  or 	/etc/ssl/openssl.cnf
		
		
	Steps to be carried out
	1. Generate a key pair (private key/public key)
	2. Generate CSR (Certificate Signing Request) with public key as the input
	3. Send CSR to CA to get it signed
	4. CA shares the certificate with us(this will have the ca's public key -- not our's)

	When client is validating the certificate from server which is signed by ca
	* client looks into truststore to check if the ca's entry is present then
	* client validates the certificate 
	* client would encrypt the new messages using server's public key obtained from certificate
	* server would use server's private key to decode the message sent from client
    
    when working with java applications we must create certificates/keys using openssl and
    then load these certificates/keys to java keystore using "keytool".
	

Sample x509v3 certificate
~~~~~~~~~~~~~~~~~~~~~~~~~

::

		$ openssl x509 -in thawte-ca-certificate.pem -noout -text
		Certificate:
		   Data:
			   Version: 3 (0x2)
			   Serial Number: 1 (0x1)
			   Signature Algorithm: md5WithRSAEncryption
			   Issuer: C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc,
				       OU=Certification Services Division,
				       CN=Thawte Server CA/emailAddress=server-certs@thawte.com
			   Validity
				   Not Before: Aug  1 00:00:00 1996 GMT
				   Not After : Dec 31 23:59:59 2020 GMT
			   Subject: C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc,
				        OU=Certification Services Division,
				        CN=Thawte Server CA/emailAddress=server-certs@thawte.com
			   Subject Public Key Info:
				   Public Key Algorithm: rsaEncryption
				   RSA Public Key: (1024 bit)
				       Modulus (1024 bit):
				           00:d3:a4:50:6e:c8:ff:56:6b:e6:cf:5d:b6:ea:0c:
				           68:75:47:a2:aa:c2:da:84:25:fc:a8:f4:47:51:da:
				           85:b5:20:74:94:86:1e:0f:75:c9:e9:08:61:f5:06:
				           6d:30:6e:15:19:02:e9:52:c0:62:db:4d:99:9e:e2:
				           6a:0c:44:38:cd:fe:be:e3:64:09:70:c5:fe:b1:6b:
				           29:b6:2f:49:c8:3b:d4:27:04:25:10:97:2f:e7:90:
				           6d:c0:28:42:99:d7:4c:43:de:c3:f5:21:6d:54:9f:
				           5d:c3:58:e1:c0:e4:d9:5b:b0:b8:dc:b4:7b:df:36:
				           3a:c2:b5:66:22:12:d6:87:0d
				       Exponent: 65537 (0x10001)
			   X509v3 extensions:
				   X509v3 Basic Constraints: critical
				       CA:TRUE
		   Signature Algorithm: md5WithRSAEncryption
			   07:fa:4c:69:5c:fb:95:cc:46:ee:85:83:4d:21:30:8e:ca:d9:
			   a8:6f:49:1a:e6:da:51:e3:60:70:6c:84:61:11:a1:1a:c8:48:
			   3e:59:43:7d:4f:95:3d:a1:8b:b7:0b:62:98:7a:75:8a:dd:88:
			   4e:4e:9e:40:db:a8:cc:32:74:b9:6f:0d:c6:e3:b3:44:0b:d9:
			   8a:6f:9a:29:9b:99:18:28:3b:d1:e3:40:28:9a:5a:3c:d5:b5:
			   e7:20:1b:8b:ca:a4:ab:8d:e9:51:d9:e2:4c:2c:59:a9:da:b9:
			   b2:75:1b:f6:42:f2:ef:c7:f2:18:f9:89:bc:a3:ff:8a:23:2e:
			   70:47 



Trouble Shooting Guide
------------------------

- verify if certificates are ok
- disable Weak-Ciphers (-Dcom.sun.net.ssl.enableECC=false)
- disable SSL(TLSv1.0 and above must be supported)
- Enable tomcat logging
- Enable Application logging (optional)
- if java version is 1.6 and post browser upgrade if its not working then we need to disable DHE ciphers(it might be logjam issue)



Site Issues
-------------


VF DE - NTR OTA - Devin/Appa - 29th Apr 2015
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Problem Statement:
	Hi Amit, Daniel,
	      This email is regarding an NTR OTA deployment. OTA is the server (talking HTTPS) and the operators client is connecting to it. They are using server certificates but not client certificates. 
	      The observation is that 20% of HTTPS requests are failing. I have attached the openssl client output and snoop logs shared by the client.

		If you scroll down the client has explained the pcap packets - it will help you go through pcap. Can you have a look at the data and see if it rings a bell. Note that in the 
		openssl-failure.txt, the client has not passed the CA path and hence there is a verify error. But my impression that it is more of a warning and not actually related to the problem statement.

	Regards,
	Parag


rwsupport@VRS-NTR-APP2 07:58:00 $ java -version
java version "1.6.0_03"
Java(TM) SE Runtime Environment (build 1.6.0_03-b05)
Java HotSpot(TM) Server VM (build 1.6.0_03-b05, mixed mode)

R&D Actions:

Step1:
openssl s_client -host 62.87.95.170 -port 8443 -state -debug -CApath /opt/certificates/CAs/
---

New, TLSv1/SSLv3, Cipher is EDH-RSA-DES-CBC3-SHA
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
SSL-Session:
    Protocol  : TLSv1
    Cipher    : EDH-RSA-DES-CBC3-SHA
    Session-ID: 5541D2F005947A96C69E509D8A8D6B17D8D2A4D29FDD2D5329B412752F5CC750
    Session-ID-ctx:
    Master-Key: 45E57F5A040D08DDCF28E71139CBEE767C7380AAB253B834ADD8D646CDE3AC7DD857E124334E117B39696238828C6218
    Key-Arg   : None
    Start Time: 1430377200
    Timeout   : 300 (sec)
    Verify return code: 19 (self signed certificate in certificate chain)


Step2:

for i in {1..300} ; do openssl s_client -host 10.10.16.142 -port 8433 >> /tmp/client-test.log; done


Step3:

disable weak ciphers -this step helped to reduce 90% of issues

Step4: 
Now we are left with Invalid Padding issue. Upgrade to java 8 solved this problem as well.

	   http-8443-2, SEND TLSv1 ALERT:  fatal, description = handshake_failure
	   http-8443-2, WRITE: TLSv1 Alert, length = 2
	   http-8443-2, called closeSocket()
	      http-8443-2, handling exception: javax.net.ssl.SSLHandshakeException: Invalid padding
	   http-8443-2, called close()
	   http-8443-2, called closeInternal(true)



Orange - OTA -  Omar/Khallid - 3rd Aug 2015
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Problem Statement:

Hi
 

We are stuck since end of last week in OTA integration with FT, the OTA requests are failing due to SSL checks, it was working before but things changed since 1 week
Orange teams are claiming nothing changed on their certicates, and escalation is expected soon , our guy onsite did follow the procedures and re-did it many times in order to make sure nothing is missed
I need a dedicated help urgently from backend

Regards
Khalid Sweeseh 

R&D Actions:
1. enabled loging and verified certificates were not imported correctly after that things looked to be fine from our side. 
But the response that we got towards SOAP was nok hence we had asked to check with operator why its not replying correctly.

Conclusion:
Operator had to do some code changes to fix the issue. we dint do anything.


Telcel_Mexico - OTA - Sandeep/Bhooshan - Oct 9th 2015
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SNI extension issue - Meeting with OTA 



Telcel - NTR - Sandeep - 6th June 2016
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

certificates issue


MENA - OM GUI - Oleg - 21st July 2016
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Problem Statement: 
Customer has upgrade IE from 8 to 9 and after the GUI is not working what to do?

R&D Actions taken:
1. Asked to disable weak-ciphers and set protocols to TLSv1.0 & above -- issues not resolved.
2. Asked to enable ssl logging & share java version -- we found the following error
::
	…
	Cipher suite:  TLS_DHE_DSS_WITH_AES_128_CBC_SHA

	…
	*** ServerHelloDone
	http-8443-1, WRITE: TLSv1 Handshake, length = 1224
	http-8443-1, received EOFException: error
	http-8443-1, handling exception: javax.net.ssl.SSLHandshakeException: Remote host closed connection during handshake
	http-8443-1, SEND TLSv1 ALERT:  fatal, description = handshake_failure
	http-8443-1, WRITE: TLSv1 Alert, length = 2
	http-8443-1, called closeSocket()
	http-8443-1, called close()
	http-8443-1, called closeInternal(true)

3. Simulate the problem in lab
4. Site had java version "1.6.0_51" this is relatively new but still it dint work

Conclusion:

This is logjam issue where dh key length less than 1024 will be rejected. So we have disabled DHE ciphers in lab and it worked fine.
Another possible solution would be to upgrade to latest versions of java 7 or 8.


In your server.xml file, change the following snippet::

    <Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true"
               maxThreads="150" scheme="https" secure="true"
               clientAuth="false" sslProtocol="TLS" keyAlias="myKey" keystoreFile="/opt/certs/server.keystore" keypass="watapp01"/>

The above tag should become::

    <Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true"
               maxThreads="150" scheme="https" secure="true"
               ciphers="TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_256_CBC_SHA, SSL_RSA_WITH_RC4_128_SHA, SSL_RSA_WITH_3DES_EDE_CBC_SHA, SSL_RSA_WITH_RC4_128_MD5"
               clientAuth="false" sslProtocol="TLS" keyAlias="myKey" keystoreFile="/opt/certs/server.keystore" keypass="watapp01"/>




FAQ
----

	1. How do you know if its selfsigned?
		Ans: Certificate Subject and Issuer would be same


	2. How to enable basic ssl debugging logs?
		Ans: add "-Djavax.net.debug=ssl" to CATALINA_OPTS as shown below
	     	export CATALINA_OPTS="-server -Xms2048m -Xmx2048m -Djavax.net.debug=ssl"
		if we say "-Djavax.net.debug=all" it will enable every log

	3. How to enable application logging?
		Ans:To Enable logging you can follow steps below

		logging.properties and log4j.properties attached. Copy them to tomcat
		conf directory. 
		Add the following to startup options for java
		"-Dlog4j.configuration=file:/opt/Roamware/admin/jakarta-tomcat-6.0.20/conf/log4j.properties"

	4. How to disable weak-ciphers?
		Ans: add "-Dcom.sun.net.ssl.enableECC=false" to CATALINA_OPTS as shown below
	     	export CATALINA_OPTS="-server -Xms2048m -Xmx2048m -Dcom.sun.net.ssl.enableECC=false"

		Info: Sun Java has know issues with ECC hence its recommended to disable it.
		http://bugs.java.com/view_bug.do?bug_id=7016078


	5. How to disable ssl(or just enable only TSLv1.2)
		Ans: For tomcat, in server.xml, you need to add as below and restart tomcat server
		     sslProtocols = "TLSv1,TLSv1.1,TLSv1.2" (to support all TLS versions) or sslProtocols = "TLSv1.2" just to support v1.2


	6. How to simulate client request?
		Ans: `openssl s_client -host 62.87.95.170 -port 8443 -state -debug -CApath /opt/certificates/CAs/`
				or

		to simulate client request with specific cipher we must give 
		openssl s_client -cipher TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA   -host <IP> -port 8443  -CApath </opt/certificates/CAs/>

	7. If I see following error in debug logs what should I do?
	   http-8443-2, SEND TLSv1 ALERT:  fatal, description = handshake_failure
	   http-8443-2, WRITE: TLSv1 Alert, length = 2
	   http-8443-2, called closeSocket()
	      http-8443-2, handling exception: javax.net.ssl.SSLHandshakeException: Invalid padding
	   http-8443-2, called close()
	   http-8443-2, called closeInternal(true)
		Ans: check the java version being used. This issue was fixed in java 8 so you will have to upgrade java

		http://bugs.java.com/bugdatabase/view_bug.do?bug_id=7146728


	8. On Wireshark Im unable to see ssl/tls packets what to do?
		Ans: right click on any packet and say decode as -> select SSL now you must be able to see ssl/tls packets


	9. I view wireshark traces often and i dont want to do the above step everytime.
		Ans: Select Edit->Preferences->Protocols->HTTP and filling SSL/TLS Ports with 443,8443
	
	10. Q: LogJam --what's it? 
	    Q: ssl connection is not working after upgrading the browser.
		Ans:	
		A new SSL vulnerability know as LogJam was  identified on May 20th 2015.
		due to this firefox,chrome,IE would have updated there software to block ssl connections if a dh key length less than 1024 was being used.

		so we need to upgrade to latest java 7 or 8 to overcome this problem.


	11. How to display all the ciphers that are currently used by tomcat server?
		Ans: one quick way is to enable ssl debug logs and in catalina.out when the server comes up we would see all the ciphers selected.


	12. For HTTP Server how to disable ssl?
		Ans: in config file add the following line  (this disables sslv2,v3)
			SSLProtocol             all -SSLv2 -SSLv3

	13. For HTTP server how to set cipher suite?
		Ans:  In http config file we can mention as below

		SSLCipherSuite          ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA

		SSLHonorCipherOrder     on


	14. What is POODLE vulnerability?s
		Ans: POODLE is a SSL v3 protocol vulnerability. It allows attacker to downgrade SSL/TLS protocol to version SSL v3, and then break the cryptographic 
		security (e.g. decrypt the trafic, hijack sessions, etc.) 

		Mitigation: 
		-----------

			Disabling SSL v3 on either client side or server side will mitigate this vulnerability. 

		Apache Web Server

			The SSL configuration file changed slightly in httpd version 2.2.23. For httpd version 2.2.23 and newer, specify all protocols except SSLv2 and SSLv3.
				SSLProtocol ALL -SSLv2 -SSLv3

			For httpd version 2.2.22 and older, only specify TLSv1. This is treated as a wildcard for all TLS versions.	
				SSLProtocol TLSv1

			For Apache + mod_nss, edit /etc/httpd/conf.d/nss.conf to allow only TLS 1.0+.
				NSSProtocol TLSv1.0,TLSv1.1

		Postfix SMTP
			Modify the smtpd_tls_mandatory_protocols configuration line.
				smtpd_tls_mandatory_protocols=!SSLv2,!SSLv3

		HAProxy Server

			Edit the bind line in your /etc/haproxy.cfb file.
				bind :443 ssl crt  ciphers  no-sslv3

		
