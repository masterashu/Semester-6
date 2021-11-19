package com.group7;

import java.io.Serializable;

// Used as a concealed Wallet containing
// Details of cart, etc,
// Ignored products and cart. for working PoC
public class Wallet  implements Serializable {
    final float price;
    final String idT;
    // TODO: User data, email, address, cart.

    public Wallet(float price, String idT) {
        this.price = price;
        this.idT = idT;
    }

    public boolean verify(float price) {
        return this.price == price;
        // TODO: Match User data, email, address, cart.
    }
}
