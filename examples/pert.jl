using ProgressMeter
using Plots
using Base.Threads

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
    patchSize = 3,
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

    A = 1
    B = 0
    C = 0

    δ = δz(dx, dy, patchSize)
    δ2 = δ .^ 2
    δ3 = δ .^ 3

    result = zeros(patchSize, patchSize)
    for i = 1:(maxIter-1)
        two_z_f = 2 * z_arr[i]
        C = two_z_f * C + 2 * A * B
        B = two_z_f * B + A^2
        A = two_z_f * A + 1
        ε_arr[:, :, i+1] .= A .* δ + B .* δ2 + C .* δ3

        z = z^2 + c
        z_arr[i+1] = convert(Complex{Float64}, z)
        if abs(z) > 2
            break
        end
    end

    for j = 1:patchSize
        for i = 1:patchSize
            for iter = 1:(maxIter-1)
                zprime = z_arr[iter] + ε_arr[i, j, iter]
                if abs(zprime) > 2 || abs(z_arr[iter])>2
                    result[i, j] = iter
                    break
                end
            end
        end
    end

    return result
end

#%%
xmin = BigFloat("0.2503006273651145643691")
xmax = BigFloat("0.2503006273651201870891")
ymin = BigFloat("0.0000077612880963380370")
ymax = BigFloat("0.0000077612881005550770")

width=1920
height=1080
maxIter=50000

dx = (xmax-xmin)/width
dy = (ymax-ymin)/height

x_arr = range(xmin+dx, xmax-dx, step=5*dx)
y_arr = range(ymin+dy, ymax-dy, step=5*dy)

image = zeros(height,width)
#%%
p = Progress(length(x_arr))
update!(p, 0)
jj = Threads.Atomic{Int}(0)
l = Threads.SpinLock()


setprecision(100) do
    @threads for j in 1:length(x_arr)
        for i in 1:length(y_arr)
            image[(i*5-4):i*5, (j*5-4):j*5] = computePatch(x_arr[j],y_arr[i],dx,dy,maxIter,5)
        end
        Threads.atomic_add!(jj, 1)
        Threads.lock(l)
        update!(p, jj[])
        Threads.unlock(l)
    end
end
#%%
heatmap(image)
