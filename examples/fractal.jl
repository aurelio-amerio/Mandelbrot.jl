#%%
# using PyPlot
using BenchmarkTools
using Base.Threads
using Plots
using ProgressMeter
#%%
"""Find the required precision to perform exact computations"""
function find_precision(diff)
    tmp = eps(Float64)
    i = 53
    while tmp > (diff * 1e-2)
        setprecision(i) do
            tmp = eps(typeof(BigFloat(3.1)))
        end
        i += 1
    end
    return i
end

""" A mandelbrot set of geometry (width x height) and iterations 'niter' """
function mandelbrot_set(
    width,
    height,
    zoom = 1,
    x_off = 0,
    y_off = 0,
    niter = :auto,
    verbose = true,
)
    if niter == :auto
        niter = round(
            Int,
            42 * (1 +
             log10(zoom + 1)^(1.14 * log10(zoom + 1) / sqrt(log(zoom + 1)))),
        )
    end

    w, h = round.(Int, [width, height])
    pixels = zeros(Int, h, w)

    if verbose
        p = Progress(w)
        update!(p, 0)
        jj = Threads.Atomic{Int}(0)
        l = Threads.SpinLock()
    end

    # The mandelbrot set represents every complex point "c" for which
    # the Julia set is connected or every julia set that contains
    # the origin (0, 0). Hence we always start with c at the origin

    @threads for x = 1:w
        zx = 1.5 * (x + x_off * (zoom - 1) - 3 * w / 4) / (0.5 * zoom * w)
        @inbounds for y = 1:h
            # calculate the initial real and imaginary part of z,
            # based on the pixel location and zoom and position values
            # We use (x-3*w/4) instead of (x-w/2) to fully visualize the fractal
            # along the x-axis

            zy = 1.0 * (y + y_off * (zoom - 1) - h / 2) / (0.5 * zoom * h)

            z = complex(zx, zy)
            c = complex(0.0, 0.0)

            @inbounds for i = 1:niter
                if abs(c) > 4
                    # i = convert(Int32, i)
                    # color = (i<<21) + (i<<10) + i*8
                    pixels[y, x] = i
                    break
                end
                # Iterate till the point c is outside
                # the circle with radius 2.
                # Calculate new positions
                c = c^2 + z
            end
        end
        if verbose
            Threads.atomic_add!(jj, 1)
            Threads.lock(l)
            update!(p, jj[])
            Threads.unlock(l)
        end
    end

    return pixels
end

""" A mandelbrot set of geometry (width x height) and iterations 'niter' """
function mandelbrot_set(
    width,
    height,
    zoom,
    x_off::BigFloat,
    y_off::BigFloat,
    niter = :auto,
    verbose = true,
)
    if niter == :auto
        niter = round(
            Int,
            42 * (1 +
             log10(zoom + 1)^(1.14 * log10(zoom + 1) / sqrt(log(zoom + 1)))),
        )
    end

    w, h = round.(Int, [width, height])
    pixels = zeros(Int, h, w)

    if verbose
        p = Progress(w)
        update!(p, 0)
        jj = Threads.Atomic{Int}(0)
        l = Threads.SpinLock()
    end

    # The mandelbrot set represents every complex point "c" for which
    # the Julia set is connected or every julia set that contains
    # the origin (0, 0). Hence we always start with c at the origin

    @threads for x = 1:w
        zx = BigFloat(1.5 * (x + x_off * (zoom - 1) - 3 * w / 4) /
                      (0.5 * zoom * w))
        @inbounds for y = 1:h
            # calculate the initial real and imaginary part of z,
            # based on the pixel location and zoom and position values
            # We use (x-3*w/4) instead of (x-w/2) to fully visualize the fractal
            # along the x-axis

            zy = BigFloat(1.0 * (y + y_off * (zoom - 1) - h / 2) /
                          (0.5 * zoom * h))

            z = complex(zx, zy)
            c = complex(BigFloat(0), BigFloat(0))

            @inbounds for i = 1:niter
                if abs(c) > 4
                    # i = convert(Int32, i)
                    # color = (i<<21) + (i<<10) + i*8
                    pixels[y, x] = i
                    break
                end
                # Iterate till the point c is outside
                # the circle with radius 2.
                # Calculate new positions
                c = c^2 + z
            end
        end
        if verbose
            Threads.atomic_add!(jj, 1)
            Threads.lock(l)
            update!(p, jj[])
            Threads.unlock(l)
        end
    end

    return pixels
end

""" Display a mandelbrot set of width `width` and height `height` and zoom `zoom`
and offsets (x_off, y_off) """
function mandelbrot_display(
    ;
    width = 1024,
    height = 768,
    zoom = 1.0,
    x_off = 0,
    y_off = 0,
    niter = :auto,
    cmap = :viridis,
    filename = :none,
    verbose = true,
)
    dpi = round(Int, 100 * width / 600)

    x1 = 1
    x2 = 2
    zx1 = 1.5 * (x1 - 3 * width / 4) / (0.5 * zoom * width)
    zx2 = 1.5 * (x2 - 3 * width / 4) / (0.5 * zoom * width)
    diff = abs(zx1 - zx2)

    minimum_precision = find_precision(diff)
    if minimum_precision > precision(Float64)
        println("High precision computations required, using precision: $minimum_precision")
        setprecision(minimum_precision) do
            pixels = mandelbrot_set(
                width,
                height,
                zoom,
                BigFloat(x_off),
                BigFloat(y_off),
                niter,
                verbose,
            )
        end
    else
        pixels = mandelbrot_set(width, height, zoom, x_off, y_off, niter, verbose)
    end

    heatmap(pixels, showaxis = false, dpi = dpi, color = cmap)

    if filename != :none
        savefig(filename)
        println("File saved!")
    end


end

function create_animation(
    ;
    width = 1024,
    height = 768,
    zoom_min = 1.0,
    zoom_max = 1e6,
    x_off = -247.163795912061,
    y_off = -109.99932219994,
    niter = :auto,
    cmap = :viridis,
    res_multiplier = 1.0,
    filename = "mandelbrot.gif",
    n_frames = 100,
    fps = 10,
)
    if res_multiplier != 1
        width *= res_multiplier
        height *= res_multiplier
        x_off *= res_multiplier
        y_off *= res_multiplier
    end

    p = Progress(n_frames)
    update!(p, 0)
    jj = 0

    anim = @animate for zoom in 10 .^ range(
        round(Int, log10(zoom_min)),
        stop = round(Int, log10(zoom_max)),
        length = n_frames,
    )
        mandelbrot_display(
            width = width,
            height = height,
            zoom = zoom,
            x_off = x_off,
            y_off = y_off,
            niter = :auto,
            verbose = false,
        )
        jj += 1
        update!(p, jj)
    end
    gif(anim, filename, fps = fps)

end
#%%
create_animation(zoom_max=1e10, n_frames = 200, filename="mandelbrot2_1e11" )
#%%
mult = 1
width = mult * 1024
height = mult * 768
zoom = 1e5
x_off = -mult * 247.163795912061
y_off = -mult * 109.99932219994

mandelbrot_set(2048, 2048, zoom, x_off, y_off, 500, false)

# niter=2500
mandelbrot_display(
    width = width,
    height = height,
    zoom = zoom,
    x_off = x_off,
    y_off = y_off,
    # filename = "mandelbrot-fractal/mandelbrot_tmp.png",
)
# savefig("mandelbrot-fractal/mandelbrot_tmp.png")
# println("saved!")
#%%
