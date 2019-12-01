# Utilities for visualization
w_pw = 256
h_pw = 144

w_lr = 768
h_lr = 432

w_HD = 1920
h_HD = 1080

w_4k = 3840
h_4k = 2160

@doc raw"""
    get_coords(fractal::FractalData)

Get the coordinates for the selected `FractalData` object.
"""
function get_coords(fractal::FractalData)
    return fractal.xmin, fractal.xmax, fractal.ymin, fractal.ymax
end

@doc raw"""
    set_coords(fractal::FractalData, xmin, xmax, ymin, ymax)

Set the coordinates for the desired FractalData object.
"""
function set_coords(fractal::FractalData, xmin, xmax, ymin, ymax)
    fractal.xmin, fractal.xmax, fractal.ymin, fractal.ymax = xmin,
        xmax,
        ymin,
        ymax
    return
end

# functions to move on the fractal
@doc raw"""
    move_center!(fractal::FractalData, nStepsX::Int, nStepsY::Int)

Move the center of a FractalData objoct of n steps in the `x` or `y` direction.
`nStepsX=1` equals to a 1% movement to the right, while `nStepsY=1` equals to a
1% movement upside.
"""
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

@doc raw"""
    move_up!(fractal::FractalData, nSteps::Int = 1)

Move nSteps up. `nSteps = 1` equals to a 1% movement up.
"""
function move_up!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, 0, nSteps)
end

@doc raw"""
    move_down!(fractal::FractalData, nSteps::Int = 1)

Move nSteps down. `nSteps = 1` equals to a 1% movement down.
"""
function move_down!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, 0, -nSteps)
end

@doc raw"""
    move_left!(fractal::FractalData, nSteps::Int = 1)

Move nSteps left. `nSteps = 1` equals to a 1% movement left.
"""
function move_left!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, -nSteps, 0)
end

@doc raw"""
    move_right!(fractal::FractalData, nSteps::Int = 1)

Move nSteps right. `nSteps = 1` equals to a 1% movement right.
"""
function move_right!(fractal::FractalData, nSteps::Int = 1)
    move_center!(fractal::FractalData, nSteps, 0)
end

@doc raw"""
    zoom!(fractal::FractalData, zoom_factor::Real)

Zoom at the current position by a factor `zoom_factor`.
"""
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

@doc raw"""
    pumpkin(nRepeat::Int = 1)

Pumpkin colormap. `nRepeat` specifies the number of times the colormap loops over.
"""
function pumpkin(nRepeat::Int = 1)
    return ColorGradient(repeat([:black, :red, :orange], nRepeat))
end

@doc raw"""
    fire_and_ice(nRepeat::Int = 1)

"Fire and Ice" colormap. `nRepeat` specifies the number of times the colormap loops over.
"""
function fire_and_ice(nRepeat::Int = 1)
    cmap = ColorGradient(vcat(cgrad(:inferno).colors, cgrad(:ice).colors))
    return ColorGradient(repeat(cmap.colors, nRepeat))
end

@doc raw"""
    deep_space(nRepeat::Int = 1)

"Deep space" colormap. `nRepeat` specifies the number of times the colormap loops over.
"""
function deep_space(nRepeat::Int = 1)
    return ColorGradient(repeat(["#000000", "#193e7c", "#dde2ff"], nRepeat))
end

@doc raw"""
    alien_space(nRepeat::Int = 1)

"Alien space" colormap. `nRepeat` specifies the number of times the colormap loops over.
"""
function alien_space(nRepeat::Int = 1)
    return ColorGradient(repeat(
        ["#1a072a", "#ff3e24", "#ffa805", "#7b00ff"],
        nRepeat,
    ))
end

@doc raw"""
    funky_rainbow(nRepeat::Int = 1)

"Funky rainbow" colormap. `nRepeat` specifies the number of times the colormap loops over.
"""
function funky_rainbow(nRepeat::Int = 1)
    return ColorGradient(repeat(
        [
         "#833ab4",
         "#fdcd1d",
         "#45d0fc",
         "#fc45ae",
         "#747473",
         "#454cfc",
         "#fc4545",
         "#d27625",
         "#00ff10",
         "#45a8fc",
         "#833ab4",
        ],
        nRepeat,
    ))
end

@doc raw"""
    cycle_cmap(cmap, nRepeat::Int = 1)

Function to make a colormap cyclic.

# Arguments
- `cmap` may be either a `Symbol` or a `ColorGradient`.
- `nRepeat` specifies the number of times the colormap loops over.
"""
function cycle_cmap(cmap::Symbol, nRepeat::Int = 1)
    return ColorGradient(repeat(cgrad(cmap).colors, nRepeat))
end

