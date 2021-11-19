package com.group7;

import it.unisa.dia.gas.jpbc.Element;

import java.math.BigInteger;

public interface HashFunction1 {
    BigInteger hash(byte[] data, Element a);
}

