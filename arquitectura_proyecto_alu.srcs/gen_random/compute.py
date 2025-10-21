import struct
import math
import numpy as np


# Conversión binario <-> float 
def bin_to_float(bstr, bits=16):
    if bits == 32:
        i = int(bstr, 2)
        return struct.unpack('>f', struct.pack('>I', i))[0]
    elif bits == 16:
        i = int(bstr, 2)
        return np.frombuffer(struct.pack('>H', i), dtype=np.float16)[0].item()
    else:
        raise ValueError("Solo se permiten 16 o 32 bits")


def float_to_bin(f, bits=16):
    if math.isnan(f):
        # Convertir NaN a +inf
        f = float('inf')
    if math.isinf(f):
        sign = '1' if math.copysign(1.0, f) < 0 else '0'
        if bits == 16:
            return sign + "1111100000000000"
        else:
            return sign + "11111111000000000000000000000000"
    if bits == 32:
        b = struct.pack('>f', f)
        i = struct.unpack('>I', b)[0]
        return format(i, '032b')
    elif bits == 16:
        hf = np.float16(f)
        i = struct.unpack('>H', hf.tobytes())[0]
        return format(i, '016b')
    else:
        raise ValueError("Solo se permiten 16 o 32 bits")


# --- Cálculo de flags y resultado ---
def calc_flags(a, b, op):

    invalid = div0 = ovf = unf = inx = 0
    r = 0.0

    # NaN → +inf
    if math.isnan(a) or math.isnan(b):
        r = float('inf')
        invalid = 1
        return r, f"{invalid}{div0}{ovf}{unf}{inx}"

    # Infinito + -Infinito → +inf (antes era NaN)
    if math.isinf(a) and math.isinf(b):
        if op in ['00', '01']:  # add o sub
            r = float('inf')
            invalid = 1
            return r, f"{invalid}{div0}{ovf}{unf}{inx}"

    # División por cero
    if op == '11' and b == 0.0:
        div0 = 1
        r = float('inf')
        inx = 1
        return r, f"{invalid}{div0}{ovf}{unf}{inx}"

    # Calcular operación
    try:
        if op == '00':  # add
            r = a + b
        elif op == '01':  # sub
            r = a - b
        elif op == '10':  # mul
            r = a * b
        elif op == '11':  # div
            r = a / b
    except Exception:
        r = float('inf')
        invalid = 1
        return r, f"{invalid}{div0}{ovf}{unf}{inx}"

    # Flags por magnitud
    if math.isinf(r) or abs(r) > np.finfo(np.float16).max:
        ovf = 1
        inx = 1
        r = float('inf')
    elif 0 < abs(r) < np.finfo(np.float16).tiny:
        unf = 1
        inx = 1
        r = 0.0  # underflow -> full 0

    return r, f"{invalid}{div0}{ovf}{unf}{inx}"


# Generador de archivo de salida 
def generar_output(input_file='tb_vectors_input.mem', output_file='tb_expected.mem', bits=16):
    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        for line in fin:
            parts = line.strip().split()
            if len(parts) != 3:
                continue

            a_bin, b_bin, op = parts
            a = bin_to_float(a_bin, bits)
            b = bin_to_float(b_bin, bits)

            r, flags = calc_flags(a, b, op)
            r_bin = float_to_bin(r, bits)

            fout.write(f"{r_bin} {flags}\n")

    print(f"✅ Archivo {output_file} generado con resultado y flags ({bits} bits)")


if __name__ == "__main__":
    generar_output(bits=16, input_file="./data/tb_vectors_16.mem", output_file="./output/tb_expected_output16.mem")
    generar_output(bits=32, input_file="./data/tb_vectors_32.mem", output_file="./output/tb_expected_output32.mem")
