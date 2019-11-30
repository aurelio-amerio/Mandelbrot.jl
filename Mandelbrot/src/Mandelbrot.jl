
module Mandelbrot

using Base.Threads
using Plots
using ProgressMeter
using ArrayFire

w_pw = 256
h_pw = 144

w_lr = 768
h_lr = 432

w_HD = 1920
h_HD = 1080

w_4k = 3840
h_4k = 2160

# structure to hold fractal data
mutable struct FractalData
    xmin::Union{Float64,BigFloat}
    xmax::Union{Float64,BigFloat}
    ymin::Union{Float64,BigFloat}
    ymax::Union{Float64,BigFloat}
    width::Int
    height::Int
    fractal::Matrix{Float64}
    maxIter::Int
    colormap::ColorGradient
    scale_function::Function

    function FractalData(
        xmin::Union{Float64,BigFloat},
        xmax::Union{Float64,BigFloat},
        ymin::Union{Float64,BigFloat},
        ymax::Union{Float64,BigFloat};
        width::Int = w_lr,
        height::Int = h_lr,
        fractal = :none,
        maxIter = 1500,
        colormap = cgrad(:inferno),
        scale_function::Function = x -> x,
    ) #where {T<:Real}
        img = zeros(Float64, height, width)
        if fractal != :none
            img = fractal
        end
        new(
            xmin,
            xmax,
            ymin,
            ymax,
            width,
            height,
            img,
            maxIter,
            colormap,
            scale_function,
        )
    end
end

function get_coords(fractal::FractalData)
    return fractal.xmin, fractal.xmax, fractal.ymin, fractal.ymax
end

function set_coords(fractal::FractalData, xmin, xmax, ymin, ymax)
    fractal.xmin, fractal.xmax, fractal.ymin, fractal.ymax = xmin,
        xmax,
        ymin,
        ymax
    return
end

# functions to move on the fractal
function move_center!(fractal::FractalData, nStepsX::Int, nStepsY::Int)

    if nStepsX != 0
        xc = (fractal.xmax + fractal.xmin) / 2
        width = fractal.xmax - fractal.xmin
        dx = width / 100

        xc += nStepsX * dx
        fractal.xmin = xc - width / 2
        fractal.xmax = xc + width / 2
    end
    if nStepsY != 0
        yc = (fractal.ymax + fractal.ymin) / 2
        height = fractal.ymax - fractal.ymin
        dy = height / 100

        yc += nStepsY * dy
        fractal.ymin = yc - height / 2
        fractal.ymax = yc + height / 2
    end
    return preview_fractal(fractal) #preview changes
end

function move_up!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, 0, nSteps)
end

function move_down!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, 0, -nSteps)
end

function move_left!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, -nSteps, 0)
end

function move_right!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, nSteps, 0)
end

function zoom!(fractal::FractalData, zoom_factor::Real)
    xc = (fractal.xmax + fractal.xmin) / 2
    width = fractal.xmax - fractal.xmin
    width /= zoom_factor

    fractal.xmin = xc - width / 2
    fractal.xmax = xc + width / 2

    yc = (fractal.ymax + fractal.ymin) / 2
    height = fractal.ymax - fractal.ymin
    height /= zoom_factor

    fractal.ymin = yc - height / 2
    fractal.ymax = yc + height / 2

    if typeof(fractal.xmax) != BigFloat &&
       2 + ceil(Int, -log10(width / fractal.width)) > 16

        @info "Upgrading fractal to high resolution computations"

        fractal.xmin = BigFloat(fractal.xmin)
        fractal.xmax = BigFloat(fractal.xmax)
        fractal.ymin = BigFloat(fractal.ymin)
        fractal.ymax = BigFloat(fractal.ymax)
    end

    return preview_fractal(fractal) #preview changes
end

# custom colorbars, generate them using https://cssgradient.io/

function pumpkin(nRepeat::Int = 1)
    return ColorGradient(repeat([:black, :red, :orange], nRepeat))
end

function ice(nRepeat::Int = 1)
    return ColorGradient(repeat(["#193e7c", "#dde2ff"], nRepeat))
