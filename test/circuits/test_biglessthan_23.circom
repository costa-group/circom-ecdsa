pragma circom 2.0.2;

include "../../circuits/bigint.circom";

template A(m, k){
   signal input a[k];
   signal input b[k];
   
   signal {maxbit} aux_a[k];
   aux_a.maxbit = m;
   aux_a <== a;
   
   signal {maxbit} aux_b[k];
   aux_b.maxbit = m;
   aux_b <== b;
   
   signal out <== BigLessThan(m, k)(aux_a, aux_b);

}

component main {public [a, b]} = A(2, 3);

