pragma circom 2.1.5;

include "circuits/comparators.circom";
include "circuits/bitify.circom";
include "circuits/gates.circom";



include "bigint_func.circom";


function max2(a, b){
   return a>b ?  a : b;
}

template UpdateMaxbitTag(n){
   signal input {maxbit} in;
   signal output {maxbit} out;
   
   assert(n >= in.maxbit);
   
   out.maxbit = n;
   out <== in;


}

template Aux(n, k){
   signal input a;
   signal input b;
   signal input c;
   signal input d;
   
   signal output sum;
   signal output carry;
   
   signal output sum_1;
   signal output carry_1;
   
   signal output sum_2;
   signal output carry_2;
   
   //(sum, carry) <== ModSum(n)(Bits2Num(n)(Num2Bits(n)(a)), Bits2Num(n)(Num2Bits(n)(b)));
   //(sum_1, carry_1) <== ModSub(n)(Bits2Num(n)(Num2Bits(n)(a)), Bits2Num(n)(Num2Bits(n)(b)));
   //(sum_2, carry_2) <== ModSubThree(n)(Bits2Num(n)(Num2Bits(n)(a)), Bits2Num(n)(Num2Bits(n)(b)), Bits2Num(n)(Num2Bits(n)(c)));
   
   signal output sum_3;
   signal output carry_3;
   //(sum_3, carry_3) <== ModSumThree(n)(Bits2Num(n)(Num2Bits(n)(a)), Bits2Num(n)(Num2Bits(n)(b)), Bits2Num(n)(Num2Bits(n)(c)));
   

   signal output sum_4;
   signal output carry_4;
   //(sum_4, carry_4) <== ModSumFour(n)(Bits2Num(n)(Num2Bits(n)(a)), Bits2Num(n)(Num2Bits(n)(b)), Bits2Num(n)(Num2Bits(n)(c)), Bits2Num(n)(Num2Bits(n)(d)));
   
   signal output sum_5;
   signal output carry_5;
   //(sum_5, carry_5) <== ModProd(2 * n)(Bits2Num(n)(Num2Bits(n)(a)), Bits2Num(n)(Num2Bits(n)(b)));
   
   signal output out_1;
   signal output out_2;
   
   //(out_1, out_2) <== Split(n-2, 2)(Bits2Num(n)(Num2Bits(n)(a)));
   
   signal output out_3;
   signal output out_4;
   signal output out_5;
   //(out_3, out_4, out_5) <== SplitThree(n-2, 1, 1)(Bits2Num(n)(Num2Bits(n)(a)));
   
   
   signal aux_a[k];
   signal aux_b[k];
   signal aux_c[k];
   signal output out6[k+1];
   
   for(var i = 0; i < k; i++){
   	aux_a[i] <== Bits2Num(n)(Num2Bits(n)(a));
   	aux_b[i] <== Bits2Num(n)(Num2Bits(n)(b));
   	aux_c[i] <== Bits2Num(n)(Num2Bits(n)(c));
   }
   
   //out6 <== BigAdd(n, k)(aux_a, aux_b);
 
   signal output out7[2 * k - 1];
   
   //out7 <== BigMultNoCarry(n, k, k)(aux_a, aux_b);
   
   
   signal output out8[k+1];
   //out8 <== LongToShortNoEndCarry(n, k)(aux_a);
   
   signal output out9[2 * k];
   //out9 <== BigMult(n, k)(aux_a, aux_b);
   
   //signal output out10 <== BigLessThan(n, k)(aux_a, aux_b);
   
   //signal output out11 <== BigIsEqual(k)([aux_a, aux_b]);
   
   signal aux_2a[2*k];
   for(var i = 0; i < k; i++){
   	aux_2a[i] <== Bits2Num(n)(Num2Bits(n)(a));
   	aux_2a[k + i] <== Bits2Num(n)(Num2Bits(n)(b));
   }
   signal output out12[k+1];
   signal output out13[k];
   
   component bm = BigMod(n, k);
   //(out12, out13) <== BigMod(n, k)(aux_2a, aux_b);
   
   signal output out14[k];
   signal output out15;
   //(out14, out15) <== BigSub(n, k)(aux_a, aux_b);
   
   //signal output out16[k] <== BigSubModP(n, k)(aux_a, aux_b, aux_c);
   
   //signal output out17[k] <== BigMultModP(n, k)(aux_a, aux_b, aux_c);
   
   //signal output out18[k] <== BigModInv(n, k)(aux_a, aux_b);
   
   signal {maxbit_abs} auxn[2];
   auxn.maxbit_abs = 2;
   auxn <== [a, a];
   CheckCarryToZero(2, 3, 2)(auxn);

}



