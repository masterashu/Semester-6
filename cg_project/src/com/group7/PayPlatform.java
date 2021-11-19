package com.group7;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Field;

import java.math.BigInteger;

@SuppressWarnings("FieldCanBeLocal")
public class PayPlatform {
    public final String id;
    private final Element secret;
    final Element publicKey;
    final SystemParams systemParams;
    Wallet currentWallet;
    BigInteger sID;
    Element rID;

    public PayPlatform(Field<Element> zp, SystemParams params) {
        id = "PP01";        // TODO: Used constant for PoC

        secret = zp.newRandomElement();
        publicKey = params.publicKey.mulZn(secret);
        systemParams = params;
    }

    public void setPartialPrivateKey(BigInteger sIDi, Element rIDi) {
        sID = sIDi;
        rID = rIDi;
        Element RID = systemParams.publicKey.mulZn(rID);
        assert systemParams.publicKey.mul(sID) == rID.add(
                systemParams.publicKey.mul(systemParams.H1.hash(id.getBytes(), RID))
        );
//        System.out.println(systemParams.publicKey.mul(sID));
//        System.out.println(rID.add(systemParams.publicKey.mul(systemParams.H1.hash(id.getBytes(), RID))));
    }

    public Wallet createNewTransaction(User user, float price) {
        // Using fixed Transaction id for PoC
        // TODO: generate transaction id
        currentWallet = new Wallet(price, "T0201");
        return currentWallet;
    }

    @SuppressWarnings("UnnecessaryLocalVariable")
    public M2 sendM1(User user, M1 data, Element sigma1, Element sigma2) {
        BigInteger FW__Si = Hash.hash(data.
                C1.mul(secret.toBigInteger().add(sID)).toBytes())
                .xor(data.C2);
        Element RID = systemParams.publicKey.mulZn(rID);
        BigInteger hi = systemParams.H1.hash(id.getBytes(), RID);
        BigInteger ki = systemParams.H2.hash(user.id.getBytes(), user.publicKey, sigma2, systemParams.publicKey);
        BigInteger kj = systemParams.H2.hash(id.getBytes(), publicKey, RID, systemParams.publicKey);
        Element Pi = systemParams.P.mulZn(secret);
        //
        assert systemParams.e.pair(systemParams.P, sigma1)
                == systemParams.e.pair(systemParams.H3.hash(SerializeUtils.serialize(currentWallet)),
                sigma2.add(systemParams.publicKey.mul(hi).add(secret.mul(ki))));

        System.out.println("✔ Verified Details by Pay Platform");
        System.out.println("Running Re-Key process on message");
        long initTime = System.currentTimeMillis();

        BigInteger ti = systemParams.Zq.newRandomElement().toBigInteger();
        Element rk_ij_1 = sigma2.add(systemParams.publicKey.mul(hi).add(Pi.mul(ki))).mul((secret.toBigInteger().multiply(kj).add(sID)).modInverse(systemParams.q));
        Element rk_ij_2 = RID;

        Element sigma_j1 = sigma1.mul(ti);
        Element sigma_j2 = sigma2.add(systemParams.publicKey.mul(hi).add(Pi.mul(ki))).mul(ti);
        Element sigma_j3 = rk_ij_1.mul(ti);
        Element sigma_j4 = rk_ij_2;
        long endTime = System.currentTimeMillis();
        System.out.println("Running Re-Key process on message took: " + (endTime-initTime) + "ms");

        System.out.println("Sending request to TSA");
        return new M2(sigma_j1, sigma_j2, sigma_j3, sigma_j4, currentWallet);
    }
}
