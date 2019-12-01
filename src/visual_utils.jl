# Utilities for visualization
w_pw = 256
h_pw = 144

w_lr = 768
h_lr = 432

w_HD = 1920
h_HD = 1080

w_4k = 3840
h_4k = 2160

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


# utilities to display or preview the fractal

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

function create_animation(
    coords_stop::NTuple{4,AbstractFloat},
    coords_start = :auto;
    width = w_lr,
    height = h_lr,
    maxIter = :auto,
    colormap = cycle_cmap(:inferno, 2),
    scale = :linear,
    filename = "mandelbrot_$(rand(UInt))$(rand(UInt)).gif",
    n_frames = 100,
    fps = 10,
)
    p = Progress(n_frames)
    update!(p, 0)
    jj = 0

    xmin_f, xmax_f, ymin_f, ymax_f = coords_stop
    xc_f = (xmax_f + xmin_f) / 2
    yc_f = (ymax_f + ymin_f) / 2

    if coords_start == :auto
        xmin_i = xc_f - 1.5
        xmax_i = xc_f + 1.5
        ymin_i = yc_f - 1.2
        ymax_i = yc_f + 1.2
    else
        xmin_i, xmax_i, ymin_i, ymax_i = coords_start
    end

    xc_i = (xmax_i + xmin_i) / 2
    yc_i = (ymax_i + ymin_i) / 2


    dxc = xc_f - xc_i
    dyc = yc_f - yc_i

    dxc_arr = range(0, dxc, length = n_frames)
    dyc_arr = range(0, dyc, length = n_frames)

    dW_i = abs(xmax_i - xmin_i)
    dW_f = abs(xmax_f - xmin_f)
    dH_i = abs(ymax_i - ymin_i)
    dH_f = abs(ymax_f - ymin_f)

    dW_arr = 10 .^ range(log10(dW_i), log10(dW_f), length = n_frames)
    dH_arr = 10 .^ range(log10(dH_i), log10(dH_f), length = n_frames)

    xc_arr = dxc_arr .+ xc_i
    yc_arr = dyc_arr .+ yc_i

    xmin_arr = xc_arr .- dW_arr / 2
    xmax_arr = xc_arr .+ dW_arr / 2
    ymin_arr = yc_arr .- dH_arr / 2
    ymax_arr = yc_arr .+ dH_arr / 2


    #
    # ΔW_left = xmin_i - xmin_f
    # ΔW_right = xmax_i - xmax_f
    # ΔH_up = ymax_i - ymax_f
    # ΔH_down = ymin_i - ymin_f
    #
    # dW_left = 10^(log10(abs(ΔW_left))/n_frames)
    # dW_right = 10^(log10(abs(ΔW_left))/n_frames)
    # dH_up = 10^(log10(abs(ΔH_up))/n_frames)
    # dH_down = 10^(log10(abs(ΔH_down))/n_frames)
    #
    # xmin_arr = range(xmin_i, xmin_f, step = n_frames)
    # xmax_arr = range(log10(xmax_i), log10(xmax_f), length = n_frames)
    # ymin_arr = range(log10(ymin_i), log10(ymin_f), length = n_frames)
    # ymax_arr = range(log10(ymax_i), log10(ymax_f), length = n_frames)

    if maxIter == :auto
        nIters = 100
        anim = @animate for i = 1:n_frames
            nIters_new = 50 +
                     round(Int, log10(4 / abs(xmax_arr[i] - xmin_arr[i]))^4)
            nIters = max(nIters_new, nIters)
            img = computeMandelbrot(
                xmin_arr[i],
                xmax_arr[i],
                ymin_arr[i],
                ymax_arr[i],
                width,
                height,
                nIters,
                false,
            )

            display_fractal(
                img,
                colormap = colormap,
                scale = scale,
                filename = :none,
            )

            jj += 1
            update!(p, jj)
        end
    else
        anim = @animate for i = 1:n_frames
            img = computeMandelbrot(
                xmin_arr[i],
                xmax_arr[i],
                ymin_arr[i],
                ymax_arr[i],
                width,
                height,
                maxIter,
                false,
            )

            display_fractal(
                img,
                colormap = colormap,
                scale = scale,
                filename = :none,
            )

            jj += 1
            update!(p, jj)
        end
    end
    gif(anim, filename, fps = fps)

end
