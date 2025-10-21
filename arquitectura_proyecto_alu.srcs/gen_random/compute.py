import numpy as np
from decimal import Decimal, getcontext, InvalidOperation


# --- Conversión binario ↔ float ---
def bits_to_float(bits, bitsz=16):
    """
    bits: int or binary string like '010101' (no '0b' needed) or '0b...'
    bitsz: 16 or 32
    devuelve un Python float (64-bit) y también el numpy-typed float del tamaño pedido
    """
    if isinstance(bits, str):
        bstr = bits.strip()
        if bstr.startswith("0b"):
            bstr = bstr[2:]
        bits_int = int(bstr, 2)
    else:
        bits_int = int(bits)

    if bitsz == 32:
        # view uint32 -> float32
        arr = np.array([bits_int], dtype=np.uint32)
        f = arr.view(np.float32)[0]
        return float(f), f
    elif bitsz == 16:
        # numpy float16 view trick: use uint16 -> float16 via view
        arr = np.array([bits_int], dtype=np.uint16)
        f16 = arr.view(np.float16)[0]
        return float(f16), f16
    else:
        raise ValueError("bitsz must be 16 or 32")


def float_to_bits(value, bitsz=16):
    """
    value: Python float or numpy float
    devuelve string de bits con longitud bitsz ('0'/'1')
    """
    if bitsz == 32:
        f32 = np.float32(value)
        u = np.array([f32], dtype=np.float32).view(np.uint32)[0]
        return format(int(u), '032b')
    elif bitsz == 16:
        f16 = np.float16(value)
        u = np.array([f16], dtype=np.float16).view(np.uint16)[0]
        return format(int(u), '016b')
    else:
        raise ValueError("bitsz must be 16 or 32")


