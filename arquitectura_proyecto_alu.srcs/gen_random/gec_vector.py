import struct
import random
import numpy as np

# Conversión float → binario IEEE (16 o 32 bits)
def float_to_bin(f, bits=16):
    if bits == 32:
        try:
            b = struct.pack('>f', f)
            i = struct.unpack('>I', b)[0]
            return format(i, '032b')
        except OverflowError:
            # Si es demasiado grande, se fuerza a ±Inf
            if f > 0:
                return "01111111100000000000000000000000"
            else:
                return "11111111100000000000000000000000"
    elif bits == 16:
        hf = np.float16(f)
        i = struct.unpack('>H', hf.tobytes())[0]
        return format(i, '016b')
    else:
        raise ValueError("Solo se permiten 16 o 32 bits")

# Generación de operandos con porcentaje de casos especiales
def gen_operand(bits=16):
    p = random.random() * 100  # porcentaje
    if p < 1.25:
        # 1.25% NaN
        if bits == 32:
            sign = random.choice([0, 1])
            exp = '1' * 8
            mant = format(random.randint(1, (1 << 23) - 1), '023b')
            return f"{sign}{exp}{mant}"
        else:
            sign = random.choice([0, 1])
            exp = '1' * 5
            mant = format(random.randint(1, (1 << 10) - 1), '010b')
            return f"{sign}{exp}{mant}"

    elif p < 2.5:
        # 1.25% exactos 0
        return "0" * bits

    elif p < 7.5:
        # 5% underflow / valores denormales pequeños
        val = random.uniform(-1e-6, 1e-6)
        return float_to_bin(val, bits)

    elif p < 12.5:
        # 5% overflow / ±Inf o cercanos
        if random.random() < 0.5:
            val = float('inf')
        else:
            # Limitar al rango representable
            if bits == 32:
                val = random.uniform(3e38, 3.4e38)
            else:
                val = random.uniform(6e4, 6.55e4)
        if random.random() < 0.5:
            val = -val
        return float_to_bin(val, bits)

    else:
        # 87.5% valores normales entre -10 y 10
        val = random.uniform(-10, 10)
        return float_to_bin(val, bits)

# Genera operación aleatoria (sin resultado)
def gen_vector(bits=16):
    ops = {
        'add': '00',
        'sub': '01',
        'mul': '10',
        'div': '11'
    }
    op_name = random.choice(list(ops.keys()))
    op_code = ops[op_name]

    # Generar operandos (en binario)
    a_bin = gen_operand(bits)
    b_bin = gen_operand(bits)

    return a_bin, b_bin, op_code

# Generar archivo de vectores
def generar_vectores(n=1000, bits=16, archivo='vectors.mem'):
    with open(archivo, 'w') as f:
        for _ in range(n):
            a, b, op = gen_vector(bits)
            f.write(f"{a} {b} {op}\n")
    print(f"✅ Archivo {archivo} generado con {n} vectores de {bits} bits (sin resultado)")


if __name__ == "__main__":
    generar_vectores(100000, bits=16, archivo='./data/tb_vectors_16_100000.mem')
    generar_vectores(100000, bits=32, archivo='./data/tb_vectors_32_100000.mem')
