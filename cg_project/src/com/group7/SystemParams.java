package com.group7;

import it.unisa.dia.gas.jpbc.*;

import java.math.BigInteger;

public class SystemParams {
    final Field<Element> G1, G2;
    final Element P;
    final BilinearPairing e;
    final Element publicKey;
    final BigInteger q;
    final HashFunction1 H1;
    final HashFunction2 H2;
    final HashFunction3 H3;
    Field<Element> Zq;

    public SystemParams(
            Field<Element> g1,
            Field<Element> g2,
            Field<Element> Zq,
            Element p,
            Element publicKey,
            BilinearPairing e,
            BigInteger q,
            HashFunction1 h1,
            HashFunction2 h2,
            HashFunction3 h3) {
        G1 = g1;
        G2 = g2;
        P = p;
        this.publicKey = publicKey;
        this.e = e;
        this.q = q;
        this.Zq = Zq;
        H1 = h1;
        H2 = h2;
        H3 = h3;
    }

    @Override
    public String toString() {
        return "SystemParams{" +
                "G1=" + G1 +
                ", G2=" + G2 +
                ", P=" + P +
                ", publicKey=" + publicKey +
                ", e=" + e +
                ", q=" + q +
                ", H1=" + H1 +
                ", H2=" + H2 +
                ", H3=" + H3 +
                '}';
    }
}
