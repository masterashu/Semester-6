package com.group7;

import it.unisa.dia.gas.jpbc.Element;

import java.math.BigInteger;

public interface HashFunction2 {
    BigInteger hash(byte[] data, Element a, Element b, Element c);
}