// addition mod 2**n with carry bit
template ModSum(n) {
    
    signal input {maxbit} a;
    signal input {maxbit} b;
    signal output {maxbit} sum;
    signal output {maxbit, binary} carry;
    
    assert(n >= a.maxbit);
    assert(n >= b.maxbit);
    assert(n <= 252);

    component n2b = Num2Bits(n + 1);
    n2b.in <== a + b;
    carry.maxbit = 1;
    carry <== n2b.out[n];
    sum.maxbit = n;
    sum <== a + b - carry * (1 << n);
}


// a - b
template ModSub(n) {

    signal input {maxbit} a;
    signal input {maxbit} b;
    signal output {maxbit} out;
    signal output {maxbit, binary} borrow;
    
    assert(n >= a.maxbit);
    assert(n >= b.maxbit);
    assert(n <= 252);
    
    component lt = LessThanBounded();
    lt.in[0] <== UpdateMaxbitTag(n)(a);
    lt.in[1] <==  UpdateMaxbitTag(n)(b);
    
    borrow.maxbit = 1;
    borrow <== lt.out;
    out.maxbit = n;
    out <== borrow * (1 << n) + a - b;
}

// a - b - c
// assume a - b - c + 2**n >= 0
template ModSubThree(n) {

    signal input {maxbit} a;
    signal input {maxbit} b;
    signal input {maxbit} c;
    
    assert(n >= a.maxbit);
    assert(n >= b.maxbit);
    assert(n >= c.maxbit);
    assert(n+2 <= 253);
    
    
    // in this case we can assume that a - b - c + 2**n >= 0
    if(2 ** n >=  2 ** b.maxbit + 2 ** c.maxbit - 2){
    
         // no need of extra checks
    
    } else{
    
        // if not we check this property
        component lt_aux = LessEqThan(n + 1);
        lt_aux.in[0] <== b + c;
        lt_aux.in[1] <== a + 2 ** n;
        lt_aux.out === 1;
    
    }
    
    
    signal output {maxbit} out;
    signal output {maxbit, binary} borrow;
    signal {maxbit} b_plus_c;
    b_plus_c.maxbit = n + 1;
    b_plus_c <== b + c;
    
    component lt = LessThan(n + 1);
    lt.in[0] <== UpdateMaxbitTag(n + 1)(a);
    lt.in[1] <== b_plus_c;
    borrow.maxbit = 1;
    borrow <== lt.out;
    out.maxbit = n; 
    out <== borrow * (1 << n) + a - b_plus_c;
}

template ModSumThree(n) {

    signal input {maxbit} a;
    signal input {maxbit} b;
    signal input {maxbit} c;
    signal output {maxbit} sum;
    signal output {maxbit} carry;
    
    assert(n >= a.maxbit);
    assert(n >= b.maxbit);
    assert(n >= c.maxbit);
    assert(n+2 <= 253);

    component n2b = Num2Bits(n + 2);
    n2b.in <== a + b + c;
    carry.maxbit = 2;
    carry <== n2b.out[n] + 2 * n2b.out[n + 1];
    sum.maxbit = n;
    sum <== a + b + c - carry * (1 << n);
}

template ModSumFour(n) {

    signal input {maxbit} a;
    signal input {maxbit} b;
    signal input {maxbit} c;
    signal input {maxbit} d;
    signal output {maxbit} sum;
    signal output {maxbit} carry;
    
    assert(n >= a.maxbit);
    assert(n >= b.maxbit);
    assert(n >= c.maxbit);
    assert(n >= d.maxbit);
    assert(n+2 <= 253);

    component n2b = Num2Bits(n + 2);
    n2b.in <== a + b + c + d;
    carry.maxbit = 2;
    carry <== n2b.out[n] + 2 * n2b.out[n + 1];
    sum.maxbit = n;
    sum <== a + b + c + d - carry * (1 << n);
}


// product mod 2**n with carry
template ModProd(n) {
    assert(n <= 126);
    signal input {maxbit} a;
    signal input {maxbit} b;
    signal output {maxbit} prod;
    signal output {maxbit} carry;
    
    prod.maxbit = n;
    carry.maxbit = n;
    
    assert(2 * n >= a.maxbit + b.maxbit);
    
    component n2b = Num2Bits(2 * n);
    n2b.in <== a * b;

    component b2n1 = Bits2Num(n);
    component b2n2 = Bits2Num(n);
    var i;
    for (i = 0; i < n; i++) {
        b2n1.in[i] <== n2b.out[i];
        b2n2.in[i] <== n2b.out[i + n];
    }
    prod <== b2n1.out;
    carry <== b2n2.out;
}