function cycle_cmap(cmap::ColorGradient, nRepeat::Int = 1)
    return ColorGradient(repeat(cmap.colors, nRepeat))
end

# utility functions to convert from bits to precision digits
"""
    bits_to_digits(bits::Int)

Converts bits to the number of digits of accuracy.
"""
function bits_to_digits(bits::Int)
    return floor(bits * log10(2))
end

"""
    digits_to_bits(digits::Int)

Converts a number of figures to the corresponding number of bits required to achieve such accuracy.
"""
function digits_to_bits(digits::Int)
    return ceil(Int, digits / log10(2))
end


# utilities to display or preview the fractal
@doc raw"""
    display_fractal(fractal::FractalData; scale = :none, filename = :none, offset=0)

    display_fractal(
        fractal::Matrix;
        colormap = cycle_cmap(:inferno, 3),
        background_color = :white,
        scale = :linear,
        filename = :none,
        offset = 0
    )

Function to display a fractal, can either use a matrix or a `FractalData` object.

#Arguments
- `fractal`: can either be a `Matrix` or a `FractalData` object.
- `colormap`: the colormap which needs to be used, for `FractalData` uses the one stored insde the object.
- `background_color`: the color of the backgroud, also applies to transparent zones, such as when `Inf` values are not plotted.
For `FractalData` uses the one stored insde the object.
- `scale`: a scale function which can be applied to the fractal image before plotting.
If `:linear` is selected no scale function is applied. If `:none` is selected,
uses the default scale function stored inside the `FractalData` object.
- `filename`: if speccified, save the resulting image at that location.
- `offset`: value to be summed to the image before plotting it.

# Examples
```jldoctest
julia>  cmap1 = Mandelbrot.cycle_cmap(:inferno, 5)
        xmin1 = -1.744453831814658538530
        xmax1 = -1.744449945239591698236
        ymin1 = 0.022017835126305555133
        ymax1 = 0.022020017997233506531

julia>  fractal1_data = FractalData(xmin1, xmax1, ymin1, ymax1, width = Mandelbrot.w_4k,
                                    height = Mandelbrot.h_4k, colormap = cmap1,
                                    maxIter = 1500, scale_function = log)

julia>  computeMandelbrot!(fractal1_data)

julia>  display_fractal(fractal1_data, filename = "mandelbrot1.png")
```
"""
function display_fractal(
    fractal::Matrix;
    colormap = cycle_cmap(:inferno, 3),
    background_color = :white,
    scale = :linear,
    filename = :none,
    offset = 0
)
    img = deepcopy(fractal) .+ offset
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
        background_color = background_color
    )

    if filename != :none
        savefig(filename)
    end

    return plot
end

# # version using the structure
function display_fractal(fractal::FractalData; scale = :none, filename = :none, offset=0)
    if scale == :none
        display_fractal(
            fractal.fractal,
            colormap = fractal.colormap,
            background_color = fractal.background_color,
            scale = fractal.scale_function,
            filename = filename,
            offset = offset,
        )
    else
        display_fractal(
            fractal.fractal,
            colormap = fractal.colormap,
            background_color = fractal.background_color,
            scale = scale,
            filename = filename,
            offset = offset
        )
    end
end

@doc raw```
    preview_fractal( fractal_data::FractalData; scale = :linear, use_GPU = false)

Function used to preview the fractal contained in a `FractalData` object before computing it.

See also: [`display_fractal`](@ref)
```
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