def calc_flags_ieee(a_bits, b_bits, op, bits=16, ext_bits=5):
    """
    Calcula resultado y flags IEEE simplificadas para half (16) o single (32) precision.

    Flags en orden: invalid, div0, ovf, unf, inx (todos 0/1)
    op: '00' add, '01' sub, '10' mul, '11' div
    """

    if bits not in (16, 32):
        raise ValueError("bits must be 16 or 32")

    # precision params
    mant_bits = 10 if bits == 16 else 23
    ftype = np.float16 if bits == 16 else np.float32

    # parse inputs -> we keep both python float (64-bit) and numpy typed float (ftype)
    a_py, a_typed = bits_to_float(a_bits, bits)
    b_py, b_typed = bits_to_float(b_bits, bits)

    # flags
    invalid = div0 = ovf = unf = inx = 0

    # Helpers for classification
    def is_nan(x): return np.isnan(x)
    def is_inf(x): return np.isinf(x)
    def sign_of(x): return 1 if np.signbit(x) else 0

    sign_a = int(a_bits[0])  # bit más significativo de 'a'
    sign_b = int(b_bits[0])  # bit más significativo de 'b'

    if op == '00':
        # si ambos operandos tienen el mismo signo, lo hereda
        # si difieren, depende de cuál magnitud sea mayor
        if sign_a == sign_b:
            sign_bit = sign_a
        else:
            # comparar magnitudes (sin incluir el bit de signo)
            mag_a = int(a_bits[1:], 2)
            mag_b = int(b_bits[1:], 2)
            sign_bit = sign_a if mag_a >= mag_b else sign_b

    elif op == '01':
        # resta a - b  → el signo depende de cuál es mayor en magnitud
        mag_a = int(a_bits[1:], 2)
        mag_b = int(b_bits[1:], 2)
        if mag_a >= mag_b:
            sign_bit = sign_a
        else:
            # si el resultado se “voltea”, invierte el signo de a
            sign_bit = 1 - sign_a

    elif op == '10':
        # multiplicación → XOR de los signos
        sign_bit = sign_a ^ sign_b

    elif op == '11':
        # división → XOR de los signos
        sign_bit = sign_a ^ sign_b


    # --- Early special cases using operands ---
    # If either operand is NaN -> invalid
    if is_nan(a_typed) or is_nan(b_typed):
        invalid = 1
        # Result must be NaN (propagate)
        r_typed = ftype(np.nan)
        bits_result = float_to_bits(np.nan, bits)
        flags = f"{invalid}{div0}{ovf}{unf}{inx}"
        return bits_result, flags

    # If operation is division and divisor is zero:
    if op == '11' and (b_py == 0.0):
        # if numerator is also zero -> invalid (0/0)
        if a_py == 0.0:
            invalid = 1
            r_typed = ftype(np.nan)
            bits_result = float_to_bits(np.nan, bits)
            return bits_result, f"{invalid}{div0}{ovf}{unf}{inx}"
        # if numerator is NaN handled above; else finite / 0 => divide-by-zero
        div0 = 1
        # result is signed infinity
        sign = sign_of(a_typed) ^ sign_of(b_typed)
        r_typed = ftype(np.inf if sign == 0 else -np.inf)
        # We will still compute inexact later but for div0 set inx=1 (typical)
        inx = 1
        bits_result = float_to_bits(r_typed, bits)
        return bits_result, f"{invalid}{div0}{ovf}{unf}{inx}"

    # If operands are infinities, check invalid cases (inf/inf -> invalid, inf - inf -> invalid, etc.)
    # For operations that are undefined: inf/inf, inf - inf, 0*inf? (0*inf -> invalid)
    if op == '11':  # division
        if is_inf(a_typed) and is_inf(b_typed):
            invalid = 1
            r_typed = ftype(np.nan)
            bits_result = float_to_bits(np.nan, bits)
            return bits_result, f"{invalid}{div0}{ovf}{unf}{inx}"
    if op == '00' or op == '01':  # add or sub
        # inf + -inf or inf - inf depending on signs -> invalid
        if is_inf(a_typed) and is_inf(b_typed):
            # if signs are opposite for add -> invalid (inf + -inf)
            if op == '00' and (sign_of(a_typed) != sign_of(b_typed)):
                invalid = 1
                r_typed = ftype(np.nan)
                return float_to_bits(np.nan, bits), f"{invalid}{div0}{ovf}{unf}{inx}"
            # if op is sub and signs same -> invalid (inf - inf)
            if op == '01' and (sign_of(a_typed) == sign_of(b_typed)):
                invalid = 1
                r_typed = ftype(np.nan)
                return float_to_bits(np.nan, bits), f"{invalid}{div0}{ovf}{unf}{inx}"
    if op == '10':  # multiplication
        # 0 * inf or inf * 0 -> invalid
        if (a_py == 0.0 and is_inf(b_typed)) or (b_py == 0.0 and is_inf(a_typed)):
            invalid = 1
            return float_to_bits(np.nan, bits), f"{invalid}{div0}{ovf}{unf}{inx}"

    # --- Compute exact result using Decimal (high precision) ---
    # set context precision large enough: mant_bits + ext_bits + margin
    prec = (mant_bits + ext_bits) * 3 + 50
    getcontext().prec = max(prec, 60)

    # Convert operands to Decimal carefully
    # Decimal.from_float keeps binary float exact decimal expansion, that's OK because we want the exact real of
    # the original float64 value. We use a_py (python float) as the 'true' input value (since inputs were bits of target format,
    # but converting to python float may already widened them; it's acceptable for the heuristic).
    try:
        dec_a = Decimal(a_py)
        dec_b = Decimal(b_py)
    except InvalidOperation:
        # fallback: use string conversion
        dec_a = Decimal(str(a_py))
        dec_b = Decimal(str(b_py))

    op_map = {'00': 'add', '01': 'sub', '10': 'mul', '11': 'div'}

    try:
        if op == '00':
            dec_exact = dec_a + dec_b
        elif op == '01':
            dec_exact = dec_a - dec_b
        elif op == '10':
            dec_exact = dec_a * dec_b
        elif op == '11':
            # division by zero handled earlier
            dec_exact = dec_a / dec_b
        else:
            raise ValueError("op must be '00','01','10' or '11'")
    except InvalidOperation:
        # e.g. decimal division invalid -> treat as NaN/invalid
        invalid = 1
        return float_to_bits(np.nan, bits), f"{invalid}{div0}{ovf}{unf}{inx}"

    # --- Compute the rounded result in the target ftype using numpy (this simulates hardware rounding) ---
    if op == '00':
        r_np = a_typed + b_typed
    elif op == '01':
        r_np = a_typed - b_typed
    elif op == '10':
        r_np = a_typed * b_typed
    elif op == '11':
        r_np = a_typed / b_typed
    else:
        r_np = ftype(np.nan)

    # convert typed result to python float for Decimal conversion
    r_py = float(r_np)

    # --- Overflow / Underflow detection based on exact result and representable range ---
    # get max and tiny of ftype in python float
    f_info = np.finfo(ftype)
    f_max = Decimal(str(f_info.max))
    f_tiny = Decimal(str(f_info.tiny))  # smallest positive normal

    # If exact result is NaN or Infinity from Decimal perspective (e.g. division overflow), handle:
    # Decimal.is_finite available
    if dec_exact.is_nan():
        invalid = 1
        return float_to_bits(np.nan, bits), f"{invalid}{div0}{ovf}{unf}{inx}"

    # Overflow: exact magnitude > max representable
    if dec_exact.copy_abs() > f_max:
        ovf = 1
        inx = 1
        # set result to signed infinity
        sign = 1 if (dec_exact < 0) else 0
        bits_result = float_to_bits(r_np, bits)
        return bits_result, f"{invalid}{div0}{ovf}{unf}{inx}"

    # Underflow: exact non-zero magnitude < tiny -> result may become zero or denormal.
    # We treat as underflow if exact_abs < tiny and rounded-to-ftype is zero (or denorm handled as underflow if flush-to-zero).
    if dec_exact.copy_abs() != Decimal(0) and dec_exact.copy_abs() < f_tiny:
        # In IEEE, if goes to subnormal it's considered underflow if result is rounded to a subnormal with loss of precision.
        # We'll set unf = 1 if result after rounding is zero or a subnormal that lost precision.
        # Check typed result representation:
        if r_np == 0.0:
            unf = 1
            inx = 1
            bits_result = float_to_bits(r_np, bits)
            return bits_result, f"{invalid}{div0}{ovf}{unf}{inx}"
        else:
            # r_np is subnormal or small non-zero; mark underflow and possibly inexact
            # We'll check inexactness below anyway
            unf = 1

    # --- Inexact detection ---
    # Compare dec_exact with decimal of the rounded result r_np; if different => inexact.
    # Note: We consider rounding-to-nearest-even via numpy conversion; converting r_np back to Decimal should reflect
    # the rounded value.
    try:
        dec_rounded = Decimal(r_py)
    except InvalidOperation:
        dec_rounded = Decimal(str(r_py))

    if dec_exact != dec_rounded:
        # For division by zero or NaN we handled earlier; here mark inexact
        inx = 1

    # Extra rules per user for mul/div: examine bits immediately after mantissa (ext_bits)
    # We refine inx by extracting binary fraction of exact result and seeing lower ext_bits beyond mantissa.
    # We'll only do this if operation is mul/div and dec_exact is finite and not zero and not already inexact (but if already inx we keep it).
    if op in ('10', '11') and dec_exact.copy_abs() != Decimal(0) and dec_exact.is_finite():
        # Represent dec_exact in binary: compute integer k such that 1 <= mantissa < 2 when scaled by 2^k
        # We'll use repeated shifting: dec_exact = m * 2^e with 1<=m<2
        # Compute binary exponent e ~= floor(log2(|dec_exact|))
        # Use natural log via float as heuristic (safe because we only need exponent estimate)
        approx_e = int(np.floor(np.log2(float(dec_exact.copy_abs())))) if float(dec_exact.copy_abs()) > 0.0 else 0
        # scale to get fractional mantissa of (mant_bits + ext_bits + 4) bits precision
        total_bits_check = mant_bits + ext_bits + 6
        scale = Decimal(2) ** (total_bits_check - approx_e)
        scaled = (dec_exact.copy_abs() * scale)
        # Take integer part
        try:
            scaled_int = int(scaled.to_integral_value(rounding="ROUND_FLOOR"))
        except InvalidOperation:
            scaled_int = int(float(scaled))
        # Now the lower ext_bits beyond mantissa are the bits at positions 0..(ext_bits-1) of scaled_int after shifting out mant_bits.
        lower_mask = (1 << ext_bits) - 1
        # shift right the integer so that LSB corresponds to the ext_bits zone
        shifted = scaled_int >> (total_bits_check - (mant_bits + ext_bits))
        extra_bits_value = shifted & lower_mask
        if extra_bits_value != 0:
            inx = 1

    # For add/sub: The Decimal compare above already caught any difference due to lost bits during alignment and normalization.
    # But we can also apply your rule: "if during normalization at least one lost bit among the mantissa was 1".
    # The Decimal comparison is a faithful indicator; keep it.

    # --- Compose final numpy-typed result (make sure sign for zero is preserved) ---
    # If not already set to special values, use r_np (the numpy-typed calculation)
    # (We already handled overflow -> inf and div0 -> inf earlier)
    final_typed = r_np

    # If final typed result is NaN and we haven't marked invalid, mark invalid
    if is_nan(final_typed):
        invalid = 1

    # If final is inf and not flagged ovf yet, set ovf
    if is_inf(final_typed):
        ovf = 1

    # If final is zero but dec_exact != 0 and not flagged unf yet, set unf
    if float(final_typed) == 0.0 and dec_exact.copy_abs() != Decimal(0) and dec_exact.copy_abs() < f_tiny:
        unf = 1
        inx = 1


    if invalid:
        # NaN: exponent all 1s, mantissa MSB=1
        if bits == 16:
            bits_result = f"{sign_bit}111111000000000"
            bits_result = bits_result.ljust(16, '0')
        else:  # 32-bit
            bits_result = f"{sign_bit}1111111110000000000000000000000"
            bits_result = bits_result.ljust(32, '0')
    elif ovf:
        # ±Infinity
        if bits == 16:
            bits_result = f"{sign_bit}1111100000000000"
        else:
            bits_result = f"{sign_bit}11111111000000000000000000000000"
    elif unf:
        # ±Zero
        if bits == 16:
            bits_result = f"{sign_bit}0000000000000000"
        else:
            bits_result = f"{sign_bit}00000000000000000000000000000000"
    else:
        # Valor normal, solo convertir a bits IEEE
        bits_result = float_to_bits(final_typed, bits)

    flags = f"{int(invalid)}{int(div0)}{int(ovf)}{int(unf)}{int(inx)}"
    return bits_result, flags


# --- Generador de archivo de salida ---
def generar_output(input_file='tb_vectors_input.mem', output_file='tb_expected.mem', bits=16):
    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        for i, line in enumerate(fin):
            parts = line.strip().split()
            if len(parts) != 3:
                continue

            a_bin, b_bin, op = parts
            r, flags = calc_flags_ieee(a_bin, b_bin, op, bits=len(a_bin))
            fout.write(f"{r} {flags}\n")

    print(f"✅ Archivo {output_file} generado con resultado y flags ({bits} bits)")



if __name__ == "__main__":
    generar_output(bits=16, input_file="./data/tb_vectors_16_100000.mem", output_file="./output/tb_expected_output16_100000.mem")
    generar_output(bits=32, input_file="./data/tb_vectors_32_100000.mem", output_file="./output/tb_expected_output32_100000.mem")