// split a n + m bit input into two outputs
template Split(n, m) {
    assert(n <= 126);
    signal input {maxbit} in;
    signal output {maxbit} small;
    signal output {maxbit} big;
    
    assert(in.maxbit <= n + m);
    small.maxbit = n;
    big.maxbit = m;

    small <-- in % (1 << n);
    big <-- in \ (1 << n);

    component n2b_small = Num2Bits(n);
    n2b_small.in <== small;
    component n2b_big = Num2Bits(m);
    n2b_big.in <== big;

    in === small + big * (1 << n);
}

// split a n + m + k bit input into three outputs
template SplitThree(n, m, k) {
    assert(n <= 126);
    signal input {maxbit} in;
    signal output {maxbit} small;
    signal output {maxbit} medium;
    signal output {maxbit} big;
    
    assert(in.maxbit <= n + m + k);
    small.maxbit = n;
    medium.maxbit = m;
    big.maxbit = k;
    

    small <-- in % (1 << n);
    medium <-- (in \ (1 << n)) % (1 << m);
    big <-- in \ (1 << n + m);

    component n2b_small = Num2Bits(n);
    n2b_small.in <== small;
    component n2b_medium = Num2Bits(m);
    n2b_medium.in <== medium;
    component n2b_big = Num2Bits(k);
    n2b_big.in <== big;

    in === small + medium * (1 << n) + big * (1 << n + m);
}

// a[i], b[i] in 0... 2**n-1
// represent a = a[0] + a[1] * 2**n + .. + a[k - 1] * 2**(n * k)
template BigAdd(n, k) {
    assert(n <= 252);
    signal input {maxbit} a[k];
    signal input {maxbit} b[k];
    signal output {maxbit} out[k + 1];

    assert(a.maxbit <= n);
    assert(b.maxbit <= n);
    
    out.maxbit = n;

    component unit0 = ModSum(n);
    unit0.a <== a[0];
    unit0.b <== b[0];
    out[0] <== unit0.sum;

    component unit[k - 1];
    for (var i = 1; i < k; i++) {
        unit[i - 1] = ModSumThree(n);
        unit[i - 1].a <== a[i];
        unit[i - 1].b <== b[i];
        if (i == 1) {
            unit[i - 1].c <== unit0.carry;
        } else {
            unit[i - 1].c <== unit[i - 2].carry;
        }
        out[i] <== unit[i - 1].sum;
    }
    out[k] <== unit[k - 2].carry;
}



// a and b have n-bit registers
// a has ka registers, each with NONNEGATIVE ma-bit values (ma can be > n)
// b has kb registers, each with NONNEGATIVE mb-bit values (mb can be > n)
// out has ka + kb - 1 registers, each with (ma + mb + ceil(log(max(ka, kb))))-bit values
template BigMultNoCarry(n, ka, kb) {
    signal input {maxbit} a[ka];
    signal input {maxbit} b[kb];
    signal output {maxbit} out[ka + kb - 1];
      
      
    assert(a.maxbit <= n);
    assert(b.maxbit <= n);
    out.maxbit = a.maxbit + b.maxbit + log_ceil(max2(ka, kb));
    assert(out.maxbit <= 253);

    var prod_val[ka + kb - 1];
    for (var i = 0; i < ka + kb - 1; i++) {
        prod_val[i] = 0;
    }
    for (var i = 0; i < ka; i++) {
        for (var j = 0; j < kb; j++) {
            prod_val[i + j] += a[i] * b[j];
        }
    }
    for (var i = 0; i < ka + kb - 1; i++) {
        out[i] <-- prod_val[i];
    }
    

    var a_poly[ka + kb - 1];
    var b_poly[ka + kb - 1];
    var out_poly[ka + kb - 1];
    for (var i = 0; i < ka + kb - 1; i++) {
        out_poly[i] = 0;
        a_poly[i] = 0;
        b_poly[i] = 0;
        for (var j = 0; j < ka + kb - 1; j++) {
            out_poly[i] = out_poly[i] + out[j] * (i ** j);
        }
        for (var j = 0; j < ka; j++) {
            a_poly[i] = a_poly[i] + a[j] * (i ** j);
        }
        for (var j = 0; j < kb; j++) {
            b_poly[i] = b_poly[i] + b[j] * (i ** j);
        }
    }
    
    // Con lo de clusterizar deberia ir bien
    for (var i = 0; i < ka + kb - 1; i++) {
        out_poly[i] === a_poly[i] * b_poly[i];
    }
}


