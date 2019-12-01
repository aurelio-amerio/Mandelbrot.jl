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


    c = AFArray(xGrid + im * yGrid)

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