# function create_animation_old(
#     coords_stop::NTuple{4,AbstractFloat},
#     coords_start = :auto;
#     width = w_lr,
#     height = h_lr,
#     maxIter = :auto,
#     colormap = cycle_cmap(:inferno, 2),
#     scale = :linear,
#     filename = "mandelbrot_$(rand(UInt))$(rand(UInt)).gif",
#     n_frames = 100,
#     fps = 10,
# )
#     p = Progress(n_frames)
#     update!(p, 0)
#     jj = 0
#
#     xmin_f, xmax_f, ymin_f, ymax_f = coords_stop
#     xc_f = (xmax_f + xmin_f) / 2
#     yc_f = (ymax_f + ymin_f) / 2
#
#     if coords_start == :auto
#         xmin_i = xc_f - 1.5
#         xmax_i = xc_f + 1.5
#         ymin_i = yc_f - 1.2
#         ymax_i = yc_f + 1.2
#     else
#         xmin_i, xmax_i, ymin_i, ymax_i = coords_start
#     end
#
#     xc_i = (xmax_i + xmin_i) / 2
#     yc_i = (ymax_i + ymin_i) / 2
#
#
#     dxc = xc_f - xc_i
#     dyc = yc_f - yc_i
#
#     dxc_arr = range(0, dxc, length = n_frames)
#     dyc_arr = range(0, dyc, length = n_frames)
#
#     dW_i = abs(xmax_i - xmin_i)
#     dW_f = abs(xmax_f - xmin_f)
#     dH_i = abs(ymax_i - ymin_i)
#     dH_f = abs(ymax_f - ymin_f)
#
#     dW_arr = 10 .^ range(log10(dW_i), log10(dW_f), length = n_frames)
#     dH_arr = 10 .^ range(log10(dH_i), log10(dH_f), length = n_frames)
#
#     xc_arr = dxc_arr .+ xc_i
#     yc_arr = dyc_arr .+ yc_i
#
#     xmin_arr = xc_arr .- dW_arr / 2
#     xmax_arr = xc_arr .+ dW_arr / 2
#     ymin_arr = yc_arr .- dH_arr / 2
#     ymax_arr = yc_arr .+ dH_arr / 2
#
#     if maxIter == :auto
#         nIters1 = 50
#         nIters2 = 50
#         nIters3 = 50
#         anim = @animate for i = 1:n_frames
#             nIters_new = 50 +
#                          round(Int, log10(4 / abs(xmax_arr[i] - xmin_arr[i]))^4)
#
#             nIters1 = nIters2
#             nIters2 = nIters3
#             nIters3 = max(nIters3, nIters_new)
#             nIters = ceil(Int, (nIters1 + nIters2 + nIters3) / 3)
#             img = computeMandelbrot(
#                 xmin_arr[i],
#                 xmax_arr[i],
#                 ymin_arr[i],
#                 ymax_arr[i],
#                 width,
#                 height,
#                 nIters,
#                 false,
#             )
#
#             display_fractal(
#                 img,
#                 colormap = colormap,
#                 scale = scale,
#                 filename = :none,
#             )
#
#             jj += 1
#             update!(p, jj)
#         end
#     else
#         anim = @animate for i = 1:n_frames
#             img = computeMandelbrot(
#                 xmin_arr[i],
#                 xmax_arr[i],
#                 ymin_arr[i],
#                 ymax_arr[i],
#                 width,
#                 height,
#                 maxIter,
#                 false,
#             )
#
#             display_fractal(
#                 img,
#                 colormap = colormap,
#                 scale = scale,
#                 filename = :none,
#             )
#
#             jj += 1
#             update!(p, jj)
#         end
#     end
#     gif(anim, filename, fps = fps)
#
# end

# v2

# function create_animation_old_v2(
#     coords_stop::NTuple{4,AbstractFloat},
#     coords_start = :auto;
#     width = w_lr,
#     height = h_lr,
#     maxIter = :auto,
#     colormap = cycle_cmap(:inferno, 2),
#     scale = :linear,
#     filename = "mandelbrot_$(rand(UInt))$(rand(UInt)).gif",
#     n_frames = 100,
#     fps = 10,
# )
#     p = Progress(n_frames)
#     update!(p, 0)
#     jj = 0
#
#     xmin_f, xmax_f, ymin_f, ymax_f = coords_stop
#     xc_f = (xmax_f + xmin_f) / 2
#     yc_f = (ymax_f + ymin_f) / 2
#
#     if coords_start == :auto
#         xmin_i = xc_f - 1.5
#         xmax_i = xc_f + 1.5
#         ymin_i = yc_f - 1.2
#         ymax_i = yc_f + 1.2
#     else
#         xmin_i, xmax_i, ymin_i, ymax_i = coords_start
#     end
#
#     xc_i = (xmax_i + xmin_i) / 2
#     yc_i = (ymax_i + ymin_i) / 2
#
#
#     dxc = xc_f - xc_i
#     dyc = yc_f - yc_i
#
#     dxc_arr = range(0, dxc, length = n_frames)
#     dyc_arr = range(0, dyc, length = n_frames)
#
#     dW_i = abs(xmax_i - xmin_i)
#     dW_f = abs(xmax_f - xmin_f)
#     dH_i = abs(ymax_i - ymin_i)
#     dH_f = abs(ymax_f - ymin_f)
#
#     dW_arr = 10 .^ range(log10(dW_i), log10(dW_f), length = n_frames)
#     dH_arr = 10 .^ range(log10(dH_i), log10(dH_f), length = n_frames)
#
#     xc_arr = dxc_arr .+ xc_i
#     yc_arr = dyc_arr .+ yc_i
#
#     xmin_arr = xc_arr .- dW_arr / 2
#     xmax_arr = xc_arr .+ dW_arr / 2
#     ymin_arr = yc_arr .- dH_arr / 2
#     ymax_arr = yc_arr .+ dH_arr / 2
#
#     images = zeros(n_frames, height, width)
#
#     if maxIter == :auto
#         nIters = 50
#         maxVal = 0
#         anim = @animate for i = 1:n_frames
#             nIters_new = 50 +
#                          round(Int, log10(4 / abs(xmax_arr[i] - xmin_arr[i]))^4)
#
#             nIters = max(nIters, nIters_new)
#             img = computeMandelbrot(
#                 xmin_arr[i],
#                 xmax_arr[i],
#                 ymin_arr[i],
#                 ymax_arr[i],
#                 width,
#                 height,
#                 nIters,
#                 false,
#             )
#
#             maxVal = max(maxVal, maximum(img))
#             img[1, 1] = maxVal
#             img[1, 2] = 0.0
#
#             display_fractal(
#                 img,
#                 colormap = colormap,
#                 scale = scale,
#                 filename = :none,
#             )
#
#             jj += 1
#             update!(p, jj)
#         end
#     else
#         anim = @animate for i = 1:n_frames
#             img = computeMandelbrot(
#                 xmin_arr[i],
#                 xmax_arr[i],
#                 ymin_arr[i],
#                 ymax_arr[i],
#                 width,
#                 height,
#                 maxIter,
#                 false,
#             )
#
#             maxVal = max(maxVal, maximum(img))
#             img[1, 1] = maxVal
#             img[1, 2] = 0.0
#
#             display_fractal(
#                 img,
#                 colormap = colormap,
#                 scale = scale,
#                 filename = :none,
#             )
#
#             jj += 1
#             update!(p, jj)
#         end
#     end
#     gif(anim, filename, fps = fps)
#
# end