// in[i] contains longs
// out[i] contains shorts
template LongToShortNoEndCarry(n, k) {
    assert(n <= 126);
    signal input {maxbit} in[k];
    signal output {maxbit} out[k+1];
    
    assert(in.maxbit <= 3 * n);
    out.maxbit = n;

    var split[k][3];
    for (var i = 0; i < k; i++) {
        split[i] = SplitThreeFn(in[i], n, n, n);
    }

    var carry[k];
    carry[0] = 0;
    out[0] <-- split[0][0];
    if (k == 1) {
	out[1] <-- split[0][1];
    }
    if (k > 1) {
        var sumAndCarry[2] = SplitFn(split[0][1] + split[1][0], n, n);
        out[1] <-- sumAndCarry[0];
        carry[1] = sumAndCarry[1];
    }
    if (k == 2) {
	out[2] <-- split[1][1] + split[0][2] + carry[1];
    }
    if (k > 2) {
        for (var i = 2; i < k; i++) {
            var sumAndCarry[2] = SplitFn(split[i][0] + split[i-1][1] + split[i-2][2] + carry[i-1], n, n);
            out[i] <-- sumAndCarry[0];
            carry[i] = sumAndCarry[1];
        }
        out[k] <-- split[k-1][1] + split[k-2][2] + carry[k-1];
    }

    component outRangeChecks[k+1];
    for (var i = 0; i < k+1; i++) {
        outRangeChecks[i] = Num2Bits(n);
        outRangeChecks[i].in <== out[i];
    }

    signal {maxbit} runningCarry[k];
    runningCarry.maxbit = n + log_ceil(k);
    
    component runningCarryRangeChecks[k];
    runningCarry[0] <-- (in[0] - out[0]) / (1 << n);
    runningCarryRangeChecks[0] = Num2Bits(n + log_ceil(k));
    runningCarryRangeChecks[0].in <== runningCarry[0];
    runningCarry[0] * (1 << n) === in[0] - out[0];
    for (var i = 1; i < k; i++) {
        runningCarry[i] <-- (in[i] - out[i] + runningCarry[i-1]) / (1 << n);
        runningCarryRangeChecks[i] = Num2Bits(n + log_ceil(k));
        runningCarryRangeChecks[i].in <== runningCarry[i];
        runningCarry[i] * (1 << n) === in[i] - out[i] + runningCarry[i-1];
    }
    runningCarry[k-1] === out[k];
}


template BigMult(n, k) {
    signal input {maxbit} a[k];
    signal input {maxbit} b[k];
    signal output {maxbit} out[2 * k];
    
    assert(a.maxbit <= n);
    assert(b.maxbit <= n);
    out.maxbit = n;

    component mult = BigMultNoCarry(n, k, k);
    for (var i = 0; i < k; i++) {
        mult.a[i] <== a[i];
        mult.b[i] <== b[i];
    }

    // no carry is possible in the highest order register
    component longshort = LongToShortNoEndCarry(n, 2 * k - 1);
    for (var i = 0; i < 2 * k - 1; i++) {
        longshort.in[i] <== mult.out[i];
    }
    for (var i = 0; i < 2 * k; i++) {
        out[i] <== longshort.out[i];
    }
}


