using BenchmarkTools

function bits_to_digits(bits::Int)
    return floor(bits*log10(2))
end

function digits_to_bits(digits::Int)
    return ceil(Int, digits/log10(2))
end

bits_to_digits(53)

digits_to_bits(35)

counter = 0
xmin4 = BigFloat("0.2503006273651145643691")
xmax4 = BigFloat("0.2503006273651201870891")
xc = (xmax4+xmin4)/2
ymin4 = BigFloat("0.0000077612880963380370")
ymax4 = BigFloat("0.0000077612881005550770")
yc = (ymax4+ymin4)/2

#%%
function mandelbrotBoundCheck(
    cr::T,
    ci::T,
    maxIter::Int = 1000,
) where {T<:AbstractFloat}
    zr = zero(T)
    zi = zero(T)
    z = complex(zr, zi)
    c = complex(cr, ci)
    result = 0
    A = one(c)
    B = zero(c)
    for i = 1:maxIter
        if abs(z) > 2
            result = i
            break
        end
        z = z^2 + c
        B = 2*z*B + A^2
        A = 2*z*A + 1
    end
    return result, real(z), imag(z)
end

#%%
bits=digits_to_bits(2+ceil(Int,-log10((ymax4-ymin4)/1080)))
bits=1000
@btime setprecision($bits) do
    mandelbrotBoundCheck(xc, yc, 50000)
end

@btime mandelbrotBoundCheck(xc, yc, 5000)

max(bits, 53)

#%%
module VarTest

function mutate_a(a)
    eval(:($a = 3))
    return
end

end

using .VarTest

#%%
a=5.3
VarTest.mutate_a(a)

a