end

function deep_space(nRepeat::Int = 1)
    return ColorGradient(repeat(["#000000", "#193e7c", "#dde2ff"], nRepeat))
end

function alien_space(nRepeat::Int = 1)
    return ColorGradient(repeat(
        ["#1a072a", "#ff3e24", "#ffa805", "#7b00ff"],
        nRepeat,
    ))
end

function cycle_cmap(cmap::Symbol, nRepeat::Int = 1)
    return ColorGradient(repeat(cgrad(cmap).colors, nRepeat))
end

# utility functions to convert from bits to precision digits
function bits_to_digits(bits::Int)
    return floor(bits * log10(2))
end

function digits_to_bits(digits::Int)
    return ceil(Int, digits / log10(2))
end

# compute mandelbrot

function mandelbrotBoundCheck(
    cr::T,
    ci::T,
    maxIter::Int = 1000,
) where {T<:AbstractFloat}
    zr = zero(T)
    zi = zero(T)
    zrsqr = zr^2
    zisqr = zi^2
    result = 0
    for i = 1:maxIter
        if zrsqr + zisqr > 4.0
            result = i
            break
        end
        zi = (zr + zi)^2 - zrsqr - zisqr
        zi += ci
        zr = zrsqr - zisqr + cr
        zrsqr = zr^2
        zisqr = zi^2
    end
    return result
end

function computeMandelbrot(
    xmin::Float64,
    xmax::Float64,
    ymin::Float64,
    ymax::Float64,
    width::Int = w_lr,
    height::Int = h_lr,
    maxIter::Int = 100,
    verbose = true,
)
    if verbose
        p = Progress(width)
        update!(p, 0)
        jj = Threads.Atomic{Int}(0)
        l = Threads.SpinLock()
    end

    # xc = (xmax + xmin) / 2
    # yc = (ymax + ymin) / 2
    # dx = (xmax - xmin) / width
    # dy = (ymax - ymin) / height

    x_arr = range(xmin, stop = xmax, length = width)
    y_arr = range(ymin, stop = ymax, length = height)

    pixels = zeros(typeof(xmin), height, width) #pixels[y,x]

    @threads for x_j = 1:width
        @inbounds for y_i = 1:height
            pixels[y_i, x_j] = mandelbrotBoundCheck(
                x_arr[x_j],
                y_arr[y_i],
                maxIter,
            )
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

function computeMandelbrot(
    xmin::BigFloat,
    xmax::BigFloat,
    ymin::BigFloat,
    ymax::BigFloat,
    width::Int = w_lr,
    height::Int = h_lr,
    maxIter::Int = 100,
    verbose = true,
)
    if verbose
        p = Progress(width)
        update!(p, 0)
        jj = Threads.Atomic{Int}(0)
        l = Threads.SpinLock()
    end

    # xc = (xmax + xmin) / 2
    # yc = (ymax + ymin) / 2
    dx = (xmax - xmin) / width
    dy = (ymax - ymin) / height

    x_arr = range(xmin, stop = xmax, length = width)
    y_arr = range(ymin, stop = ymax, length = height)

    pixels = zeros(typeof(xmin), height, width) #pixels[y,x]

    # compute the required precision to have accurate computation of the fractal
    digits = 2 + ceil(Int, -log10(dx))
    bits = digits_to_bits(digits)
    bits = max(bits, 53) # use at least double precision
    @info "Using $digits digits"
    setprecision(bits) do
        @threads for x_j = 1:width
            @inbounds for y_i = 1:height
                pixels[y_i, x_j] = mandelbrotBoundCheck(
                    x_arr[x_j],
                    y_arr[y_i],
                    maxIter,
                )
            end
            if verbose
                Threads.atomic_add!(jj, 1)
                Threads.lock(l)
                update!(p, jj[])
                Threads.unlock(l)
            end
        end
    end
    return pixels
end

