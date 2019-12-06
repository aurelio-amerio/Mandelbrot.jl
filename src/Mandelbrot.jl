
module Mandelbrot

using Base.Threads
using Plots
using ProgressMeter
using ArrayFire

include("fractal_struct.jl")
include("computation_routines.jl")
include("visual_utils.jl")

export FractalData,
       computeMandelbrot!,
       move_center!,
       move_up!,
       move_down!,
       move_left!,
       move_right!,
       display,
       preview


end # end module
