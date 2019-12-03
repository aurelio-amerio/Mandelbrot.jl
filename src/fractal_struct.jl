# structure to hold fractal data
@doc raw"""
    FractalData(xmin::Union{Float64,BigFloat},
        xmax::Union{Float64,BigFloat},
        ymin::Union{Float64,BigFloat},
        ymax::Union{Float64,BigFloat};
        width::Int = w_lr,
        height::Int = h_lr,
        fractal = :none,
        maxIter = 1500,
        colormap = cgrad(:inferno),
        background_color = :white,
        scale_function::Function = x -> x)

Structure to contain the informations necessary to compute a Mandelbrot fractal.
"""
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
    background_color
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
        background_color = :white,
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
            background_color,
            scale_function,
        )
    end
end