template BigLessThan(n, k){
    signal input {maxbit} a[k];
    signal input {maxbit} b[k];
    signal output {binary} out;
    
    assert(a.maxbit <= n);
    assert(b.maxbit <= n);

    component lt[k];
    component eq[k];
    for (var i = 0; i < k; i++) {
        lt[i] = LessThanBounded();
        lt[i].in[0] <== UpdateMaxbitTag(n)(a[i]);
        lt[i].in[1] <== UpdateMaxbitTag(n)(b[i]);
        eq[i] = IsEqual();
        eq[i].in[0] <== a[i];
        eq[i].in[1] <== b[i];
    }

    // ors[i] holds (lt[k - 1] || (eq[k - 1] && lt[k - 2]) .. || (eq[k - 1] && .. && lt[i]))
    // ands[i] holds (eq[k - 1] && .. && lt[i])
    // eq_ands[i] holds (eq[k - 1] && .. && eq[i])
    component ors[k - 1];
    component ands[k - 1];
    component eq_ands[k - 1];
    for (var i = k - 2; i >= 0; i--) {
        ands[i] = AND();
        eq_ands[i] = AND();
        ors[i] = OR();

        if (i == k - 2) {
           ands[i].a <== eq[k - 1].out;
           ands[i].b <== lt[k - 2].out;
           eq_ands[i].a <== eq[k - 1].out;
           eq_ands[i].b <== eq[k - 2].out;
           ors[i].a <== lt[k - 1].out;
           ors[i].b <== ands[i].out;
        } else {
           ands[i].a <== eq_ands[i + 1].out;
           ands[i].b <== lt[i].out;
           eq_ands[i].a <== eq_ands[i + 1].out;
           eq_ands[i].b <== eq[i].out;
           ors[i].a <== ors[i + 1].out;
           ors[i].b <== ands[i].out;
        }
     }
     out <== ors[0].out;
}


template BigIsEqual(k){
    signal input in[2][k];
    signal output {binary} out;
    component isEqual[k+1];
    var sum = 0;
    for(var i = 0; i < k; i++){
        isEqual[i] = IsEqual();
        isEqual[i].in[0] <== in[0][i];
        isEqual[i].in[1] <== in[1][i];
        sum = sum + isEqual[i].out;
    }

    isEqual[k] = IsEqual();
    isEqual[k].in[0] <== sum;
    isEqual[k].in[1] <== k;
    out <== isEqual[k].out;
}

// leading register of b should be non-zero
template BigMod(n, k) {
    assert(n <= 126);
    signal  input {maxbit} a[2 * k];
    signal input {maxbit} b[k];

    signal output {maxbit} div[k + 1];
    div.maxbit = n;
    signal output {maxbit} mod[k];
    mod.maxbit = n;

    var longdiv[2][100] = long_div(n, k, k, a, b);
    for (var i = 0; i < k; i++) {
        div[i] <-- longdiv[0][i];
        mod[i] <-- longdiv[1][i];
    }
    div[k] <-- longdiv[0][k];
    
    component div_range_checks[k + 1];
    for (var i = 0; i <= k; i++) {
        div_range_checks[i] = Num2Bits(n);
        div_range_checks[i].in <== div[i];
    }
    component mod_range_checks[k];
    for (var i = 0; i < k; i++) {
        mod_range_checks[i] = Num2Bits(n);
        mod_range_checks[i].in <== mod[i];
    }
    

    component mul = BigMult(n, k + 1);
    for (var i = 0; i < k; i++) {
        mul.a[i] <== div[i];
        mul.b[i] <== b[i];
    }
    mul.a[k] <== div[k];
    signal {maxbit} aux_0;
    aux_0.maxbit = n;
    
    aux_0 <== 0;
    
    mul.b[k] <== aux_0;

    component add = BigAdd(n, 2 * k + 2);
    for (var i = 0; i < 2 * k; i++) {
        add.a[i] <== mul.out[i];
        if (i < k) {
            add.b[i] <== mod[i];
        } else {
            add.b[i] <== aux_0;
        }
    }
    add.a[2 * k] <== mul.out[2 * k];
    add.a[2 * k + 1] <== mul.out[2 * k + 1];
    add.b[2 * k] <== aux_0;
    add.b[2 * k + 1] <== aux_0;

    for (var i = 0; i < 2 * k; i++) {
        add.out[i] === a[i];
    }
    add.out[2 * k] === 0;
    add.out[2 * k + 1] === 0;
    
    component lt = BigLessThan(n, k);
    for (var i = 0; i < k; i++) {
        lt.a[i] <== mod[i];
        lt.b[i] <== b[i];
    }
    lt.out === 1;
}


// a[i], b[i] in 0... 2**n-1
// represent a = a[0] + a[1] * 2**n + .. + a[k - 1] * 2**(n * k)
// assume a >= b
template BigSub(n, k) {
    assert(n <= 252);
    signal input {maxbit} a[k];
    signal input {maxbit} b[k];
    signal output {maxbit} out[k];
    signal output {binary} underflow;

    component unit0 = ModSub(n);
    unit0.a <== a[0];
    unit0.b <== b[0];
    out[0] <== unit0.out;

    component unit[k - 1];
    for (var i = 1; i < k; i++) {
        unit[i - 1] = ModSubThree(n);
        unit[i - 1].a <== a[i];
        unit[i - 1].b <== b[i];
        if (i == 1) {
            unit[i - 1].c <== unit0.borrow;
        } else {
            unit[i - 1].c <== unit[i - 2].borrow;
        }
        out[i] <== unit[i - 1].out;
    }
    underflow <== unit[k - 2].borrow;
}


