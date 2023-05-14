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
   
   signal out1 [k+1];
   signal out2[k];
   
   signal {maxbit} aux3[2 * k];
   aux3.maxbit = m;
   for (var i= 0; i< k; i++){
      aux3[i]<== a[i];
      aux3[k + i] <== a[i];
   }
   (out1, out2) <== BigMod(m, k)(aux3, aux_b);

}

component main {public [a, b]} = A(3, 2);
