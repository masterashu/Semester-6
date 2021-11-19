package com.group7;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Field;
import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.jpbc.PairingParameters;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;
import it.unisa.dia.gas.plaf.jpbc.pairing.a.TypeACurveGenerator;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;


public class Main {
    Element secret;
    Field<Element> G1;
    Field<Element> G2;
    Field<Element> GT;
    Field<Element> Zr;
    SystemParams params;

    Element URID;
    Element PPRID;

    public static void main(String[] args) {
        Main system = new Main();
        System.out.println("Setting up TSA System");
        long initTime = System.currentTimeMillis();
        /*
         ************** Setup *****************
         */
        system.setup();

        long endTime = System.currentTimeMillis();
        System.out.println("System Setup took: " + (endTime-initTime) + "ms");

        System.out.println("Registering a new User");
        initTime = System.currentTimeMillis();
        // Create and Register a user
        User user1 = new User(system.Zr, system.params);
        system.registerUser(user1);
        endTime = System.currentTimeMillis();
        System.out.println("Registering a new User took: " + (endTime-initTime) + "ms");

        System.out.println("Registering a new Pay Platform");
        initTime = System.currentTimeMillis();
        // Create and Register Android Pay Platform
        PayPlatform payPlatform = new PayPlatform(system.Zr, system.params);
        system.registerPayPlatform(payPlatform);
        endTime = System.currentTimeMillis();
        System.out.println("Registering a new Pay Platform took: " + (endTime-initTime) + "ms");

        /*
         ************ Transaction *************
         */
        // Receive parameters for checking
        float amount = 20.0F;
        System.out.printf("Initiated Payment of amount: %.2f.\n", amount);
        M2 m2 = user1.startTransaction(payPlatform, amount);
        Wallet wallet = m2.wallet;
        BigInteger hj = system.params.H1.hash(payPlatform.id.getBytes(),system.PPRID);
        BigInteger kj = system.params.H2.hash(payPlatform.id.getBytes(), payPlatform.publicKey, system.PPRID, system.params.publicKey);

        // Check First assert
        assert system.params.e.pair(system.params.P, m2.sigma_j1) ==
                system.params.e.pair(
                        system.params.H3.hash(SerializeUtils.serialize(wallet)),
                        m2.sigma_j2.add(system.params.publicKey.mul(hj)).add(system.secret.mul(kj))
                );
        System.out.println("✔ First Verification Complete.");


        // Check additional assert
        assert system.params.e.pair(system.params.P, m2.sigma_j2) ==
                system.params.e.pair(m2.sigma_j3, m2.sigma_j4.add(system.params.publicKey.mul(hj))
                        .add(system.params.P.mulZn(system.secret)));
        System.out.println("✔ Second Verification Complete.");


        System.out.printf("🎉 Payment Completed and verified for amount: %.2f.\n", amount);

    }

    public static BigInteger hashFunction1(byte[] input, Element b, BigInteger q) {
        try {
            input = Utils.addAll(input, b.toBytes());
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return new BigInteger(md.digest(input)).mod(q);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return new BigInteger(String.valueOf(0L));
    }

    public static BigInteger hashFunction2(byte[] input, Element a, Element b, Element c, BigInteger q) {
        try {
            input = Utils.addAll(input, a.toBytes());
            input = Utils.addAll(input, b.toBytes());
            input = Utils.addAll(input, c.toBytes());
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return new BigInteger(md.digest(input)).mod(q);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return new BigInteger(String.valueOf(0L));
    }

    public static Element hashFunction3(byte[] input, Field<Element> field) {
        return field.newElementFromBytes(input);

    }

    public void registerUser(User user) {
        BigInteger rID1 = this.Zr.newRandomElement().toBigInteger();
        Element RID1 = this.params.publicKey.mul(rID1);
        URID = RID1;
        BigInteger hID1 = this.params.H1.hash(user.id.getBytes(), RID1);
        BigInteger sID1 = rID1.add(hID1.multiply(this.secret.toBigInteger())).mod(params.q);
        user.setPartialPrivateKey(sID1, RID1);
    }

    public void registerPayPlatform(PayPlatform payPlatform) {
        BigInteger rIDAP = this.Zr.newRandomElement().toBigInteger();
        Element RIDAP = this.params.publicKey.mul(rIDAP);
        PPRID = RIDAP;
        BigInteger hIDAP = this.params.H1.hash(payPlatform.id.getBytes(), RIDAP);
        BigInteger sIDAP = rIDAP.add(hIDAP.multiply(this.secret.toBigInteger())).mod(params.q);
        payPlatform.setPartialPrivateKey(sIDAP, RIDAP);
    }

    @SuppressWarnings("unchecked")
    void setup() {
        int rBits = 1024;
        int qBits = 512;
        TypeACurveGenerator pg = new TypeACurveGenerator(rBits, qBits);
        PairingParameters params = pg.generate();

        BigInteger q = params.getBigInteger("q");
        Pairing pairing = PairingFactory.getPairing(params);
        G1 = pairing.getG1();
        G2 = pairing.getG2();
        GT = pairing.getGT();
        Zr = pairing.getZr();
        secret = pairing.getZr().newRandomElement();
        Element P = G1.newElement();
        Element pubKey = P.mulZn(secret);

        this.params = new SystemParams(
                G1, GT, pairing.getZr(),
                P, pubKey,
                pairing::pairing,
                q,
                (input, a) -> hashFunction1(input, a, q),
                (input, a, b, c) -> hashFunction2(input, a, b, c, q),
                (input) -> hashFunction3(input, G1)
        );
    }
}
