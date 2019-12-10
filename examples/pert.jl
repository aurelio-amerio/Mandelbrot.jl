using Pkg
Pkg.activate("./")
# Pkg.instantiate()
using Mandelbrot
using Plots
using ProgressMeter
using Base.Threads
using BenchmarkTools
#%%

function δz(dzr, dzi, size = 3)
    res = zeros(Complex{Float64}, size, size)
    offset = floor(Int, size / 2) + 1
    for j = 1:size
        for i = 1:size
            res[i, j] = im * (i - offset) * dzi + (j - offset) * dzr
        end
    end
    return res
end


function computePatch(
    cr::T,
    ci::T,
    dx,
    dy,
    maxIter = 1000,
    patchSize = 5,
    ncoeff = 30,
) where {T<:AbstractFloat}
    zr = zero(T)
    zi = zero(T)
    c = complex(cr, ci)
    z = complex(zr, zi)
    z_arr = zeros(Complex{Float64}, maxIter)
    ε_arr = zeros(Complex{Float64}, patchSize, patchSize, maxIter + 1)
    # A_arr = zeros(Complex{Float64}, maxIter+1)
    # A_arr[1] = 1
    # B_arr = zeros(Complex{Float64}, maxIter+1)
    # B_arr[1] = 0
    # C_arr = zeros(Complex{Float64}, maxIter+1)
    # C_arr[1] = 0

    coeff = zeros(Complex{Float64}, ncoeff)
    coeff[1] = 1.0
    coeff_new = zeros(Complex{Float64}, ncoeff)

    δ = δz(dx, dy, patchSize)
    δ_arr = [δ .^ i for i = 1:ncoeff]

    result = zeros(patchSize, patchSize)
    for i = 1:(maxIter-1)
        two_z_f = 2 * z_arr[i]
        # C = two_z_f * C + 2 * A * B
        # B = two_z_f * B + A^2
        # A = two_z_f * A + 1
        # ε_arr[:, :, i+1] .= A .* δ + B .* δ2 + C .* δ3
        coeff_new[1] = two_z_f * coeff[1] + 1
        k = ncoeff
        for i = 2:k
            series = [coeff[j] * coeff[k-j] for j = 1:(k-1)]
            coeff_new[i] = two_z_f * coeff[i] + sum(series)
        end

        ε_arr[:, :, i+1] = sum(δ_arr .* coeff_new)
        coeff = coeff_new # update coefficients

        z = z^2 + c
        z_arr[i+1] = convert(Complex{Float64}, z)
        # if abs(z) > 2
        #     break
        # end
    end

    for j = 1:patchSize
        for i = 1:patchSize
            for iter = 1:(maxIter-1)
                zprime = z_arr[iter] + ε_arr[i, j, iter]
                if abs(zprime) > 2 #|| abs(z_arr[iter])>2
                    result[i, j] = iter
                    break
                end
            end
        end
    end

    return result
end

#%%
# xmin = -2.2
# xmax = 0.8
# ymin = -1.2
# ymax = 1.2

xmin=-0.747458753333333332354
xmax=-0.747186451111111110226
ymin=0.100209751111111111151
ymax=0.100413977777777777747
# width=960
# height=540
width = 1920
height = 1080
maxIter = 5000
cmap = Mandelbrot.cycle_cmap(:inferno, 3)
scale = x -> x^-5

fractal_data = FractalData(
    xmin,
    xmax,
    ymin,
    ymax,
    width = width,
    height = height,
    colormap = cmap,
    maxIter = maxIter,
    scale_function = scale,
)



nsteps = 5
order = 30

dx = (xmax - xmin) / width
dy = (ymax - ymin) / height

x_arr = range(xmin + dx, xmax - dx, step = nsteps * dx)
y_arr = range(ymin + dy, ymax - dy, step = nsteps * dy)

image = zeros(height, width)
#%%
computeMandelbrot!(fractal_data)
displayMandelbrot(fractal_data)
#%%
p = Progress(length(x_arr))
update!(p, 0)
jj = Threads.Atomic{Int}(0)
l = Threads.SpinLock()


setprecision(100) do
    @threads for j = 1:length(x_arr)
        for i = 1:length(y_arr)
            image[
                (i*nsteps-nsteps+1):i*nsteps,
                (j*nsteps-nsteps+1):j*nsteps,
            ] = computePatch(x_arr[j], y_arr[i], dx, dy, maxIter)
        end
        Threads.atomic_add!(jj, 1)
        Threads.lock(l)
        update!(p, jj[])
        Threads.unlock(l)
    end
end
#%%
displayMandelbrot(image, colormap = cmap, scale = scale)
# displayMandelbrot(image, colormap=cmap, scale=x->x^-5)
# savefig("test.png")
