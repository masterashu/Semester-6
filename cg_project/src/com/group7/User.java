package com.group7;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Field;
import it.unisa.dia.gas.plaf.jpbc.field.z.ZrField;

import java.math.BigInteger;
import java.security.SecureRandom;
import java.util.Random;

@SuppressWarnings("FieldCanBeLocal")
public class User {
    public final String id;
    final Element publicKey;
    final SystemParams systemParams;
    private final Element secret;
    BigInteger sID;
    Element rID;


    public User(Field<Element> zp, SystemParams params) {
        id = "USER000000001";        // TODO: Used constant for PoC
        secret = zp.newRandomElement();
        publicKey = params.publicKey.mulZn(secret);
        systemParams = params;
    }

    public void setPartialPrivateKey(BigInteger sIDi, Element rIDi) {
        sID = sIDi;
        rID = rIDi;
        Element RID = systemParams.publicKey.mulZn(rID);
        assert systemParams.publicKey.mul(sID) == rID.add(systemParams.publicKey.mul(systemParams.H1.hash(id.getBytes(), RID)));
//        System.out.println(systemParams.publicKey.mul(sID));
//        System.out.println(rID.add(systemParams.publicKey.mul(systemParams.H1.hash(id.getBytes(), RID))));
    }

    M2 startTransaction(PayPlatform payPlatform, float amount) {
        // Creating a Final Wallet
        long initTime = System.currentTimeMillis();
        System.out.println("Creating a Full Wallet for transaction");
        Wallet wallet = payPlatform.createNewTransaction(this, amount);
        long endTime = System.currentTimeMillis();
        System.out.printf("Creating a Full Wallet for transaction took: %d ms\n", (endTime - initTime));
        assert wallet.verify(amount);
        System.out.println("✔ Verified Wallet");

        Element RID = systemParams.publicKey.mulZn(rID);
        BigInteger ki = systemParams.H2.hash(id.getBytes(), publicKey, RID, systemParams.publicKey);
        byte[] walletBytes = SerializeUtils.serialize(wallet);
        Element sigma1 = systemParams.H3.hash(walletBytes).mul(secret.toBigInteger().multiply(ki).add(sID));
        // RID = sigma2
        BigInteger ai = (new BigInteger(256, new SecureRandom())).mod(systemParams.q);
        BigInteger r = systemParams.H2.hash(id.getBytes(), publicKey, RID, systemParams.P.mul(ai));
        Element C1 = systemParams.P.mul(r);
        BigInteger x = new BigInteger(Utils.addAll(Utils.addAll(walletBytes, sigma1.toBytes()), RID.toBytes()));
        Element RIDAP = systemParams.publicKey.mulZn(payPlatform.rID);
        BigInteger y = Hash.hash(
                payPlatform.publicKey.
                        add(RIDAP).
                        add(systemParams
                                .publicKey.mul(systemParams.H1.hash(
                                        payPlatform.id.getBytes(), RIDAP
                                ))
                        )
                        .mul(r).toBytes()
        );
        BigInteger C2 = x.xor(y);

        // Sending request to Pay Platform
        System.out.println("Sending Request to Pay Platform");
        return payPlatform.sendM1(this, new M1(C1, C2), sigma1, RID);

    }
}
