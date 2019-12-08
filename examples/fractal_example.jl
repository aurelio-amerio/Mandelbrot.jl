using Pkg
Pkg.activate("./")
Pkg.instantiate()
using Mandelbrot
using Plots
using BenchmarkTools

#%% code to make some of the example images
# starting point
cmap = Mandelbrot.cycle_cmap(:inferno, 5)
xmin = -2.2
xmax = 0.8
ymin = -1.2
ymax = 1.2

fractal0_data = FractalData(
    xmin,
    xmax,
    ymin,
    ymax,
    width = Mandelbrot.w_4k,
    height = Mandelbrot.h_4k,
    colormap = cmap,
    maxIter = 1500,
    scale_function = x -> x,
)


cmap1 = Mandelbrot.cycle_cmap(:inferno, 5)
xmin1 = -1.744453831814658538530
xmax1 = -1.744449945239591698236
ymin1 = 0.022017835126305555133
ymax1 = 0.022020017997233506531

fractal1_data = FractalData(
    xmin1,
    xmax1,
    ymin1,
    ymax1,
    width = Mandelbrot.w_4k,
    height = Mandelbrot.h_4k,
    colormap = cmap1,
    maxIter = 1500,
    scale_function = x -> x,
)

cmap2 = cgrad(:ice)
scale2 = log
maxIter2 = 5000
xmin2 = 0.308405876790033128474
xmax2 = 0.308405910247503605302
ymin2 = 0.025554220954294027410
ymax2 = 0.025554245987221578418

fractal2_data = FractalData(
    xmin2,
    xmax2,
    ymin2,
    ymax2,
    width = Mandelbrot.w_4k,
    height = Mandelbrot.h_4k,
    colormap = cmap2,
    maxIter = maxIter2,
    scale_function = scale2,
)


# cmap3b = Mandelbrot.pumpkin(4)
cmap3c = Mandelbrot.cycle_cmap(:inferno, 50)
scale3 = x -> x^-5
maxIter3 = 5000
xmin3 = 0.307567454839614329536
xmax3 = 0.307567454903142214608
ymin3 = 0.023304267108419154581
ymax3 = 0.023304267156089095573

fractal3_data = FractalData(
    xmin3,
    xmax3,
    ymin3,
    ymax3,
    width = Mandelbrot.w_4k,
    height = Mandelbrot.h_4k,
    colormap = cmap3c,
    maxIter = maxIter3,
    scale_function = scale3,
)

fractal3b_data = FractalData(
    xmin3,
    xmax3,
    ymin3,
    ymax3,
    width = 2 * Mandelbrot.w_4k,
    height = 2 * Mandelbrot.h_4k,
    colormap = cmap3c,
    maxIter = maxIter3,
    scale_function = scale3,
)

cmap4 = Mandelbrot.alien_space(50)
scale4 = x -> x^-5
maxIter4 = 50000
xmin4 = 0.2503006273651145643691
xmax4 = 0.2503006273651201870891
ymin4 = 0.0000077612880963380370
ymax4 = 0.0000077612881005550770

xmin4b = BigFloat("0.2503006273651145643691")
xmax4b = BigFloat("0.2503006273651201870891")
ymin4b = BigFloat("0.0000077612880963380370")
ymax4b = BigFloat("0.0000077612881005550770")

fractal4b_data = FractalData(
    xmin4b,
    xmax4b,
    ymin4b,
    ymax4b,
    width = Mandelbrot.w_HD,
    height = Mandelbrot.h_HD,
    colormap = cmap4,
    maxIter = maxIter4,
    scale_function = scale4,
)


xmin5=-1.262440431894299
xmax5=-1.2624404318626976
ymin5=0.4082647088979621
ymax5=0.40826470892164096
cmap5 = Mandelbrot.fire_and_ice(3)

fractal5_data = FractalData(
    xmin5,
    xmax5,
    ymin5,
    ymax5,
    width = Mandelbrot.w_HD,
    height = Mandelbrot.h_HD,
    colormap = cmap5,
    maxIter = maxIter4,
    scale_function = scale4,
)

xmin6=BigFloat("-0.7500679710085359722781")
xmax6=BigFloat("-0.7500679710085335423022")
ymin6=BigFloat("0.0066482323597727934007")
ymax6=BigFloat("0.0066482323597746227151")
fractal6_data = FractalData(
    xmin6,
    xmax6,
    ymin6,
    ymax6,
    width = Mandelbrot.w_HD,
    height = Mandelbrot.h_HD,
    colormap = cmap5,
    maxIter = 150000,
    scale_function = scale4,
)


xmin7=-0.048039235368553826
xmax7=-0.048039193307296899
ymin7=0.6746533946423985
ymax7=0.6746534263607233