// calculates (a - b) % p, where a, b < p
// note: does not assume a >= b
template BigSubModP(n, k){
    assert(n <= 252);
    signal input {maxbit} a[k];
    signal input {maxbit} b[k];
    signal input {maxbit} p[k];
    signal output {maxbit} out[k];
    
    assert(a.maxbit <= n);
    assert(b.maxbit <= n);
    assert(p.maxbit <= n);
    out.maxbit = n;
    
    component sub = BigSub(n, k);
    for (var i = 0; i < k; i++){
        sub.a[i] <== a[i];
        sub.b[i] <== b[i];
    }
    signal {binary} flag;
    flag <== sub.underflow;
    component add = BigAdd(n, k);
    for (var i = 0; i < k; i++){
        add.a[i] <== sub.out[i];
        add.b[i] <== p[i];
    }
    signal tmp[k];
    for (var i = 0; i < k; i++){
        tmp[i] <== (1 - flag) * sub.out[i];
        out[i] <== tmp[i] + flag * add.out[i];
    }
}



template BigMultModP(n, k) {
    assert(n <= 252);
    signal input {maxbit} a[k];
    signal input {maxbit} b[k];
    signal input {maxbit} p[k];
    signal output {maxbit} out[k];
    
    assert(a.maxbit <= n);
    assert(b.maxbit <= n);
    assert(p.maxbit <= n);
    out.maxbit = n;

    component big_mult = BigMult(n, k);
    for (var i = 0; i < k; i++) {
        big_mult.a[i] <== a[i];
        big_mult.b[i] <== b[i];
    }
    component big_mod = BigMod(n, k);
    for (var i = 0; i < 2 * k; i++) {
        big_mod.a[i] <== big_mult.out[i];
    }
    for (var i = 0; i < k; i++) {
        big_mod.b[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[i] <== big_mod.mod[i];
    }
}


template BigModInv(n, k) {
    assert(n <= 252);
    signal input {maxbit} in[k];
    signal input {maxbit} p[k];
    signal output {maxbit} out[k];
    
    assert(in.maxbit <= n);
    assert(p.maxbit <= n);
    out.maxbit = n;

    // length k
    var inv[100] = mod_inv(n, k, in, p);
    for (var i = 0; i < k; i++) {
        out[i] <-- inv[i];
    }
    component range_checks[k];
    for (var i = 0; i < k; i++) {
        range_checks[i] = Num2Bits(n);
        range_checks[i].in <== out[i];
    }

    component mult = BigMult(n, k);
    for (var i = 0; i < k; i++) {
        mult.a[i] <== in[i];
        mult.b[i] <== out[i];
    }
    component mod = BigMod(n, k);
    for (var i = 0; i < 2 * k; i++) {
        mod.a[i] <== mult.out[i];
    }
    for (var i = 0; i < k; i++) {
        mod.b[i] <== p[i];
    }
    mod.mod[0] === 1;
    for (var i = 1; i < k; i++) {
        mod.mod[i] === 0;
    }
}


// in[i] contains values in the range -2^(m-1) to 2^(m-1)
// constrain that in[] as a big integer is zero
// each limbs is n bits
template CheckCarryToZero(n, m, k) {
    assert(k >= 2);
    
    var EPSILON = 3;
    
    signal input {maxbit_abs} in[k];
    
    assert(m >= in.maxbit_abs);
    
    signal {maxbit_abs} carry[k];
    carry.maxbit_abs = m - n - 1 + EPSILON;
    component carryRangeChecks[k];
    for (var i = 0; i < k-1; i++){
        carryRangeChecks[i] = Num2Bits(m + EPSILON - n); 
        if( i == 0 ){
            carry[i] <-- in[i] / (1<<n);
            in[i] === carry[i] * (1<<n);
        }
        else{
            carry[i] <-- (in[i]+carry[i-1]) / (1<<n);
            in[i] + carry[i-1] === carry[i] * (1<<n);
        }
        // checking carry is in the range of - 2^(m-n-1+eps), 2^(m+-n-1+eps)
        carryRangeChecks[i].in <== carry[i] + ( 1<< (m + EPSILON - n - 1));
    }
    in[k-1] + carry[k-2] === 0;   
}

component main = Aux(5, 2);
