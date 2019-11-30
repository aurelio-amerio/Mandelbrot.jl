using Pkg
Pkg.activate("Mandelbrot")
using Mandelbrot
using Plots

#%%
# starting point
cmap = Mandelbrot.cycle_cmap(:inferno, 5)
xmin = -2.2
xmax = 0.8
ymin = -1.2
ymax = 1.2

fractal0_data = Mandelbrot.FractalData(
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

fractal1_data = Mandelbrot.FractalData(
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

fractal2_data = Mandelbrot.FractalData(
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

fractal3_data = Mandelbrot.FractalData(
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

fractal4b_data = Mandelbrot.FractalData(
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

#%% number 1
Mandelbrot.computeMandelbrot!(fractal1_data, use_GPU=true)

Mandelbrot.display_fractal(fractal1_data,
    # filename = "mandelbrot-fractal/images/mandelbrot1.png"
)
#%%
Mandelbrot.display_fractal(
    fractal1_data,
    scale = log,
    # filename = "mandelbrot-fractal/images/mandelbrot1b.png"
)

#%% number 2
Mandelbrot.computeMandelbrot!(fractal2_data)

Mandelbrot.display_fractal(fractal2_data,
    # filename = "mandelbrot-fractal/images/mandelbrot2.png"
)

#%% number 3
Mandelbrot.computeMandelbrot!(fractal3_data)

Mandelbrot.display_fractal(fractal3_data,
    # filename = "mandelbrot-fractal/images/mandelbrot3d.png"
)

#%% number 4
Mandelbrot.computeMandelbrot!(fractal4_data)

Mandelbrot.display_fractal(fractal4_data,
    # filename = "mandelbrot-fractal/images/mandelbrot4.png"
)
#%% navigation
fractal0_data.maxIter = 500
Mandelbrot.preview_fractal(fractal3_data, scale = :linear)
Mandelbrot.move_center!(fractal0_data, -1, 0)
Mandelbrot.zoom!(fractal0_data, 1.5)
Mandelbrot.get_coords(fractal0_data)
Mandelbrot.set_coords(fractal0_data, (-1.6761523437499999, -1.6722460937499999, -0.0015624999999999999, 0.0015624999999999999)...)
#%%
@code_warntype Mandelbrot.computeMandelbrot!(fractal0_data)
fractal0_data.colormap = Mandelbrot.cycle_cmap(:algae, 42)
Mandelbrot.display_fractal(
    fractal0_data,
    # filename = "mandelbrot-fractal/images/mandelbrot_navigation.png",
)

#%%
Mandelbrot.preview_fractal(fractal4b_data)
Mandelbrot.zoom!(fractal3_data, 5)
fractal3_data
Mandelbrot.move_center!(fractal3_data, 70, 0)