fractal7_data = FractalData(
    xmin7,
    xmax7,
    ymin7,
    ymax7,
    width = Mandelbrot.w_4k,
    height = Mandelbrot.h_4k,
    colormap = cmap5,
    maxIter = 5000,
    scale_function = scale4,
)
#%% number 1
computeMandelbrot!(fractal1_data)

displayMandelbrot(fractal1_data,
    # filename = "images/mandelbrot1.png"
)
#%%
displayMandelbrot(
    fractal1_data,
    scale = log,
    # filename = "mandelbrot-fractal/images/mandelbrot1b.png"
)

#%% let's change the colormap and the scale function
fractal1_data.colormap = Mandelbrot.fire_and_ice(2)
fractal1_data.background_color = :black
scale = x-> x^-1

displayMandelbrot(fractal1_data, scale = scale,
 # filename="images/mandelbrot1c",
 offset=0)


#%% number 2
computeMandelbrot!(fractal2_data)

displayMandelbrot(fractal2_data,
    # filename = "mandelbrot-fractal/images/mandelbrot2.png"
)

#%% number 3
computeMandelbrot!(fractal3_data)

displayMandelbrot(fractal3_data,
    # filename = "mandelbrot-fractal/images/mandelbrot3d.png"
)
#%% number 3 using GPU
@btime computeMandelbrot!(fractal3_data, use_GPU=true, verbose=false)
@btime computeMandelbrot!(fractal3_data, use_GPU=false, verbose=false)

displayMandelbrot(fractal3_data,
    # filename = "mandelbrot-fractal/images/mandelbrot3d.png"
)

#%% number 4
computeMandelbrot!(fractal4_data)

displayMandelbrot(fractal4_data,
    # filename = "mandelbrot-fractal/images/mandelbrot4.png"
)
#%% number 5

computeMandelbrot!(fractal5_data)
Mandelbrot.displayMandelbrot(fractal5_data, scale=x->-1/x, filename="images/mandelbrot5")

#%% number 6
preview(fractal6_data)
Mandelbrot.move_right!(fractal6_data, 20)

#%% number 7
Mandelbrot.get_coords(fractal7_data)
fractal7_data.colormap=Mandelbrot.cycle_cmap(:inferno,3)
fractal7_data.colormap=Mandelbrot.fire_and_ice(2)
move_center!(fractal7_data,-2,0)
computeMandelbrot!(fractal7_data)
displayMandelbrot(fractal7_data, scale=x->-1/x, filename="images/mandelbrot7")
#%% navigation

fractal0_data.maxIter = 50
preview(fractal0_data, scale = :linear)
Mandelbrot.move_center!(fractal0_data, -41, 0)

fractal0_data.maxIter = 500 #increas maximum number of iterations
Mandelbrot.zoom!(fractal0_data, 100)
Mandelbrot.move_center!(fractal0_data, -35, 0)
Mandelbrot.zoom!(fractal0_data, 10)
Mandelbrot.move_center!(fractal0_data, -30, 0)
fractal0_data.maxIter = 1000
preview(fractal0_data, scale = x->1/log10(x)) #nice fractal!

coords = Mandelbrot.get_coords(fractal0_data) #let's save the coordinates for future use

Mandelbrot.set_coords(fractal0_data, coords...)

computeMandelbrot!(fractal0_data) # compute 4k resolution image
displayMandelbrot(fractal0_data, scale = x->1/log10(x),
    filename = "images/mandelbrot_movement.png"
) #plot and save the fractal

#%% compute an animation up to point 3

Mandelbrot.create_animation(
    (xmin3, xmax3, ymin3, ymax3),
    n_frames = 500,
    scale = log10,
    colormap = Mandelbrot.fire_and_ice(),
)

#%%
fractal0_data.maxIter = 10000
preview(fractal0_data, scale = :linear)
Mandelbrot.move_left!(fractal0_data, 20)
Mandelbrot.move_right!(fractal0_data, 5)
Mandelbrot.move_up!(fractal0_data, 50)
Mandelbrot.move_down!(fractal0_data, 5)

fractal0_data.maxIter = 500 #increas maximum number of iterations
Mandelbrot.zoom!(fractal0_data, 10)
Mandelbrot.move_center!(fractal0_data, -35, 0)
Mandelbrot.zoom!(fractal0_data, 10)
Mandelbrot.move_center!(fractal0_data, -30, 0)
fractal0_data.maxIter = 1000
preview(fractal0_data, scale = x->1/log10(x))

Mandelbrot.get_coords(fractal0_data)

(0.2871372209449980505979738154564984142780303955078125, 0.2871372209749980530801849454292096197605133056640625, 0.0134189404439997612972224061422821250744163990020751953125, 0.013418940467999761201323138948282576166093349456787109375)

#%%
