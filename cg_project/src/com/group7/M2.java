package com.group7;

import it.unisa.dia.gas.jpbc.Element;

public class M2 {
    final Element sigma_j1,sigma_j2,sigma_j3,sigma_j4;
    final Wallet wallet;

    public M2(Element sigma_j1, Element sigma_j2, Element sigma_j3, Element sigma_j4, Wallet wallet) {
        this.sigma_j1 = sigma_j1;
        this.sigma_j2 = sigma_j2;
        this.sigma_j3 = sigma_j3;
        this.sigma_j4 = sigma_j4;
        this.wallet = wallet;
    }
}