# gpu version
function computeMandelbrot_GPU(
    xmin::Float64,
    xmax::Float64,
    ymin::Float64,
    ymax::Float64,
    width::Int = w_lr,
    height::Int = h_lr,
    maxIter::Int = 100,
    verbose = true,
)


    x_arr = range(xmin, stop = xmax, length = width)
    y_arr = range(ymin, stop = ymax, length = height)

    dx = (xmax - xmin) / width

    xGrid = [i for j in y_arr, i in x_arr]
    yGrid = [j for j in y_arr, i in x_arr]

    # digits = 2 + ceil(Int, -log10(dx))

    # if digits <=7
    #
    #     c = AFArray(convert(Matrix{Float32}, xGrid + im * yGrid))
    #
    #     z = zeros(AFArray{Float32}, size(c))
    #     count = zeros(AFArray{Float32}, size(c))
    #
    # else
    #     if digits > 16
    #         @info "GPU computations are likely to be inaccurate at this scale"
    #     end
    #
    #     c = AFArray( xGrid + im * yGrid)
    #
    #     z = zeros(AFArray{Float64}, size(c))
    #     count = zeros(AFArray{Float64}, size(c))
    # end


    c = AFArray( xGrid + im * yGrid)

    z = zeros(AFArray{Float64}, size(c))
    count = zeros(AFArray{Float64}, size(c))

    if verbose
        @showprogress for n = 1:maxIter
            z = z .* z .+ c
            count = count + (abs(z) <= 2)
        end
    else
        for n = 1:maxIter
            z = z .* z .+ c
            count = count + (abs(z) <= 2)
        end
    end

    # sync the result
    sync(count)

    # transfer data back to the memory from GPU
    pixels = Array(count)

    return pixels
end

# compact interface
function computeMandelbrot!(
    fractal_data::FractalData;
    verbose = true,
    use_GPU = false,
)
    if use_GPU
        pixels = computeMandelbrot_GPU(
            fractal_data.xmin,
            fractal_data.xmax,
            fractal_data.ymin,
            fractal_data.ymax,
            fractal_data.width,
            fractal_data.height,
            fractal_data.maxIter,
            verbose,
        )
    else
        pixels = computeMandelbrot(
            fractal_data.xmin,
            fractal_data.xmax,
            fractal_data.ymin,
            fractal_data.ymax,
            fractal_data.width,
            fractal_data.height,
            fractal_data.maxIter,
            verbose,
        )
    end
    fractal_data.fractal = pixels
    return pixels
end

function display_fractal(
    fractal::Matrix;
    colormap = cycle_cmap(:inferno, 3),
    scale = :linear,
    filename = :none,
)
    img = deepcopy(fractal)
    if scale == :log
        img = log.(img) # normalize image to have nicer colors
    elseif scale == :exp
        img = exp.(img)
    elseif typeof(scale) <: Function
        img = scale.(img)
    end

    plot = heatmap(
        img,
        colorbar = :none,
        color = colormap,
        axis = false,
        size = (size(img)[2], size(img)[1]),
        grid = false,
        framestyle = :none,
    )

    if filename != :none
        savefig(filename)
    end

    return plot
end

# # version using the structure
function display_fractal(fractal::FractalData; scale = :none, filename = :none)
    if scale == :none
        display_fractal(
            fractal.fractal,
            colormap = fractal.colormap,
            scale = fractal.scale_function,
            filename = filename,
        )
    else
        display_fractal(
            fractal.fractal,
            colormap = fractal.colormap,
            scale = scale,
            filename = filename,
        )
    end
end

function preview_fractal(
    fractal_data::FractalData;
    scale = :linear,
    use_GPU = false,
)
    if use_GPU
        pixels = computeMandelbrot_GPU(
            fractal_data.xmin,
            fractal_data.xmax,
            fractal_data.ymin,
            fractal_data.ymax,
            w_pw,
            h_pw,
            fractal_data.maxIter,
            true,
        )
    else
        pixels = computeMandelbrot(
            fractal_data.xmin,
            fractal_data.xmax,
            fractal_data.ymin,
            fractal_data.ymax,
            w_pw,
            h_pw,
            fractal_data.maxIter,
            true,
        )
    end

    return display_fractal(
        pixels,
        colormap = fractal_data.colormap,
        scale = scale,
        filename = :none,
    )
end

end # end module