#v3

@doc raw"""
    create_animation(
        coords_stop::NTuple{4,AbstractFloat},
        coords_start = :auto;
        width = w_lr,
        height = h_lr,
        maxIter = :auto,
        offset = 0,
        colormap = :inferno,
        cycle_colormap = true,
        scale = :linear,
        filename = "default",
        n_frames = 100,
        fps = 10,
    )

Computes an animated gif from `coords_start` to `coords_stop`.

# TODO add description

"""
function create_animation(
    coords_stop::NTuple{4,AbstractFloat},
    coords_start = :auto;
    width = w_lr,
    height = h_lr,
    maxIter = :auto,
    offset = 0,
    colormap = :inferno,
    cycle_colormap = true,
    scale = :linear,
    filename = "default",
    n_frames = 100,
    fps = 10,
)
    if filename == "default"
        filename = "mandelbrot_$(rand(UInt))$(rand(UInt)).gif"
    end

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

    #compute order of magnitude of the zoom
    if cycle_colormap
        magnitude = dW_i / dW_f
        nRepetitions = ceil(Int, log10(magnitude))
        cmap = cycle_cmap(colormap, nRepetitions)
    else
        cmap = colormap
    end

    images = zeros(height, width, n_frames)

    if maxIter == :auto
        nIters = 50
        @info "Computing frames"
        for i = 1:n_frames
            nIters_new = 50 +
                         round(Int, log10(4 / abs(xmax_arr[i] - xmin_arr[i]))^4)

            nIters = max(nIters, nIters_new)
            images[:, :, i] .= computeMandelbrot(
                xmin_arr[i],
                xmax_arr[i],
                ymin_arr[i],
                ymax_arr[i],
                width,
                height,
                nIters,
                false,
            )

            jj += 1
            update!(p, jj)
        end
        maxAll = maximum(images)
        minAll = minimum(images)

        @info "Creating animation"
        update!(p, 0)
        jj = 0

        anim = @animate for i = 1:n_frames
            img = images[:, :, i]
            img[1, 1] = maxAll
            img[1, 2] = minAll

            img .+= 10 #remove zeros

            display_fractal(
                img,
                colormap = cmap,
                scale = scale,
                filename = :none,
                offset = offset
            )
            jj += 1
            update!(p, jj)
        end

    else
        @info "Computing frames"
        nIters = maxIter
        for i = 1:n_frames
            images[:, :, i] .= computeMandelbrot(
                xmin_arr[i],
                xmax_arr[i],
                ymin_arr[i],
                ymax_arr[i],
                width,
                height,
                nIters,
                false,
            )

            jj += 1
            update!(p, jj)
        end
        maxAll = maximum(images)
        minAll = minimum(images)

        @info "Creating animation"
        update!(p, 0)
        jj = 0

        anim = @animate for i = 1:n_frames
            img = images[:, :, i]
            img[1, 1] = maxAll
            img[1, 2] = minAll

            img .+= 10 #remove zeros

            display_fractal(
                img,
                colormap = cmap,
                scale = scale,
                filename = :none,
                offset = offset
            )
            jj += 1
            update!(p, jj)
        end
    end
    gif(anim, filename, fps = fps)

end
